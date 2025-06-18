import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData normalTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFF0E2D7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 172, 111, 41),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    colorScheme: ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Colors.cyan,
      surface: Colors.grey[900]!,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.cyan,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData fluorTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.pinkAccent,
    colorScheme: const ColorScheme.dark(
      primary: Colors.pinkAccent,
      secondary: Colors.limeAccent,
      surface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.cyanAccent,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
      bodyMedium: TextStyle(color: Colors.limeAccent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData harmonyTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: CustomColors.peach,
    colorScheme: const ColorScheme.light(
      primary: CustomColors.peach,
      secondary: CustomColors.mint,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.peach,
      foregroundColor: Colors.black87,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: CustomColors.mint,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData sepiaTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF6B4E31), // Marrón oscuro
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6B4E31),
      secondary: Color(0xFFA38C7A), // Marrón piedra
      surface: Color(0xFFF8F1E9), // Pergamino claro
    ),
    scaffoldBackgroundColor: Color(0xFFF8F1E9), // Pergamino claro
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6B4E31), // Marrón oscuro
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFA38C7A), // Marrón piedra
      unselectedItemColor: Colors.grey,
    ),
  );

  static Map<String, ThemeData> themes = {
    'normal': normalTheme,
    'dark': darkTheme,
    'fluor': fluorTheme,
    'harmony': harmonyTheme,
    'sepia': sepiaTheme,
  };
}

class CustomColors {
  static const peach = Color(0xFFFFE4B5);
  static const mint = Color(0xFF98FF98);
}