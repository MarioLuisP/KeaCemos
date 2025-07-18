import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart';
//import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';
import 'package:quehacemos_cba/src/providers/filter_criteria.dart';
import 'package:intl/intl.dart';
import 'package:quehacemos_cba/src/widgets/cards/fast_event_card.dart';
import 'package:quehacemos_cba/src/widgets/app_bars/main_app_bar.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  final VoidCallback? onReturnToCalendar; // NUEVO
  const HomePage({
    super.key,
    this.selectedDate,
    this.onReturnToCalendar,
  }); // NUEVO

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Estado local para evitar rebuilds innecesarios
  Set<String> _lastAppliedFilters = {};
  DateTime? _lastSelectedDate;
  bool _isInitialized = false;
  bool _isFilterUpdateScheduled = false;
  bool get _isInDayFilterMode => widget.selectedDate != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHomePage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeHomePage() async {
    print('🏁 HomePage inicializando...');

    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    final prefs = Provider.of<PreferencesProvider>(context, listen: false);

    // Inicializar filtros actuales
    _lastAppliedFilters = Set.from(prefs.activeFilterCategories);
    _lastSelectedDate = widget.selectedDate;

    // Solo inicializar si no hay datos o si cambió la fecha
    if (!_isInitialized || viewModel.filteredEvents.isEmpty) {
      await viewModel.initialize(
        initialCriteria: FilterCriteria(selectedDate: widget.selectedDate),
      );
      _isInitialized = true;
    } else if (widget.selectedDate != viewModel.selectedDate) {
      // Cambio de fecha sin rebuild completo
      await _updateSelectedDate(widget.selectedDate);
    }

    // Aplicar filtros iniciales
    _applyFiltersIfNeeded(prefs.activeFilterCategories);
  }

  Future<void> _updateSelectedDate(DateTime? newDate) async {
    if (_lastSelectedDate == newDate) return;

    print('🗓️ Actualizando fecha: $newDate');
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);

    _lastSelectedDate = newDate;
    await viewModel.setSelectedDate(newDate);
  }

  void _applyFiltersIfNeeded(Set<String> currentFilters) {
    if (_isFilterUpdateScheduled) return;

    if (_hasFiltersChanged(currentFilters)) {
      print('🎯 Aplicando filtros: $currentFilters');
      _isFilterUpdateScheduled = true;

      // Usar microtask para evitar builds durante builds
      Future.microtask(() {
        if (mounted) {
          final viewModel = Provider.of<HomeViewModel>(context, listen: false);
          _lastAppliedFilters = Set.from(currentFilters);
          viewModel.applyCategoryFilters(currentFilters);
          _isFilterUpdateScheduled = false;
        }
      });
    }
  }

  bool _hasFiltersChanged(Set<String> currentFilters) {
    if (_lastAppliedFilters.length != currentFilters.length) return true;
    return !_lastAppliedFilters.containsAll(currentFilters);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedDate != oldWidget.selectedDate) {
      _updateSelectedDate(widget.selectedDate);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refrescar cuando la app vuelve a primer plano
    if (state == AppLifecycleState.resumed && _isInitialized) {
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.refreshIfNeeded();
    }
  }

  // Método para resetear al estado por defecto (eventos próximos)
  Future<void> resetToDefaultView() async {
    print('🔄 Reseteando a vista por defecto');
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);

    _lastSelectedDate = null;
    await viewModel.setSelectedDate(null); // null = próximos eventos
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido para AutomaticKeepAliveClientMixin

    return Consumer2<HomeViewModel, PreferencesProvider>(
      builder: (context, viewModel, prefs, _) {
        // CAMBIO: Solo aplicar filtros si ya está inicializado
        if (_isInitialized) {
          _applyFiltersIfNeeded(prefs.activeFilterCategories);
        }
        return _buildContent(viewModel, prefs);
      },
    );
  }

  Widget _buildContent(HomeViewModel viewModel, PreferencesProvider prefs) {
    if (viewModel.isLoading && !_isInitialized) {
      return _buildLoadingScaffold();
    }

    if (viewModel.hasError) {
      return _buildErrorScaffold(viewModel);
    }

    final displayedEvents = viewModel.getHomePageEvents();

    final scaffoldContent = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFixedHeader(viewModel, prefs),
          Expanded(
            child: _buildScrollableBody(
              viewModel: viewModel,
              displayedEvents: displayedEvents,
              groupedEvents: {},
              sortedDates: [],
            ),
          ),
        ],
      ),
    );

    // NUEVO: Solo agregar swipe detector si viene del calendario
    if (_isInDayFilterMode) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            _returnToCalendar();
          }
        },
        child: scaffoldContent,
      );
    }

    return scaffoldContent;
  }

  // NUEVO: Agregar este método al final de la clase _HomePageState
  void _returnToCalendar() {
    // Aquí necesito saber cómo navegas al calendario
    print('🗓️ Volviendo al calendario...');
    if (widget.onReturnToCalendar != null) {
      widget.onReturnToCalendar!();
    }
  }

  Widget _buildFixedHeader(HomeViewModel viewModel, PreferencesProvider prefs) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.getPageTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          FilterChipsRow(prefs: prefs, viewModel: viewModel),
        ],
      ),
    );
  }

  Widget _buildScrollableBody({
    required HomeViewModel viewModel,
    required List<dynamic>
    displayedEvents, // CAMBIO: Parámetro mantenido para compatibilidad
    required Map<DateTime, List<dynamic>>
    groupedEvents, // CAMBIO: Parámetro mantenido para compatibilidad
    required List<DateTime>
    sortedDates, // CAMBIO: Parámetro mantenido para compatibilidad
  }) {
    // NUEVO: Obtener flatItems optimizados desde cache
    final flatItems = viewModel.getFlatItemsForHomePage();

    if (flatItems.isEmpty) {
      // CAMBIO: Usar flatItems en lugar de displayedEvents
      return _buildEmptyState(viewModel);
    }

    return CustomScrollView(
      // CAMBIO: Mantener CustomScrollView
      physics: const BouncingScrollPhysics(
        parent:
            AlwaysScrollableScrollPhysics(), // CAMBIO: Mantener physics optimizadas
      ),
      slivers: [
        // CAMBIO: Mantener estructura con slivers
        SliverPadding(
          padding: EdgeInsets.only(top: 8.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = flatItems[index];

                if (item['type'] == 'header') {
                  return SizedBox(
                    height: 60.0,  // ✅ Altura fija para headers
                    child: _buildSectionHeader(item['title']),
                  );
                } else {
                  return SizedBox(
                    height: 230.0,  // ✅ Altura fija para tarjetas
                    child: FastEventCard(
                      event: item['data'],
                      key: ValueKey(item['data']['id']),
                      viewModel: viewModel,
                    ),
                  );
                }
              },
              childCount: flatItems.length,
            ),
          ),
        ),

 
 
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return const MainAppBar(
      title: 'QuehaCeMos Córdoba',
      showUserAvatar: true, // SIN avatar = SIN Firebase
      showNotifications: true, // Campanita funciona
      showContactButton: true, // Botón + funciona
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      backgroundColor: Color(0xFFD3D3D3),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(HomeViewModel viewModel) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 141, 25, 25),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${viewModel.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _isInitialized = false;
                _initializeHomePage();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required HomeViewModel viewModel,
    required PreferencesProvider prefs,
    required List<dynamic> displayedEvents,
    required Map<DateTime, List<dynamic>> groupedEvents,
    required List<DateTime> sortedDates,
  }) {
    return CustomScrollView(
      // Mantener posición del scroll
      key: const PageStorageKey<String>('home_page_scroll'),
      slivers: [
        _buildStickyHeader(viewModel, prefs),
        if (displayedEvents.isEmpty)
          _buildEmptyState(viewModel)
        else
          ..._buildEventSections(
            groupedEvents: groupedEvents,
            sortedDates: sortedDates,
            viewModel: viewModel,
          ),
      ],
    );
  }

  SliverPersistentHeader _buildStickyHeader(
    HomeViewModel viewModel,
    PreferencesProvider prefs,
  ) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _OptimizedHeaderDelegate(
        title: viewModel.getPageTitle(),
        prefs: prefs,
        viewModel: viewModel,
      ),
    );
  }

    Widget _buildEmptyState(HomeViewModel viewModel) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                viewModel.selectedDate == null
                    ? 'No hay eventos próximos.'
                    : 'No hay eventos para esta fecha.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: resetToDefaultView,
                child: const Text('Ver todos los eventos'),
              ),
            ],
          ),

        ),
      
    );
  }

  List<Widget> _buildEventSections({
    required Map<DateTime, List<dynamic>> groupedEvents,
    required List<DateTime> sortedDates,
    required HomeViewModel viewModel,
  }) {
    return sortedDates.map((date) {
      final eventsOnDate = groupedEvents[date]!;
      // ✅ CORRECCIÓN: Convertir DateTime a String para getSectionTitle
      final sectionTitle = viewModel.getSectionTitle(
        DateFormat('yyyy-MM-dd').format(date),
      );

      return SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader(sectionTitle),
          ...eventsOnDate.map(
              (event) => FastEventCard(
                event: event,
                key: ValueKey(event['id']),
                viewModel: viewModel,
              ),
            ),
        ]),
      );
    }).toList();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              //                  color: Colors.black87,
            ),
          ),
          const Divider(thickness: 0.5, color: Colors.grey),
        ],
      ),
    );
  }
}

// Header optimizado con mejor gestión de rebuilds
class _OptimizedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final PreferencesProvider prefs;
  final HomeViewModel viewModel;

  _OptimizedHeaderDelegate({
    required this.title,
    required this.prefs,
    required this.viewModel,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color.fromARGB(255, 241, 196, 136),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Envolver en un Consumer específico para evitar rebuilds innecesarios
            Consumer<PreferencesProvider>(
              builder:
                  (context, prefs, _) =>
                      FilterChipsRow(prefs: prefs, viewModel: viewModel),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80.0;

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _OptimizedHeaderDelegate oldDelegate) {
    // Solo rebuilding si realmente cambió algo importante
    return title != oldDelegate.title;
  }
}
