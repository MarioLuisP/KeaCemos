import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/utils/utils.dart';
import 'package:quehacemos_cba/src/services/services.dart'; 
import 'package:quehacemos_cba/src/services/services.dart'; // EXISTENTE
import 'package:quehacemos_cba/src/data/repositories/event_repository.dart'; // NUEVO: import repository

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
        elevation: 2.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        children: [
          // ========== CARD 1: TEMAS ==========
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
          
          // ========== CARD 2: CATEGORÍAS ==========
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.paddingSmall,
                    crossAxisSpacing: AppDimens.paddingSmall,
                    childAspectRatio: 4.5,
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

          // ========== CARD 3: GESTIÓN DE DATOS ========== // NUEVO: card completo
          const SizedBox(height: AppDimens.paddingMedium),                  // NUEVO: espaciado
          Card(                                                             // NUEVO: card gestión
            elevation: AppDimens.cardElevation,                            // NUEVO: misma elevación
            shape: RoundedRectangleBorder(                                  // NUEVO: mismo border
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            ),
            child: Padding(                                                 // NUEVO: mismo padding
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: Column(                                                // NUEVO: columna principal
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(                                                     // NUEVO: título
                    '⚙️ Gestión de Datos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),         // NUEVO: espaciado
                  Row(                                                      // NUEVO: layout 2 columnas
                    children: [
                      Expanded(                                             // NUEVO: columna izquierda
                        child: _buildCleanupColumn(
                          context,
                          provider,
                          'Eventos vencidos',
                          [2, 3, 7, 10],
                          provider.eventCleanupDays,
                          true, // isEvents
                        ),
                      ),
                      Container(                                            // NUEVO: divider vertical
                        width: 1,
                        height: 160,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
                      ),
                      Expanded(                                             // NUEVO: columna derecha
                        child: _buildCleanupColumn(
                          context,
                          provider,
                          'Favoritos vencidos',
                          [3, 7, 10, 30],
                          provider.favoriteCleanupDays,
                          false, // isFavorites
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ========== CARD 4: DESARROLLADOR ========== // NUEVO: card desarrollador completo
          const SizedBox(height: AppDimens.paddingMedium),                  // NUEVO: espaciado
          Card(                                                             // NUEVO: card desarrollador
            elevation: AppDimens.cardElevation,                            // NUEVO: misma elevación
            shape: RoundedRectangleBorder(                                  // NUEVO: mismo border
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            ),
            child: Padding(                                                 // NUEVO: mismo padding
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: Column(                                                // NUEVO: columna botones
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(                                                     // NUEVO: título desarrollador
                    '🔧 Desarrollador',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),         // NUEVO: espaciado
                  _buildDebugButton(                                        // NUEVO: botón sync
                    context,
                    'FORZAR SINCRONIZACIÓN',
                    '🔄 Descargar lote desde Firestore ahora',
                    Colors.blue,
                    () => _forceSyncDatabase(context),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),          // NUEVO: espaciado botones
                  _buildDebugButton(                                        // NUEVO: botón limpiar
                    context,
                    'LIMPIAR BASE DE DATOS',
                    '⚠️ Borra todos los eventos guardados',
                    Colors.red,
                    () => _clearDatabase(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS EXISTENTES ==========
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
    bool isLightColor(Color color) {
      return color.computeLuminance() > 0.5;
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                            ? (isLightColor(color) ? Colors.black : Colors.white)
                            : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 14,
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

  // ========== NUEVOS MÉTODOS ========== // NUEVO: métodos para gestión datos
  Widget _buildCleanupColumn(BuildContext context, PreferencesProvider provider, String title, List<int> options, int currentValue, bool isEvents) {
    return Column(                                                          // NUEVO: columna cleanup
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(                                                               // NUEVO: título columna
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.paddingSmall),                    // NUEVO: espaciado
        ...options.map((days) => Padding(                                  // NUEVO: botones días
          padding: const EdgeInsets.only(bottom: AppDimens.paddingSmall),
          child: _buildCleanupButton(
            context,
            provider,
            days,
            currentValue,
            isEvents,
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCleanupButton(BuildContext context, PreferencesProvider provider, int days, int currentValue, bool isEvents) {
    final isSelected = days == currentValue;                               // NUEVO: verificar selección
    
    return SizedBox(                                                       // NUEVO: botón días fijo
      width: double.infinity,
      height: 32,
      child: Material(
        color: isSelected 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {                                                       // NUEVO: acción click
            if (isEvents) {
              provider.setEventCleanupDays(days);                          // NUEVO: actualizar eventos
            } else {
              provider.setFavoriteCleanupDays(days);                       // NUEVO: actualizar favoritos
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(                                                  // NUEVO: texto botón
                '$days días después',
                style: TextStyle(
                  color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton(BuildContext context, String title, String subtitle, Color color, VoidCallback onPressed) {
    return SizedBox(                                                       // NUEVO: botón debug completo
      width: double.infinity,
      child: Material(
        color: color.withOpacity(0.1),                                     // NUEVO: color suave
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,                                                 // NUEVO: acción
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),                  // NUEVO: border color
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(                                                       // NUEVO: título botón
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),                                 // NUEVO: espaciado
                Text(                                                       // NUEVO: subtítulo
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== ACCIONES DEBUG ========== // NUEVO: acciones botones
  Future<void> _forceSyncDatabase(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(                          // NUEVO: mostrar progreso
        const SnackBar(content: Text('🔄 Sincronizando con Firestore...')),
      );
      
      final syncService = SyncService();                                   // NUEVO: instancia sync
      final result = await syncService.performAutoSync();                 // NUEVO: forzar sync
      
      if (result.success) {                                                // NUEVO: verificar resultado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Sincronización exitosa: ${result.eventsAdded} eventos')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${result.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(                          // NUEVO: manejo error
        SnackBar(content: Text('❌ Error inesperado: $e')),
      );
    }
  }

  Future<void> _clearDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(                              // NUEVO: diálogo confirmación
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Limpiar Base de Datos'),
          content: const Text('¿Estás seguro? Se borrarán todos los eventos guardados. Esta acción no se puede deshacer.'),
          actions: [
            TextButton(                                                     // NUEVO: botón cancelar
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(                                                     // NUEVO: botón confirmar
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Borrar Todo'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {                                               // NUEVO: ejecutar si confirma
      try {
        final repository = EventRepository();                              // CAMBIO: instancia repository
        await repository.clearAllData();                                   // CAMBIO: método que sí existe                // NUEVO: limpiar datos
        
        ScaffoldMessenger.of(context).showSnackBar(                        // NUEVO: confirmar limpieza
          const SnackBar(content: Text('✅ Base de datos limpiada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(                        // NUEVO: manejo error
          SnackBar(content: Text('❌ Error limpiando: $e')),
        );
      }
    }
  }
}

// 📋 RESEÑA PARA BORRAR EN PRODUCCIÓN:
// 
// PARA ELIMINAR LOS BOTONES DEBUG en producción, borrar:
// 
// 1. Import (línea 4):
// dartimport 'package:quehacemos_cba/src/services/services.dart'; // ELIMINAR esta línea🔥
// 
// 2. Card completo desarrollador (líneas 190):
// BUSCAR:
      // ========== CARD 4: DESARROLLADOR ========== 🔥
// NUEVO: card desarrollador completo
// const SizedBox(height: AppDimens.paddingMed

// BORRAR todo ese bloque y dejar solo:🔥


//        ],
//      ),
//    );
//  }

// 3. Métodos debug 

//BORRAR: Todo desde línea 461 hasta el final,🔥
// EXCEPTO el último } 🔥

// dart// ========== ACCIONES DEBUG ==========
// ELIMINAR: _forceSyncDatabase()
// ELIMINAR: _clearDatabase()
// ELIMINAR: _buildDebugButton()
// 
// Con esos 3 cambios tienes la versión de producción limpia 🚀

//RESUMEN:

//✅ Líneas 1-189: MANTENER (cards tema, categorías, gestión datos)
//❌ Líneas 190-227: BORRAR (card desarrollador)
//✅ Líneas 228-460: MANTENER (métodos cleanup)
//❌ Líneas 461-final: BORRAR (métodos debug)
//✅ Último }: MANTENER (cierre de clase)
