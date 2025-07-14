import 'package:flutter/material.dart';
import 'destacado_event_card_painter.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';

/// Painter para eventos Silver (Rating 200)
/// Hereda el badge de DestacadoEventCardPainter y agrega borde dorado
class SilverEventCardPainter extends DestacadoEventCardPainter {
  SilverEventCardPainter({
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
    // PASO 1: Pintar tarjeta normal + badge destacado
    super.paint(canvas, size);
    
    // PASO 2: Agregar borde dorado Silver
    _drawSilverBorder(canvas, size);
  }

  /// Dibuja el borde dorado alrededor de toda la tarjeta
  void _drawSilverBorder(Canvas canvas, Size size) {
    // Paint para el borde dorado adaptativo por tema
    final borderPaint = Paint()
      ..color = _getBorderColor() // CAMBIO: Color adaptativo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  /// Obtiene el color del borde según el tema para máxima visibilidad
  Color _getBorderColor() {
    switch (theme) {
      case 'dark':
      case 'fluor':
        return const Color(0xFFFFD700); // Oro clásico brillante
      case 'normal':
      case 'pastel':
        return const Color(0xFFB8860B); // Oro oscuro (DarkGoldenRod)
      case 'sepia':
        return const Color(0xFFCD853F); // Oro terroso (Peru)
      case 'harmony':
        return const Color(0xFFDAA520); // Oro medio (GoldenRod)
      default:
        return const Color(0xFFB8860B); // Fallback oro oscuro
    }

    // Path del borde (misma forma que la tarjeta)
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), // Ajuste para el grosor del borde
        Radius.circular(AppDimens.borderRadius),
      ));

    // Dibujar el borde dorado
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(SilverEventCardPainter oldDelegate) {
    // Heredar la lógica de repaint del padre
    return super.shouldRepaint(oldDelegate);
  }
}