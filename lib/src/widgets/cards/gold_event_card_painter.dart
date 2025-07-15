import 'package:flutter/material.dart';
import 'silver_event_card_painter.dart';
import 'gold_shimmer_manager.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';

/// Painter para eventos Gold (Rating 300)
/// Hereda badge + borde de SilverEventCardPainter y agrega shimmer animado
class GoldEventCardPainter extends SilverEventCardPainter {
  final Animation<double>? shimmerAnimation;
  
  GoldEventCardPainter({
    required super.title,
    required super.categoryWithEmoji,
    required super.formattedDate,
    required super.location,
    required super.district,
    required super.price,
    required super.isFavorite,
    required super.theme,
    required super.category,
    this.shimmerAnimation,
    super.onFavoriteTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // PASO 1: Pintar tarjeta Silver completa (badge + borde)
    super.paint(canvas, size);
    // PASO 2: Agregar shimmer dorado animado usando el singleton
    _drawGoldShimmer(canvas, size);
  }

  /// Dibuja el efecto shimmer que cruza la tarjeta cada 3 segundos
  void _drawGoldShimmer(Canvas canvas, Size size) {
    final shimmerAnimation = GoldShimmerManager.instance.animation;
    
    if (shimmerAnimation == null || shimmerAnimation.value <= 0.0) {
      return;
    }
    
    // Calcular posición del shimmer (de izquierda a derecha)
    final shimmerProgress = shimmerAnimation.value;
    final shimmerX = (size.width + 100) * shimmerProgress - 50;

    // Gradient del shimmer inclinado (transparente → dorado → transparente)
    final shimmerGradient = LinearGradient(
      begin: Alignment(-0.6, -1.0),  // ← Inclina el gradient
      end: Alignment(0.6, 1.0),      // ← Ajusta estos valores para cambiar el ángulo
      colors: [
        Colors.transparent,
        _getShimmerColor().withOpacity(0.6), // Color dorado adaptativo
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // Paint del shimmer
    final shimmerPaint = Paint()
      ..shader = shimmerGradient.createShader(
        Rect.fromLTWH(shimmerX - 50, -50, 100, size.height + 100)
      );

    // Path del shimmer (misma forma que la tarjeta para no salirse)
    final shimmerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(AppDimens.borderRadius),
      ));

    // Dibujar shimmer con clipping
    canvas.save();
    canvas.clipPath(shimmerPath);
    canvas.drawRect(
      Rect.fromLTWH(shimmerX - 25, 0, 50, size.height),
      shimmerPaint,
    );
    canvas.restore();
  }

  /// Obtiene el color del shimmer según el tema
  Color _getShimmerColor() {
    switch (theme) {
      case 'dark':
      case 'fluor':
        return const Color(0xFFFFD700); // Oro brillante
      case 'normal':
      case 'pastel':
        return const Color(0xFFDAA520); // Oro medio más visible
      case 'sepia':
        return const Color(0xFFCD853F); // Oro terroso
      case 'harmony':
        return const Color(0xFFFFD700); // Oro clásico
      default:
        return const Color(0xFFDAA520); // Fallback oro medio
    }
  }

  @override
  bool shouldRepaint(GoldEventCardPainter oldDelegate) {
    return true; // Siempre repintar cuando hay shimmer
  }
}