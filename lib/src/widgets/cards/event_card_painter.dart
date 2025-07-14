import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quehacemos_cba/src/utils/colors.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';

/// Painter optimizado para renderizar tarjetas de eventos a 90Hz
/// Utiliza los 72 colores precalculados y minimiza las operaciones de pintado
class EventCardPainter extends CustomPainter {
  // Datos del evento
  final String title;
  final String categoryWithEmoji;
  final String formattedDate;
  final String location;
  final String district;
  final String price;
  final bool isFavorite;
  final String theme;
  final String category;
  
  // Callbacks
  final VoidCallback? onFavoriteTap;

  // Cache de Paints y TextPainters - ESTÁTICOS para reutilización
  static final Map<String, Paint> _shadowPaints = {};
  static final Map<String, TextPainter> _textPainters = {};
  static bool _initialized = false;

  EventCardPainter({
    required this.title,
    required this.categoryWithEmoji,
    required this.formattedDate,
    required this.location,
    required this.district,
    required this.price,
    required this.isFavorite,
    required this.theme,
    required this.category,
    this.onFavoriteTap,
  }) {
    // Inicializar recursos la primera vez
    if (!_initialized) {
      _initializeResources();
      _initialized = true;
    }
  }

  /// Inicializa todos los recursos estáticos una sola vez
  static void _initializeResources() {
    // Crear solo los shadow paints (los gradient paints se crean en paint())
    EventCardColorPalette.colors.forEach((themeName, themeColors) {
      themeColors.forEach((categoryName, colors) {
        final key = '$themeName-$categoryName';
        
        // Paint para la sombra (reutilizable)
        _shadowPaints[key] = Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      });
    });

    // Inicializar TextPainters base (sin texto)
    _textPainters['title'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    _textPainters['category'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    _textPainters['date'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    _textPainters['location'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    _textPainters['district'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    _textPainters['price'] = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    print('DEBUG - Theme: "$theme", Category: "$category"');
    print('DEBUG - Available categories: ${EventCardColorPalette.colors['normal']!.keys.toList()}');
    final colors = EventCardColorPalette.getColors(theme, category);
    print('DEBUG - Colors: base=${colors.base}, dark=${colors.dark}, text=${colors.text}');
    final paintKey = '$theme-$category';
    
    // Crear el paint del gradiente aquí con el tamaño real
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.base, colors.dark],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // 1. Dibujar sombra
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(AppDimens.borderRadius),
      ));
    canvas.drawPath(shadowPath, _shadowPaints[paintKey]!);
    
    // 2. Dibujar fondo con gradiente
    final backgroundPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(AppDimens.borderRadius),
      ));
    canvas.drawPath(backgroundPath, gradientPaint);
    
    // 3. Preparar y dibujar textos
    const leftPadding = AppDimens.paddingMedium;
    const rightPadding = AppDimens.paddingMedium;
    final textWidth = size.width - leftPadding - rightPadding - 40; // 40 para el corazón
    
    // Título
    _textPainters['title']!.text = TextSpan(
      text: title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.text,
      ),
    );
    _textPainters['title']!.layout(maxWidth: textWidth);
    _textPainters['title']!.paint(canvas, const Offset(leftPadding, 16));
    
    // Categoría con emoji
    _textPainters['category']!.text = TextSpan(
      text: categoryWithEmoji,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.text.withOpacity(0.9),
        height: 1.0,
      ),
    );
    _textPainters['category']!.layout(maxWidth: textWidth);
    _textPainters['category']!.paint(canvas, const Offset(leftPadding, 46));
    
    // Línea divisoria
    final linePaint = Paint()
      ..color = colors.text.withOpacity(0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftPadding, 80),
      Offset(size.width - rightPadding, 80),
      linePaint,
    );
    
    // Fecha
    _textPainters['date']!.text = TextSpan(
      text: '🗓  $formattedDate',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
    );
    _textPainters['date']!.layout(maxWidth: textWidth);
    _textPainters['date']!.paint(canvas, const Offset(leftPadding, 90));
    
    // Corazón de favoritos
    final heartPaint = Paint()
      ..color = isFavorite ? Colors.red : colors.text
      ..style = isFavorite ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Dibujar corazón simple con Path
    final heartPath = Path();
    const heartX = 320.0; // Posición X del corazón
    const heartY = 95.0;  // Posición Y del corazón
    const heartSize = 20.0;
    
    // Forma de corazón simplificada
    heartPath.moveTo(heartX + heartSize / 2, heartY + heartSize * 0.85);
    heartPath.cubicTo(
      heartX + heartSize * 0.2, heartY + heartSize * 0.6,
      heartX, heartY + heartSize * 0.3,
      heartX, heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX, heartY,
      heartX + heartSize * 0.5, heartY,
      heartX + heartSize / 2, heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX + heartSize / 2, heartY,
      heartX + heartSize, heartY,
      heartX + heartSize, heartY + heartSize * 0.3,
    );
    heartPath.cubicTo(
      heartX + heartSize, heartY + heartSize * 0.3,
      heartX + heartSize * 0.8, heartY + heartSize * 0.6,
      heartX + heartSize / 2, heartY + heartSize * 0.85,
    );
    canvas.drawPath(heartPath, heartPaint);
    
    // Ubicación con emoji
    _textPainters['location']!.text = TextSpan(
      text: '📍 $location',
      style: TextStyle(
        fontSize: 18,
        color: colors.text,
      ),
    );
    _textPainters['location']!.layout(maxWidth: textWidth);
    _textPainters['location']!.paint(canvas, const Offset(leftPadding, 125));
    
    // Distrito
    _textPainters['district']!.text = TextSpan(
      text: '     $district', // Espacios para alinear con el emoji
      style: TextStyle(
        fontSize: 14,
        color: colors.text.withOpacity(0.7),
      ),
    );
    _textPainters['district']!.layout(maxWidth: textWidth);
    _textPainters['district']!.paint(canvas, const Offset(leftPadding, 148));
    
    // Precio
    _textPainters['price']!.text = TextSpan(
      text: '🎟  ${price.isNotEmpty ? price : 'Consultar'}',
      style: TextStyle(
        fontSize: 16,
        color: colors.text,
      ),
    );
    _textPainters['price']!.layout(maxWidth: textWidth);
    _textPainters['price']!.paint(canvas, const Offset(leftPadding, 180));
  }

  @override
  bool shouldRepaint(EventCardPainter oldDelegate) {
    // Solo repintar si cambian datos relevantes
    return title != oldDelegate.title ||
           categoryWithEmoji != oldDelegate.categoryWithEmoji ||
           formattedDate != oldDelegate.formattedDate ||
           location != oldDelegate.location ||
           district != oldDelegate.district ||
           price != oldDelegate.price ||
           isFavorite != oldDelegate.isFavorite ||
           theme != oldDelegate.theme ||
           category != oldDelegate.category;
  }
  
  /// Método para detectar si se tocó el corazón
  bool hitTestHeart(Offset position) {
    // Área del corazón aproximada
    const heartRect = Rect.fromLTWH(310, 85, 40, 40);
    return heartRect.contains(position);
  }
}

/// Painter para tarjetas premium con efectos especiales
/// TODO: Implementar en el futuro para eventos destacados
class PremiumEventCardPainter extends EventCardPainter {
  PremiumEventCardPainter({
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
    // Primero pintar la tarjeta normal
    super.paint(canvas, size);
    
    // TODO: Agregar efectos premium
    // - Borde dorado animado
    // - Partículas flotantes
    // - Badge "DESTACADO"
    // - Efecto shimmer
  }
}