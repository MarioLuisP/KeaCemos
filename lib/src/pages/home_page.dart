import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 🚀 OPTIMIZACIÓN: Variables para evitar rebuilds innecesarios
  Set<String> _lastAppliedFilters = {};

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage inicializado con selectedDate: ${widget.selectedDate}');
    
    // 🚨 SIMPLE: Solo setear la fecha si es diferente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      if (widget.selectedDate != viewModel.selectedDate) {
        viewModel.setSelectedDate(widget.selectedDate);
      }
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.setSelectedDate(widget.selectedDate);
      print('🔄 HomePage actualizado con nuevo selectedDate: ${widget.selectedDate}');
    }
  }

  // 🎯 FUNCIÓN DE OPTIMIZACIÓN: Chequea si realmente necesitamos aplicar filtros
  bool _needsFilterUpdate(Set<String> currentFilters) {
    if (_lastAppliedFilters.length != currentFilters.length) return true;
    for (String filter in currentFilters) {
      if (!_lastAppliedFilters.contains(filter)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 SIMPLE: Solo Consumer2 como ExplorePage
    return Consumer2<HomeViewModel, PreferencesProvider>(
      builder: (context, viewModel, prefs, _) {
        
        print('🏠 HomePage build - Eventos en viewModel: ${viewModel.filteredEvents.length}');
        
        // 🔥 OPTIMIZACIÓN: Solo aplicar filtros cuando REALMENTE cambien
        if (_needsFilterUpdate(prefs.activeFilterCategories)) {
          _lastAppliedFilters = Set.from(prefs.activeFilterCategories);
          viewModel.applyCategoryFilters(prefs.activeFilterCategories);
        }
        
        // Estados de carga y error
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

        // 🎯 DATOS: Obtener eventos agrupados
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
              // Header pegajoso con título y filtros
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  title: viewModel.getPageTitle(),
                  prefs: prefs,
                  viewModel: viewModel,
                ),
              ),
              
              // Contenido: eventos agrupados por fecha o mensaje vacío
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
                // 🎯 AGRUPACIÓN: Por cada fecha, crear una sección
                ...sortedDates.map((date) {
                  final eventsOnDate = groupedEvents[date]!;
                  final sectionTitle = viewModel.getSectionTitle(date);

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Título de la sección (fecha)
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
                      
                      // Divisor
                      const Divider(
                        thickness: 0.5,
                        indent: 16.0,
                        endIndent: 16.0,
                        color: Colors.grey,
                      ),
                      
                      // Eventos de esa fecha
                      ...eventsOnDate.map((event) {
                        return EventCardWidget(
                          event: event,
                          viewModel: viewModel,
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

// 🎯 HEADER DELEGATE: Igual que antes pero más simple
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
            // 🎯 CHIPS: Mismo componente que ExplorePage
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