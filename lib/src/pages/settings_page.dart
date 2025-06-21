import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/utils/utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);

    final List<Map<String, dynamic>> categories = [
      {'name': 'Música', 'emoji': '🎶', 'color': AppColors.musica},
      {'name': 'Teatro', 'emoji': '🎭', 'color': AppColors.teatro},
      {'name': 'StandUp', 'emoji': '😂', 'color': AppColors.standup},
      {'name': 'Arte', 'emoji': '🎨', 'color': AppColors.arte},
      {'name': 'Cine', 'emoji': '🎬', 'color': AppColors.cine},
      {'name': 'Mic', 'emoji': '🎤', 'color': AppColors.mic},
      {'name': 'Cursos', 'emoji': '🛠️', 'color': AppColors.cursos},
      {'name': 'Ferias', 'emoji': '🏬', 'color': AppColors.ferias},
      {'name': 'Calle', 'emoji': '🌆', 'color': AppColors.calle},
      {'name': 'Redes', 'emoji': '🤝', 'color': AppColors.redes},
      {'name': 'Niños', 'emoji': '👧', 'color': AppColors.ninos},
      {'name': 'Danza', 'emoji': '🩰', 'color': AppColors.danza},
    ];

    return Scaffold(
            appBar: AppBar(
              title: const Text('Configuración'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0, // 👉 Leve sombra (podés probar con 1.0 a 4.0)
            ),

      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        children: [
          Card(
            elevation: AppDimens.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            ),
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
                  const SizedBox(height: AppDimens.paddingMedium),
                  // Grid de 2 filas x 3 columnas para los temas
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.paddingSmall,
                    crossAxisSpacing: AppDimens.paddingSmall,
                    childAspectRatio: 2.5,
                    children: [
                      _buildThemeButton(context, provider, 'Normal', 'normal'),
                      _buildThemeButton(context, provider, 'Oscuro', 'dark'),
                      _buildThemeButton(context, provider, 'Sepia', 'sepia'),
                      _buildThemeButton(context, provider, 'Pastel', 'pastel'),
                      _buildThemeButton(context, provider, 'Harmony', 'harmony'),
                      _buildThemeButton(context, provider, 'Fluor', 'fluor'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingMedium),
          Card(
            elevation: AppDimens.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            ),
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
                    'Seleccioná las categorías que te interesan. Todas están activas por defecto.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),
                  // Grid de 2 columnas x 6 filas para las categorías
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.paddingSmall,
                    crossAxisSpacing: AppDimens.paddingSmall,
                    childAspectRatio: 4.5, // Aumenté de 3.0 a 4.5 para hacerlos más chatos
                    children: categories.map((category) {
                      final isSelected = provider.selectedCategories.contains(category['name']);
                      final color = AppColors.adjustForTheme(context, category['color'] as Color);

                      return _buildCategoryButton(
                        context, 
                        provider, 
                        category['name'] as String,
                        category['emoji'] as String,
                        color,
                        isSelected
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

  Widget _buildThemeButton(BuildContext context, PreferencesProvider provider, String label, String theme) {
    final isSelected = provider.theme == theme;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: isSelected 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => provider.setTheme(theme),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, PreferencesProvider provider, String name, String emoji, Color color, bool isSelected) {
    // Función para determinar si el color es claro y necesita texto oscuro
    bool isLightColor(Color color) {
      return color.computeLuminance() > 0.5;
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduje de 16 a 12
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await provider.toggleCategory(name);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.black,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Padding más pequeño
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14), // Emoji más pequeño
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                            ? (isLightColor(color) ? Colors.black : Colors.white) // Lógica mejorada para el contraste
                            : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12, // Texto más pequeño
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 14, // Ícono más pequeño
                        color: isLightColor(color) ? Colors.black : Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 