import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/chips/event_chip_widget.dart';

class FilterChipsRow extends StatelessWidget {
  final PreferencesProvider prefs;
  final HomeViewModel viewModel;

  const FilterChipsRow({
    Key? key,
    required this.prefs,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Botón Refresh / Limpiar Filtros
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                prefs.clearActiveFilterCategories();
                viewModel.applyCategoryFilters(Set<String>());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.refresh),
              ),
            ),
          ),

          // Chips dinámicos
          ..._buildCategoryChips(),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryChips() {
    final categories = prefs.selectedCategories.isEmpty
        ? ['Música', 'Teatro', 'Cine', 'StandUp']
        : prefs.selectedCategories.toList();

    return categories.map((category) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: EventChipWidget(category: category),
      );
    }).toList();
  }
}