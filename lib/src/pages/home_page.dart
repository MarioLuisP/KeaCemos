import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/pages/pages.dart';
import 'package:quehacemos_cba/src/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/filter_criteria.dart';
import 'package:quehacemos_cba/src/widgets/chips/event_chip_widget.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String> _lastAppliedFilters = {};
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage inicializado con selectedDate: ${widget.selectedDate}');
    
    // 🚨 CAMBIO: Inicializar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewModel();
    });
  }

  Future<void> _initializeViewModel() async {
    if (_hasInitialized) return;
    
    print('🚀 Inicializando HomeViewModel desde HomePage...');
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    
    // Solo inicializar si no tiene eventos cargados
    if (homeViewModel.filteredEvents.isEmpty) {
      final initialCriteria = FilterCriteria(selectedDate: widget.selectedDate);
      await homeViewModel.initialize(initialCriteria: initialCriteria);
      print('✅ HomeViewModel inicializado desde HomePage con ${homeViewModel.filteredEvents.length} eventos');
    } else {
      print('✅ HomeViewModel ya tenía ${homeViewModel.filteredEvents.length} eventos cargados');
      // Solo actualizar la fecha si es diferente
      if (widget.selectedDate != homeViewModel.selectedDate) {
        await homeViewModel.setSelectedDate(widget.selectedDate);
      }
    }
    
    _hasInitialized = true;
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      homeViewModel.setSelectedDate(widget.selectedDate);
      print('🔄 HomePage actualizado con nuevo selectedDate: ${widget.selectedDate}');
    }
  }

  bool _needsFilterUpdate(Set<String> currentFilters) {
    if (_lastAppliedFilters.length != currentFilters.length) return true;
    for (String filter in currentFilters) {
      if (!_lastAppliedFilters.contains(filter)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 CAMBIO PRINCIPAL: Usar directamente los providers globales, NO crear instancias locales
    return Consumer3<HomeViewModel, PreferencesProvider, FavoritesProvider>(
      builder: (context, homeViewModel, preferencesProvider, favoritesProvider, child) {
        
        // Debug para verificar que usamos la instancia correcta
        print('🏠 HomePage build - Eventos en homeViewModel: ${homeViewModel.filteredEvents.length}');
        
        // Aplicar filtros solo cuando cambien
        if (_needsFilterUpdate(preferencesProvider.activeFilterCategories)) {
          _lastAppliedFilters = Set.from(preferencesProvider.activeFilterCategories);
          homeViewModel.applyCategoryFilters(preferencesProvider.activeFilterCategories);
        }
        
        if (homeViewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFD3D3D3),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (homeViewModel.hasError) {
          return Scaffold(
            backgroundColor: Color(0xFFD3D3D3),
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
                  title: homeViewModel.getPageTitle(),
                  preferencesProvider: preferencesProvider,
                  homeViewModel: homeViewModel,
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
                      ...eventsOnDate.asMap().entries.map((entry) {
                        final event = entry.value;
                        return EventCardWidget(
                          event: event,
                          viewModel: homeViewModel,
                        );
                      }).toList(),
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
  final PreferencesProvider preferencesProvider;
  final HomeViewModel homeViewModel;

  _HeaderDelegate({
    required this.title,
    required this.preferencesProvider,
    required this.homeViewModel,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Color(0xFFD3D3D3),
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
            FilterChipsRow(
              prefs: preferencesProvider,
              viewModel: homeViewModel,
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
        preferencesProvider != oldDelegate.preferencesProvider ||
        homeViewModel != oldDelegate.homeViewModel;
  }
}