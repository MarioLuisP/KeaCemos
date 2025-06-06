import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/preferences_provider.dart';
import 'package:myapp/src/utils/utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);

    final List<Map<String, dynamic>> categories = [
      {'name': 'Música', 'emoji': '🎶', 'color': AppColors.musica},
      {'name': 'Teatro', 'emoji': '🎭', 'color': AppColors.teatro},
      {'name': 'StandUp', 'emoji': '😂', 'color': AppColors.standUp},
      {'name': 'Arte', 'emoji': '🎨', 'color': AppColors.arte},
      {'name': 'Cine', 'emoji': '🎬', 'color': AppColors.cine},
      {'name': 'Mic', 'emoji': '🎤', 'color': AppColors.mic},
      {'name': 'Cursos', 'emoji': '🛠️', 'color': AppColors.cursos}, // Reemplaza Talleres
      {'name': 'Ferias', 'emoji': '🏬', 'color': AppColors.ferias},
      {'name': 'Calle', 'emoji': '🌆', 'color': AppColors.calle},
      {'name': 'Redes', 'emoji': '🤝', 'color': AppColors.redes}, // Reemplaza Comunidad
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        children: [
          // Sección: Temas
          Card(
            elevation: AppDimens.cardElevation,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadius)),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema de la app',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  Wrap(
                    spacing: AppDimens.paddingSmall,
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
          const SizedBox(height: AppDimens.paddingMedium),
          // Sección: Categorías favoritas
          Card(
            elevation: AppDimens.cardElevation,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadius)),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías favoritas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  Text(
                    'Elegí hasta 4 categorías. Seleccionaste ${provider.selectedCategories.length}/4.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.paddingSmall,
                    crossAxisSpacing: AppDimens.paddingSmall,
                    childAspectRatio: 3.5, // Ajustado para FilterChip más anchos
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
                        selectedColor: AppColors.adjustForTheme(context, category['color'] as Color),
                        backgroundColor: (category['color'] as Color).withOpacity(0.5),
                        showCheckmark: true,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),
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