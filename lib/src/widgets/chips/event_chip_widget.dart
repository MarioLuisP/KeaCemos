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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? adjustedColor : adjustedColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        border: Border.all(
          color: isSelected ? adjustedColor : AppColors.dividerGrey,
        ),
      ),
      height: AppDimens.chipHeight,
      child: InkWell(
        onTap: () {
          provider.toggleFilterCategory(category);
        },
        child: Center(
          child: Text(
            category,
            style: AppStyles.chipLabel,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}