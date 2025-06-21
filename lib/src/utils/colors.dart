import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';

class AppColors {
  // Colores originales de las categorías
  static const musica = Color(0xFFFCA1AE);
  static const teatro = Color(0xFFD7D26D);
  static const standup = Color(0xFF3CCDC7);
  static const arte = Color(0xFFFD8977);
  static const cine = Color(0xFFEBE7A7);
  static const mic = Color(0xFFE1BEE7);
  static const cursos = Color(0xFFF5DD7E);
  static const ferias = Color(0xFFFFCDD2);
  static const calle = Color(0xFFB3E5FC);
  static const redes = Color(0xFFC8E6C9);
  static const ninos = Color(0xFFD6CBAE);
  static const danza = Color(0xFFFDA673);
  static const defaultColor = Color(0xFFE0E0E0);

  // Mapa de colores originales por categoría
  static const categoryColors = {
    'Música': musica,
    'Teatro': teatro,
    'StandUp': standup,
    'Arte': arte,
    'Cine': cine,
    'Mic': mic,
    'Cursos': cursos,
    'Ferias': ferias,
    'Calle': calle,
    'Redes': redes,
    'Niños': ninos,
    'Danza': danza,
  };

  // Colores sepia (tonos claros extraídos de los gradientes)
  static const sepiaColors = {
    'Música': Color(0xFFF5EBD0), // Arena
    'Teatro': Color(0xFFEAD8B0), // Ocre claro
    'StandUp': Color(0xFFF3E1D2), // Beige rosado
    'Arte': Color(0xFFD5B59B), // Tierra suave
    'Cine': Color(0xFFC4A484), // Tostado claro
    'Mic': Color(0xFFB68E72), // Canela
    'Cursos': Color(0xFFD9B08C), // Caramelo suave
    'Ferias': Color(0xFFD6CFC6), // Gris cálido
    'Calle': Color(0xFFE4C1A1), // Terracota claro
    'Redes': Color(0xFFA38C7A), // Marrón piedra
    'Niños': Color(0xFFF0E9E2), // Crema grisáceo
    'Danza': Color(0xFF7C5E48), // Madera oscura
  };



  static const dividerGrey = Colors.grey;
  static const textDark = Colors.black87;
  static const textLight = Colors.white70;

  // Ajustes para temas
  static Color adjustForTheme(BuildContext context, Color color) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false).theme;
    // Si el tema es sepia, buscar el color correspondiente en sepiaColors
    if (theme == 'sepia') {
      final category = categoryColors.entries
          .firstWhere(
            (entry) => entry.value == color,
            orElse: () => MapEntry('default', defaultColor),
          )
          .key;
      return sepiaColors[category] ?? defaultColor;
    }
    // Lógica original para otros temas
    switch (theme) {
      case 'dark':
        return color.withOpacity(0.8);
      case 'fluor':
        return color.withBrightness(1.2);
      case 'harmony':
        return color.withOpacity(0.9);
      case 'pastel':
        return Color.lerp(color, Colors.white, 0.7)!;
      default:
        return color;
    }
  }

  // Ajustar color de texto según el tema
  static Color getTextColor(BuildContext context) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false).theme;
    switch (theme) {
      case 'dark':
      case 'fluor':
        return textLight;
      case 'sepia':
      case 'harmony':
      case 'pastel':
      case 'normal':
      default:
        return textDark;
    }
  }
}

extension ColorBrightness on Color {
  Color withBrightness(double factor) {
    final r = (red * factor).clamp(0, 255).toInt();
    final g = (green * factor).clamp(0, 255).toInt();
    final b = (blue * factor).clamp(0, 255).toInt();
    return Color.fromARGB(alpha, r, g, b);
  }
}