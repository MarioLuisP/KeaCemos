import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';

// Colores basados en SettingsPage, consistentes con los temas
class AppColors {
  // Categorías
  static const musica = Color(0xFFCCE5FF); // Música
  static const teatro = Color(0xFFB2DFDB); // Teatro
  static const standUp = Color(0xFFFFF9C4); // StandUp
  static const arte = Color(0xFFFFECB3); // Arte
  static const cine = Color(0xFFE0E0E0); // Cine
  static const mic = Color(0xFFE1BEE7); // Mic
  static const cursos = Color(0xFFDCEDC8); // Talleres -> Cursos
  static const ferias = Color(0xFFFFCDD2); // Ferias
  static const calle = Color(0xFFB3E5FC); // Calle
  static const redes = Color(0xFFC8E6C9); // Comunidad -> Redes
  static const defaultColor = Color(0xFFE0E0E0); // Default

  // Otros colores usados
  static const dividerGrey = Colors.grey;
  static const textDark = Colors.black87;

  // Mapa de colores por categoría
  static const categoryColors = {
    'Música': musica,
    'Teatro': teatro,
    'StandUp': standUp,
    'Arte': arte,
    'Cine': cine,
    'Mic': mic,
    'Cursos': cursos,
    'Ferias': ferias,
    'Calle': calle,
    'Redes': redes,
  };

  // Ajustes para temas (Normal, Dark, Fluor, Harmony)
  static Color adjustForTheme(BuildContext context, Color color) {
    final theme = Provider.of<PreferencesProvider>(context, listen: false).theme;
    switch (theme) {
      case 'dark':
        return color.withOpacity(0.8); // Atenuar para tema oscuro
      case 'fluor':
        return color.withBrightness(1.2); // Aumentar brillo (simulado)
      case 'harmony':
        return color.withOpacity(0.9); // Suavizar para tonos pastel
      default:
        return color; // Normal
    }
  }
}

// Extensión para simular aumento de brillo
extension ColorBrightness on Color {
  Color withBrightness(double factor) {
    final r = (red * factor).clamp(0, 255).toInt();
    final g = (green * factor).clamp(0, 255).toInt();
    final b = (blue * factor).clamp(0, 255).toInt();
    return Color.fromARGB(alpha, r, g, b);
  }
}