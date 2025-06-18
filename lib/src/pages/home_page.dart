import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';
import 'package:quehacemos_cba/src/providers/filter_criteria.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String> _lastAppliedFilters = {};
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🏁 HomePage init con fecha seleccionada: ${widget.selectedDate}');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);

      if (!_hasInitialized && viewModel.filteredEvents.isEmpty) {
        print('📦 Inicializando eventos desde HomePage...');
        await viewModel.initialize(
          initialCriteria: FilterCriteria(selectedDate: widget.selectedDate),
        );
        _hasInitialized = true;
      } else {
        print('♻️ Ya había eventos o ya se había inicializado');
        if (widget.selectedDate != viewModel.selectedDate) {
          viewModel.setSelectedDate(widget.selectedDate);
        }
      }
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.setSelectedDate(widget.selectedDate);
      print('🗓️ Fecha actualizada desde HomePage: ${widget.selectedDate}');
    }
  }

  bool _needsFilterUpdate(Set<String> currentFilters) {
    if (_lastAppliedFilters.length != currentFilters.length) return true;
    for (final filter in currentFilters) {
      if (!_lastAppliedFilters.contains(filter)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, PreferencesProvider>(
      builder: (context, viewModel, prefs, _) {
        print('🧠 Eventos disponibles: ${viewModel.filteredEvents.length}');

        if (_needsFilterUpdate(prefs.activeFilterCategories)) {
          print('🎯 Aplicando filtros nuevos: ${prefs.activeFilterCategories}');
          _lastAppliedFilters = Set.from(prefs.activeFilterCategories);
          viewModel.applyCategoryFilters(prefs.activeFilterCategories);
        }

        if (viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFD3D3D3),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.hasError) {
          return Scaffold(
            backgroundColor: Color(0xFFD3D3D3),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${viewModel.errorMessage}'),
                  ElevatedButton(
                    onPressed: () => viewModel.refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final displayedEvents = viewModel.getHomePageEvents();
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
                  prefs: prefs,
                  viewModel: viewModel,
                ),
              ),
              if (displayedEvents.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        viewModel.selectedDate == null
                            ? 'No hay eventos próximos.'
                            : 'No hay eventos para esta fecha.',
                      ),
                    ),
                  ),
                )
              else
                ...sortedDates.map((date) {
                  final eventsOnDate = groupedEvents[date]!;
                  final sectionTitle = viewModel.getSectionTitle(date);

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: Text(
                          sectionTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      ...eventsOnDate.map((event) => EventCardWidget(
                            event: event,
                            viewModel: viewModel,
                          )),
                    ]),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final PreferencesProvider prefs;
  final HomeViewModel viewModel;

  _HeaderDelegate({
    required this.title,
    required this.prefs,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFD3D3D3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            FilterChipsRow(
              prefs: prefs,
              viewModel: viewModel,
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
    return title != oldDelegate.title ||
        prefs != oldDelegate.prefs ||
        viewModel != oldDelegate.viewModel;
  }
}
