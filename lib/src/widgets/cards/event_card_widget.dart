import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/event_detail_modal.dart'; // Nueva importación
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';

class EventCardWidget extends StatelessWidget {
  final Map<String, String> event;
  final HomeViewModel viewModel;
  String get event_district => 'Centro';
  const EventCardWidget({
    super.key,
    required this.event,
    required this.viewModel,
  });

  Color _darkenColor(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Función para determinar si un color es claro
  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.4;
  }

  // Función para obtener el color de texto que contrasta bien
  Color _getContrastingTextColor(Color backgroundColor) {
    return _isLightColor(backgroundColor) ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // Cache valores para evitar recálculos
    final eventId = event['id']!;
    final eventTitle = event['title']!;
    final eventType = event['type'] ?? '';
    final eventLocation = event['location'] ?? '';
    final eventDate = event['date']!;
    
    final formattedDateString = viewModel.formatEventDate(eventDate, format: 'card');
    final cardColor = viewModel.getEventCardColor(eventType, context);
    final darkCardColor = _darkenColor(cardColor, 0.2);
    
    // Calculamos el color promedio del gradiente para determinar el contraste
    final averageColor = Color.lerp(cardColor, darkCardColor, 0.5)!;
    final textColor = _getContrastingTextColor(averageColor);

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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, darkCardColor],
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
                      Text(
                        eventTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: AppDimens.paddingSmall),
                      Text(
                        viewModel.getCategoryWithEmoji(eventType),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      Container(
                        height: 0.5,
                        color: textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),  
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '🗓  $formattedDateString',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                              ),
                            ),
                          ),
                          Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, child) {
                              final isFavorite = favoritesProvider.isFavorite(eventId);
                              return IconButton(
                                iconSize: 24,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : textColor,
                                ),
                                onPressed: () => favoritesProvider.toggleFavorite(eventId),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📍',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventLocation ?? 'Sin ubicación',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 18,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  event_district ?? 'Sin distrito',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.7),
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
                              color: textColor,
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