import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/pages/event_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late HomeViewModel _homeViewModel;

  @override
  bool get wantKeepAlive => true; // Preserva el estado del scroll

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
      print('HomePage actualizado con nuevo selectedDate: ${widget.selectedDate}');
    }
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _homeViewModel)],
      child: Selector<HomeViewModel, bool>(
        selector: (_, vm) => vm.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Selector<HomeViewModel, bool>(
            selector: (_, vm) => vm.hasError,
            builder: (context, hasError, child) {
              if (hasError) {
                final errorMessage = context.read<HomeViewModel>().errorMessage;
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $errorMessage'),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () => context.read<HomeViewModel>().refresh(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Selector<PreferencesProvider, Set<String>>(
                selector: (_, prefs) => prefs.activeFilterCategories,
                builder: (context, activeFilterCategories, child) {
                  final viewModel = context.read<HomeViewModel>();
                  viewModel.applyCategoryFilters(activeFilterCategories); // Mover fuera de addPostFrameCallback
                  final groupedEvents = viewModel.getGroupedEvents();
                  final sortedDates = viewModel.getSortedDates();

                  return Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'QuehaCeMos Córdoba',
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
                            title: viewModel.getPageTitle(),
                            prefs: context.read<PreferencesProvider>(),
                            viewModel: viewModel,
                          ),
                        ),
                        if (groupedEvents.isEmpty)
                          const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No hay eventos próximos.'),
                              ),
                            ),
                          )
                        else
                          ...sortedDates.map((date) {
                            final eventsOnDate = groupedEvents[date]!;
                            final sectionTitle = viewModel.getSectionTitle(date);

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 2.0,
                                      ),
                                      child: Text(
                                        sectionTitle,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    return const Divider(
                                      thickness: 0.5,
                                      indent: 16.0,
                                      endIndent: 16.0,
                                      color: Colors.grey,
                                    );
                                  } else {
                                    final event = eventsOnDate[index - 2];
                                    return Semantics(
                                      label: 'Evento ${event['title']}',
                                      button:  true,
                                      child: EventCardWidget(
                                        event: event,
                                        viewModel: viewModel,
                                      ),
                                    );
                                  }
                                },
                                childCount: eventsOnDate.length + 2, // Título + divisor + eventos
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final PreferencesProvider prefs;
  final HomeViewModel viewModel;

  const _HeaderDelegate({
    required this.title,
    required this.prefs,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 40.0, // Altura fija para FilterChipsRow
              child: FilterChipsRow(prefs: prefs, viewModel: viewModel),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 36.0 + 40.0 + 16.0; // Título (~36) + Chips (40) + Padding vertical (8+8)

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return title != oldDelegate.title || prefs != oldDelegate.prefs || viewModel != oldDelegate.viewModel;
  }
}