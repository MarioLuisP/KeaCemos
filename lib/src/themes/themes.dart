import 'package:flutter/material.dart';

class AppThemes {
 static final ThemeData normalTheme = (() {
  final Color baseAppBarColor = Color(0xFFE48832); // marrón
  final Color secondaryLerped = Color.lerp(baseAppBarColor, Colors.white, 0.35)!; // 20% blanco mezclado

  return ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: secondaryLerped,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFF0E2D7),
    appBarTheme: AppBarTheme(
      backgroundColor: baseAppBarColor,
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
})();

static final ThemeData darkTheme = (() {
  final Color baseAppBarColor = Colors.grey[900]!;
  final Color secondaryLerped = Color.lerp(baseAppBarColor, Colors.white, 0.35)!;

  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    colorScheme: ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: secondaryLerped,
      surface: Colors.grey[900]!,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: baseAppBarColor,
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
})();

static final ThemeData fluorTheme = (() {
  final Color baseAppBarColor = Colors.black;
  final Color secondaryLerped = Color.lerp(baseAppBarColor, Colors.white, 0.35)!;

  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.pinkAccent,
    colorScheme: ColorScheme.dark(
      primary: Colors.pinkAccent,
      secondary: secondaryLerped,
      surface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: baseAppBarColor,
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
})();


static final ThemeData harmonyTheme = (() {
  final Color baseAppBarColor = CustomColors.peach;
  final Color secondaryLerped = Color.lerp(baseAppBarColor, Colors.white, 0.35)!;

  return ThemeData(
    brightness: Brightness.light,
    primaryColor: CustomColors.peach,
    colorScheme: ColorScheme.light(
      primary: CustomColors.peach,
      secondary: secondaryLerped,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: baseAppBarColor,
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
})();

static final ThemeData sepiaTheme = (() {
  final Color baseAppBarColor = const Color(0xFF6B4E31);
  final Color secondaryLerped = Color.lerp(baseAppBarColor, Colors.white, 0.35)!;

  return ThemeData(
    brightness: Brightness.light,
    primaryColor: baseAppBarColor,
    colorScheme: ColorScheme.light(
      primary: baseAppBarColor,
      secondary: secondaryLerped,
      surface: const Color(0xFFF8F1E9),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F1E9),
    appBarTheme: AppBarTheme(
      backgroundColor: baseAppBarColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFA38C7A),
      unselectedItemColor: Colors.grey,
    ),
  );
})();

  // Nuevo tema pastel basado en los colores del tema normal
  static final ThemeData pastelTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color.lerp(Colors.blue, Colors.white, 0.7)!,
    colorScheme: ColorScheme.light(
      primary: Color.lerp(Colors.blue, Colors.white, 0.7)!,
      secondary: Color(0xFFF0E2D7), 
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Color.lerp(Color.fromARGB(255, 196, 140, 76), Colors.white, 0.3)!,
    appBarTheme: AppBarTheme(
      backgroundColor: Color.lerp(Color(0xFFE4CDB2), Colors.white, 0.6)!,
      foregroundColor: Colors.black87,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Color.lerp(Colors.blue, Colors.white, 0.4)!,
      unselectedItemColor: Colors.grey,
    ),
  );

  static Map<String, ThemeData> themes = {
    'normal': normalTheme,
    'dark': darkTheme,
    'fluor': fluorTheme,
    'harmony': harmonyTheme,
    'sepia': sepiaTheme,
    'pastel': pastelTheme,
  };
}

class CustomColors {
  static const peach = Color(0xFFFFE4B5);
  static const mint = Color(0xFF98FF98);
}