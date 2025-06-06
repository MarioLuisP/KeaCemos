import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimens.dart'; // Añadido para resolver el error

class AppStyles {
  static final titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static final cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static final cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
  );

  static final chipLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );
}