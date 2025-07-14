import 'package:flutter/material.dart';
import 'event_card_painter.dart';

/// Painter para eventos destacados (Rating 100)
/// Hereda toda la funcionalidad de EventCardPainter y agrega badge 🏅
class DestacadoEventCardPainter extends EventCardPainter {
  DestacadoEventCardPainter({
    required super.title,
    required super.categoryWithEmoji,
    required super.formattedDate,
    required super.location,
    required super.district,
    required super.price,
    required super.isFavorite,
    required super.theme,
    required super.category,
    super.onFavoriteTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // PASO 1: Pintar la tarjeta normal completa
    super.paint(canvas, size);
    
    // PASO 2: Agregar badge destacado 🏅
    _drawDestacadoBadge(canvas, size);
  }

  /// Dibuja el badge de "Destacado" en la esquina inferior derecha
  void _drawDestacadoBadge(Canvas canvas, Size size) {
    // Posición del badge (esquina inferior derecha con padding)
    const badgeSize = 40.0;
    const padding = 16.0;
    
    final badgeX = size.width - padding - badgeSize;
    final badgeY = size.height - padding - badgeSize;
    
    // TextPainter para el emoji 🏅
    final badgeTextPainter = TextPainter(
      text: const TextSpan(
        text: '🏅',
        style: TextStyle(
          fontSize: badgeSize,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Layout y paint del badge
    badgeTextPainter.layout();
    badgeTextPainter.paint(
      canvas, 
      Offset(badgeX, badgeY),
    );
  }

  @override
  bool shouldRepaint(DestacadoEventCardPainter oldDelegate) {
    // Heredar la lógica de repaint del padre + verificar si es el mismo tipo
    return super.shouldRepaint(oldDelegate);
  }
}