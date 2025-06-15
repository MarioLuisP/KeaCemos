import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/pages/event_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';

class EventCardWidget extends StatelessWidget {
  final Map<String, String> event;
  final HomeViewModel viewModel;

  const EventCardWidget({
    Key? key,
    required this.event,
    required this.viewModel,
  }) : super(key: key);

  Color _darkenColor(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    // CAMBIO PRINCIPAL: Usar formato 'card' específico
    final formattedDateString = viewModel.formatEventDate(event['date']!, format: 'card');
    final cardColor = viewModel.getEventCardColor(event['type'] ?? '', context);
    final darkCardColor = _darkenColor(cardColor, 0.2);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
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
                        event['title']!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      
                      const SizedBox(height: AppDimens.paddingSmall),
                      Text(
                        viewModel.getCategoryWithEmoji(event['type'] ?? ''),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),  
                    Text(
                        // MEJORADO: Ya no dice "Fecha:" porque el emoji es suficiente
                        formattedDateString,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                               ),
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      Text(
                        '📍 ${event['location']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorite = favoritesProvider.isFavorite(event['id']!);
                      return IconButton(
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurface,
                        onPressed: () => viewModel.toggleFavorite(event['id']!, favoritesProvider),
                      );
                    },
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