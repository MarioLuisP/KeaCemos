import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/event_detail_modal.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/category_constants.dart';
import 'event_card_painter.dart';
import 'destacado_event_card_painter.dart';
import 'silver_event_card_painter.dart';
import 'gold_event_card_painter.dart';
import 'gold_shimmer_manager.dart';

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

class _FastEventCardState extends State<FastEventCard> with TickerProviderStateMixin {
  // Estado local para favoritos (sin Consumer)
  late bool _isFavorite;
  late FavoritesProvider _favoritesProvider;
  
  @override
  void initState() {
    super.initState();
    _favoritesProvider = context.read<FavoritesProvider>();
    _isFavorite = _favoritesProvider.isFavorite(widget.event['id'].toString());
    
    // NUEVO: Inicializar singleton solo una vez y suscribirse si es Gold
    _initializeGoldManager();
  }

  void _initializeGoldManager() {
    //final rating = widget.event['rating'] ?? 0;💥💥💥 descomentar los 3
    final rating = 300; // TEMPORAL
    
    if (rating >= 300) {
      // Inicializar el manager (solo se hace una vez globalmente)
      GoldShimmerManager.instance.initialize(this);
      // Suscribirse para recibir updates del shimmer
      GoldShimmerManager.instance.addListener(_onShimmerUpdate);
    }
  }

 void _onShimmerUpdate() {
  print('🟢 FAST EVENT CARD: Recibí update del shimmer');
  if (mounted) setState(() {});
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

  /// Factory que crea el painter correcto según el rating
  CustomPainter _createPainter(int rating) {
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
    
    // Factory pattern para crear el painter correcto
    switch (rating) {
      case 100:
        return DestacadoEventCardPainter(
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
      case 200:
        return SilverEventCardPainter(
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
      case 300:
        return GoldEventCardPainter(
          title: eventTitle,
          categoryWithEmoji: categoryWithEmoji,
          formattedDate: formattedDate,
          location: eventLocation,
          district: eventDistrict,
          price: eventPrice,
          isFavorite: _isFavorite,
          theme: theme,
          category: uiCategory,
          shimmerAnimation: GoldShimmerManager.instance.animation, // AGREGAR ESTA LÍNEA
          
        );
      // case 400: return PlatinumEventCardPainter(...);  // TODO: Futuro
      default:
        return EventCardPainter(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    //final rating = widget.event['rating'] ?? 0;💥💥💥
    final rating = 300; // TEMPORAL
    
    return GestureDetector(
      onTapDown: (details) {
        // Obtener la posición relativa del tap
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        
        // Crear un painter temporal para verificar el hit test
        final painter = _createPainter(rating);
        
        // Si tocó el corazón, toggle favorito
        if (painter is EventCardPainter && painter.hitTestHeart(localPosition)) {
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
            size: const Size(double.infinity, 236), // Altura fija
            painter: _createPainter(rating),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //final rating = widget.event['rating'] ?? 0;💥💥💥
    final rating = 300; // TEMPORAL
    if (rating >= 300) {
      GoldShimmerManager.instance.removeListener(_onShimmerUpdate);
    }
    super.dispose();
  }
}