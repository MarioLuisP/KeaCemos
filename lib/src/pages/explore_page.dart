import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/widgets/chips/filter_chips_widget.dart'; // Nuevo import
import 'package:quehacemos_cba/src/utils/utils.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  
  // 🚀 OPTIMIZACIÓN: Variables para evitar rebuilds innecesarios
  Set<String> _lastAppliedFilters = {};

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
    _searchController.addListener(() {
      _viewModel.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
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
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _viewModel)],
      child: Consumer2<HomeViewModel, PreferencesProvider>(
        builder: (context, viewModel, prefs, _) {
          // 🔥 OPTIMIZACIÓN: Solo aplicar filtros cuando REALMENTE cambien
          if (_needsFilterUpdate(prefs.activeFilterCategories)) {
            _lastAppliedFilters = Set.from(prefs.activeFilterCategories);
            viewModel.applyCategoryFilters(prefs.activeFilterCategories); // Inmediato
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Explorar Eventos'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0,
            ),
            body: Column(
              children: [
                // Campo de búsqueda
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Busca eventos (ej. payasos)',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Fila de chips + refresh
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FilterChipsRow(prefs: prefs, viewModel: viewModel),
                ),

                const SizedBox(height: 8.0),

                // Lista de eventos
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.hasError
                          ? Center(
                              child: Text('Error: ${viewModel.errorMessage}'),
                            )
                          : viewModel.filteredEvents.isEmpty
                              ? const Center(child: Text('No hay eventos.'))
                              : ListView.builder(
                                  itemCount: viewModel.filteredEvents.take(20).length,
                                  itemBuilder: (context, index) {
                                    final event = viewModel.filteredEvents[index];
                                    return EventCardWidget(event: event, viewModel: viewModel);
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}