import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/event_detail_modal.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'event_card_painter.dart';
import 'package:quehacemos_cba/src/providers/category_constants.dart'; // NUEVO
import 'destacado_event_card_painter.dart'; // NUEVO
import 'silver_event_card_painter.dart';

/// Widget optimizado para renderizar tarjetas de eventos a 90Hz
/// Reemplaza a EventCardWidget con un CustomPaint de alto rendimiento
class FastEventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final HomeViewModel viewModel;
  
  const FastEventCard({
    super.key,
    required this.event,
    required this.viewModel,
  });

  @override
  State<FastEventCard> createState() => _FastEventCardState();
}

class _FastEventCardState extends State<FastEventCard> {
  // Estado local para favoritos (sin Consumer)
  late bool _isFavorite;
  late FavoritesProvider _favoritesProvider;
  
  @override
  void initState() {
    super.initState();
    _favoritesProvider = context.read<FavoritesProvider>();
    _isFavorite = _favoritesProvider.isFavorite(widget.event['id'].toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualizar estado de favorito si cambia externamente
    final newFavoriteState = _favoritesProvider.isFavorite(widget.event['id'].toString());
    if (newFavoriteState != _isFavorite) {
      setState(() {
        _isFavorite = newFavoriteState;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _favoritesProvider.toggleFavorite(widget.event['id'].toString());
  }

  @override
  Widget build(BuildContext context) {
    // Extraer datos una sola vez
    final eventTitle = widget.event['title'] ?? '';
    final eventType = widget.event['type'] ?? '';
    final eventLocation = widget.event['location'] ?? '';
    final eventDistrict = widget.event['district'] ?? '';
    final eventDate = widget.event['date'] ?? '';
    final eventPrice = widget.event['price'] ?? '';
    
    final formattedDate = widget.viewModel.formatEventDate(
      eventDate,
      format: 'card',
    );
    
    final categoryWithEmoji = widget.viewModel.getCategoryWithEmoji(eventType);
    final theme = context.read<PreferencesProvider>().theme;
    final uiCategory = CategoryConstants.getUiName(eventType.toLowerCase()); 
    print('DEBUG - Original eventType: "$eventType"');
    print('DEBUG - Normalized uiCategory: "$uiCategory"');

    return GestureDetector(
      onTapDown: (details) {
        // Obtener la posición relativa del tap
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        
        // Crear un painter temporal para verificar el hit test
        final painter = EventCardPainter(
          title: eventTitle,
          categoryWithEmoji: categoryWithEmoji,
          formattedDate: formattedDate,
          location: eventLocation,
          district: eventDistrict,
          price: eventPrice,
          isFavorite: _isFavorite,
          theme: theme,
          category: uiCategory,
        );
        
        // Si tocó el corazón, toggle favorito
        if (painter.hitTestHeart(localPosition)) {
          _toggleFavorite();
        } else {
          // Si no, abrir el modal de detalles
          EventDetailModal.show(context, widget.event, widget.viewModel);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: RepaintBoundary( // Optimización adicional
          child: CustomPaint(
            size: const Size(double.infinity, 236), // Altura fija🔥🔥🔥
            painter: SilverEventCardPainter(
              title: eventTitle,
              categoryWithEmoji: categoryWithEmoji,
              formattedDate: formattedDate,
              location: eventLocation,
              district: eventDistrict,
              price: eventPrice,
              isFavorite: _isFavorite,
              theme: theme,
              category: uiCategory,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar tarjetas premium con efectos especiales
/// TODO: Implementar cuando se active el modelo de monetización
//class PremiumEventCard extends FastEventCard {
 // const PremiumEventCard({
  //  super.key,
 //   required super.event,
 //   required super.viewModel,
 // });

 // @override
// PremiumEventCardState? premiumState;
// TODO: Activar cuando se implemente PremiumEventCardState
//}

//class _PremiumEventCardState extends _FastEventCardState {
 // @override
 // Widget build(BuildContext context) {
    // Por ahora, usar la misma implementación
    // TODO: Cambiar a PremiumEventCardPainter cuando esté listo
 //   return super.build(context);
 // }
//}