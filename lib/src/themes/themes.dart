import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData normalTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
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
    textTheme: TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.cyan,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData fluorTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.pinkAccent,
    colorScheme: ColorScheme.dark(
      primary: Colors.pinkAccent,
      secondary: Colors.limeAccent,
      surface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.cyanAccent,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
      bodyMedium: TextStyle(color: Colors.limeAccent),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData harmonyTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: CustomColors.peach,
    colorScheme: ColorScheme.light(
      primary: CustomColors.peach,
      secondary: CustomColors.mint,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: CustomColors.peach,
      foregroundColor: Colors.black87,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: CustomColors.mint,
      unselectedItemColor: Colors.grey,
    ),
  );

  static Map<String, ThemeData> themes = {
    'normal': normalTheme,
    'dark': darkTheme,
    'fluor': fluorTheme,
    'harmony': harmonyTheme,
  };
}

class CustomColors {
  static const peach = Color(0xFFFFE4B5); // Melocotón
  static const mint = Color(0xFF98FF98); // Menta
}