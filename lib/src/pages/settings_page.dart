import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/preferences_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);

    final List<Map<String, dynamic>> categories = [
      {'name': 'Música', 'emoji': '🎶', 'color': const Color(0xFFCCE5FF)},
      {'name': 'Teatro', 'emoji': '🎭', 'color': const Color(0xFFB2DFDB)},
      {'name': 'StandUp', 'emoji': '😂', 'color': const Color(0xFFFFF9C4)},
      {'name': 'Arte', 'emoji': '🎨', 'color': const Color(0xFFFFECB3)},
      {'name': 'Cine', 'emoji': '🎬', 'color': const Color(0xFFE0E0E0)},
      {'name': 'Mic', 'emoji': '🎤', 'color': const Color(0xFFE1BEE7)},
      {'name': 'Talleres', 'emoji': '🛠️', 'color': const Color(0xFFDCEDC8)},
      {'name': 'Ferias', 'emoji': '🏬', 'color': const Color(0xFFFFCDD2)},
      {'name': 'Calle', 'emoji': '🌆', 'color': const Color(0xFFB3E5FC)},
      {'name': 'Comunidad', 'emoji': '🤝', 'color': const Color(0xFFC8E6C9)},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección: Temas
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema de la app',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected: provider.theme == 'normal',
                        onSelected: (_) => provider.setTheme('normal'),
                      ),
                      ChoiceChip(
                        label: const Text('Oscuro'),
                        selected: provider.theme == 'dark',
                        onSelected: (_) => provider.setTheme('dark'),
                      ),
                      ChoiceChip(
                        label: const Text('Fluor'),
                        selected: provider.theme == 'fluor',
                        onSelected: (_) => provider.setTheme('fluor'),
                      ),
                      ChoiceChip(
                        label: const Text('Harmony'),
                        selected: provider.theme == 'harmony',
                        onSelected: (_) => provider.setTheme('harmony'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sección: Categorías favoritas
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías favoritas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elegí hasta 4 categorías. Seleccionaste ${provider.selectedCategories.length}/4.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = provider.selectedCategories.contains(category['name']);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category['emoji'] as String),
                            const SizedBox(width: 4),
                            Text(category['name'] as String),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) async {
                          final reachedLimit = provider.selectedCategories.length >= 4 && !isSelected;
                          await provider.toggleCategory(category['name'] as String);
                          if (reachedLimit) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ya elegiste 4. Sacá una para agregar otra.'),
                              ),
                            );
                          }
                        },
                        selectedColor: category['color'] as Color,
                        backgroundColor: (category['color'] as Color).withOpacity(0.5),
                        showCheckmark: true,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: provider.resetCategories,
                      child: const Text('Restablecer selección'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}