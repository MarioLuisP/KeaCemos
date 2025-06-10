import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/pages/pages.dart';
import 'package:quehacemos_cba/src/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/chips/event_chip_widget.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeViewModel _homeViewModel;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel();
    _initializeViewModel();
    print('HomePage inicializado con selectedDate: ${widget.selectedDate}');
  }

  Future<void> _initializeViewModel() async {
    await _homeViewModel.initialize(selectedDate: widget.selectedDate);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _homeViewModel.setSelectedDate(widget.selectedDate);
      print(
        'HomePage actualizado con nuevo selectedDate: ${widget.selectedDate}',
      );
    }
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _homeViewModel)],
      child: Consumer2<HomeViewModel, PreferencesProvider>(
        builder: (context, homeViewModel, preferencesProvider, child) {
          // Aplicar filtros después del frame actual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            homeViewModel.applyCategoryFilters(
              preferencesProvider.activeFilterCategories,
            );
          });

          if (homeViewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (homeViewModel.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${homeViewModel.errorMessage}'),
                    ElevatedButton(
                      onPressed: () => homeViewModel.refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final displayedEvents = homeViewModel.getHomePageEvents();
          final groupedEvents = homeViewModel.getGroupedEvents();
          final sortedDates = homeViewModel.getSortedDates();

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                '🌟 KeaCMos Córdoba',
                style: TextStyle(fontWeight: FontWeight.normal),
              ),
              centerTitle: true,
              toolbarHeight: 40.0,
            ),
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    title: homeViewModel.getPageTitle(),
                    categories:
                        preferencesProvider.selectedCategories.isEmpty
                            ? ['Música', 'Teatro', 'Cine', 'StandUp']
                            : preferencesProvider.selectedCategories
                                .map((c) => c == 'StandUp' ? 'StandUp' : c)
                                .toList(),
                  ),
                ),
                if (displayedEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          homeViewModel.selectedDate == null
                              ? 'No hay eventos próximos.'
                              : 'No hay eventos para esta fecha.',
                        ),
                      ),
                    ),
                  )
                else
                  ...sortedDates.map((date) {
                    final eventsOnDate = groupedEvents[date]!;
                    final sectionTitle = homeViewModel.getSectionTitle(date);

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 2.0,
                          ),
                          child: Text(
                            sectionTitle,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Divider(
                          thickness: 0.5,
                          indent: 16.0,
                          endIndent: 16.0,
                          color: Colors.grey,
                        ),
                        ...eventsOnDate.asMap().entries.map((entry) {
                          final event = entry.value;
                          return _buildEventCard(context, event, homeViewModel);
                        }).toList(),
                      ]),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Map<String, String> event,
    HomeViewModel viewModel,
  ) {
    final parsedDate = viewModel.parseDate(event['date']!);
    final formattedDate = DateFormat('d MMM yyyy', 'es').format(parsedDate);
    final formattedTime =
        parsedDate.hour > 0 || parsedDate.minute > 0
            ? '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')} hs'
            : '';
    final cardColor = viewModel.getEventCardColor(event['type'] ?? '', context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title']!, style: AppStyles.cardTitle),
                    const SizedBox(height: 8),
                    Text('Fecha: $formattedDate'),
                    if (formattedTime.isNotEmpty) Text('Hora: $formattedTime'),
                    const SizedBox(height: 4),
                    Text('Ubicación: ${event['location']}'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    AuthService()
                        .signInWithGoogle()
                        .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sesión iniciada')),
                          );
                        })
                        .catchError((error) {
                          print('Error signing in: $error');
                        });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final List<String> categories;

  _HeaderDelegate({required this.title, required this.categories});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 4.0), // Padding inicial
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: EventChipWidget(category: category),
                    ),
                  ),
                  const SizedBox(width: 4.0), // Padding final
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 28.0 + 48.0;

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return title != oldDelegate.title || categories != oldDelegate.categories;
  }
}
