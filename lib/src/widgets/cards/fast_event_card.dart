import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/event_detail_modal.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/providers/category_constants.dart';
import 'unified_event_card_painter.dart';  // EL NUEVO PAINTER
import 'gold_shimmer_manager.dart';        // TUS JOYAS
import 'gold_shimmer_painter.dart';        // TUS JOYAS
import 'platinum_particles_painter.dart';  // TUS JOYAS
import 'platinum_particles_manager.dart';  // TUS JOYAS

/// Widget optimizado para renderizar tarjetas de eventos a 90Hz
/// Usa UnifiedEventCardPainter para ratings 0-200
/// Stack con capas adicionales para ratings 300+
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
    
    // Inicializar managers para Gold/Platinum (TUS JOYAS)
    _initializeManagers();
  }

  void _initializeManagers() {
    final rating = widget.event['rating'] ?? 0;
    
    if (rating >= 300) {
      // Inicializar GoldShimmerManager (TU JOYA)
      GoldShimmerManager.instance.initialize(this);
      GoldShimmerManager.instance.addListener(_onShimmerUpdate);
      
      if (rating >= 400) {
        // Inicializar PlatinumParticlesManager (TU JOYA)
        PlatinumParticlesManager.instance.initialize(this);
        PlatinumParticlesManager.instance.addListener(_onShimmerUpdate);
      }
    }
  }

  void _onShimmerUpdate() {
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

  /// Crea el UnifiedEventCardPainter con todos los datos necesarios
  UnifiedEventCardPainter _createUnifiedPainter(int rating) {
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
    
    return UnifiedEventCardPainter(
      rating: rating,
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

  @override
  Widget build(BuildContext context) {
    final rating = widget.event['rating'] ?? 0;
    final theme = context.read<PreferencesProvider>().theme;
    
    return GestureDetector(
      onTapDown: (details) {
        // Obtener la posición relativa del tap
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;  // Size ya disponible GRATIS
        final localPosition = box.globalToLocal(details.globalPosition);
        
        // Crear painter para hacer hit test
        final painter = _createUnifiedPainter(rating);
        
        // Si tocó el corazón, toggle favorito
        if (painter.hitTestHeart(localPosition, size)) {
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
        child: RepaintBoundary(
          child: rating >= 300
            ? Stack(
                children: [
                  // CAPA 1: Silver completo (rating forzado a 200)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(double.infinity, 236),
                      painter: _createUnifiedPainter(200), // FORZAR SILVER
                      isComplex: true,
                      willChange: false,
                    ),
                  ),
                  // CAPA 2: Shimmer dorado (TU JOYA)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(double.infinity, 236),
                      painter: GoldShimmerPainter(theme: theme),
                    ),
                  ),
                  // CAPA 3: Partículas si es Platinum (TU JOYA)
                  if (rating >= 400)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(double.infinity, 236),
                        painter: PlatinumParticlesPainter(
                          animation: PlatinumParticlesManager.instance.animation!,
                          theme: theme,
                        ),
                      ),
                    ),
                ],
              )
            // Para ratings 0-200: Un solo painter unificado
            : RepaintBoundary(
                child: CustomPaint(
                  size: const Size(double.infinity, 236),
                  painter: _createUnifiedPainter(rating),
                  isComplex: true,
                  willChange: false,
                ),
              ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final rating = widget.event['rating'] ?? 0;
    
    if (rating >= 300) {
      GoldShimmerManager.instance.removeListener(_onShimmerUpdate);
      
      if (rating >= 400) {
        PlatinumParticlesManager.instance.removeListener(_onShimmerUpdate);
      }
    }
    
    super.dispose();
  }
}