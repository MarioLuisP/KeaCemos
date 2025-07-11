import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/event_detail_modal.dart'; // Nueva importación
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/providers/category_constants.dart'; // NUEVO
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:quehacemos_cba/src/utils/colors.dart'; // NUEVO: Para EventCardColorPalette
import 'package:quehacemos_cba/src/providers/preferences_provider.dart'; // NUEVO: Para acceder al theme

class EventCardWidget extends StatelessWidget {
  final Map<String, dynamic> event; // CAMBIO: String → dynamic
  final HomeViewModel viewModel;
  const EventCardWidget({
    super.key,
    required this.event,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // Cache valores para evitar recálculos
    final eventId = event['id']!;
    final eventTitle = event['title']!;
    final eventType = event['type'] ?? '';
    final eventLocation = event['location'] ?? '';
    final eventDate = event['date']!;

    final formattedDateString = viewModel.formatEventDate(
      eventDate,
      format: 'card',
    );

    // NUEVO: Lookup instantáneo de colores precalculados
    final theme = Provider.of<PreferencesProvider>(context, listen: false).theme; 
    final uiCategory = CategoryConstants.getUiName(eventType.toLowerCase()); // NUEVO
    final colors = EventCardColorPalette.getColors(theme, uiCategory); // CAMBIO
    final categoryWithEmoji = viewModel.getCategoryWithEmoji(eventType); // NUEVO
    return GestureDetector(
      onTap: () {
        // CAMBIO: Usar modal en lugar de Navigator.push
        EventDetailModal.show(context, event, viewModel);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        child: Container(
          height: 236, // NUEVO: Altura fija para todas las tarjetas
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.base,
                colors.dark,
              ], // CAMBIO: Usar colores precalculados
            ),
            borderRadius: BorderRadius.circular(AppDimens.borderRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        // NUEVO: Container con altura fija
                        height: 26, // NUEVO: Altura específica para el título
                        child: Text(
                          eventTitle,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                colors.text, // CAMBIO: Usar color precalculado
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: AppDimens.paddingSmall),
                      SizedBox( // MANTENER: Container con altura fija
                        height: 26, // CAMBIO: Nueva altura de 24 → 26
                        child: Text(
                          categoryWithEmoji, // MANTENER: Usar valor cacheado
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.text.withOpacity(0.9),
                            height: 1.0, // NUEVO: Control de altura de línea
                            leadingDistribution: TextLeadingDistribution.even, // NUEVO: Distribución uniforme
                          ),
                          textHeightBehavior: const TextHeightBehavior( // NUEVO: Comportamiento de altura
                            applyHeightToFirstAscent: false, // NUEVO: No aplicar altura al ascenso
                            applyHeightToLastDescent: false, // NUEVO: No aplicar altura al descenso
                          ),
                          maxLines: 1, // MANTENER: Forzar una línea
                          overflow: TextOverflow.ellipsis, // MANTENER: Cortar con puntos
                        ),
                      ),                     
                      const SizedBox(height: AppDimens.paddingSmall),
                      Container(
                        height: 0.5,
                        color: colors.text.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '🗓  $formattedDateString',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    colors
                                        .text, // CAMBIO: Usar color precalculado
                              ),
                            ),
                          ),
                          Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, child) {
                              final isFavorite = favoritesProvider.isFavorite(
                                eventId.toString(),
                              );
                              return IconButton(
                                iconSize: 24,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : colors.text,
                                ),
                                onPressed:
                                    () => favoritesProvider.toggleFavorite(
                                      eventId.toString(),
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📍', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventLocation ?? 'Sin ubicación',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontSize: 18,
                                    color:
                                        colors
                                            .text, // CAMBIO: Usar color precalculado
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  event['district'] ?? 'Sin distrito',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: colors.text.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      Text(
                        '🎟  ${event['price']?.isNotEmpty == true ? event['price']! : 'Consultar'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colors.text, // CAMBIO: Usar color precalculado
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
