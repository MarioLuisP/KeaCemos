import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/utils.dart';
import '../../providers/preferences_provider.dart';

class EventChipWidget extends StatelessWidget {
  final String category;

  const EventChipWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);
    final isSelected = provider.activeFilterCategories.contains(category);
    final color = AppColors.categoryColors[category] ?? AppColors.defaultColor;
    final adjustedColor = AppColors.adjustForTheme(context, color);
    final inactiveColor = AppColors.dividerGrey.withOpacity(0.3);

    return ChipTheme(
      data: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        backgroundColor: Colors.transparent,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? adjustedColor : inactiveColor,
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          border: Border.all(
            color: isSelected ? adjustedColor : AppColors.dividerGrey,
            width: 1.0,
          ),
        ),
        height: AppDimens.chipHeight,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          onTap: () {
            provider.toggleFilterCategory(category);
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Aumentado
              child: Text(
                category,
                style: AppStyles.chipLabel.copyWith(
                  color: isSelected ? AppColors.textDark : AppColors.textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}