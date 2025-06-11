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
    return Row(
      children: [
        // Botón Refresh / Limpiar Filtros (Fijo)
        _buildRefreshButton(context),

        // Chips dinámicos (Scroll horizontal)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _buildCategoryChips(context),
            ),
          ),
          ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        height: 40,
        width: 40,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          elevation: 2,
          child: InkWell(
            onTap: () {
              prefs.clearActiveFilterCategories();
              viewModel.applyCategoryFilters(Set<String>());
            },
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              Icons.refresh,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context) {
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