import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/utils.dart';
import '../../providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/utils/colors.dart'; 
import 'package:quehacemos_cba/src/providers/category_constants.dart'; // NUEVO

class EventChipWidget extends StatelessWidget {
  final String category;

  const EventChipWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);
    final isSelected = provider.activeFilterCategories.contains(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // NUEVO: Lookup instantáneo para chips también
    final theme = Provider.of<PreferencesProvider>(context, listen: false).theme;
// CAMBIO: Normalizar category también para chips
    final uiCategory = CategoryConstants.getUiName(category.toLowerCase()); // NUEVO
    final colors = EventCardColorPalette.getColors(theme, uiCategory); // CAMBIO    final adjustedColor = colors.base; // CAMBIO: Usar color precalculado
    final inactiveBackground = isDark ? Colors.black : Colors.white;
    final inactiveTextColor = isDark ? Colors.white : Colors.black;
    final inactiveBorderColor = inactiveTextColor;

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
          color: isSelected ? colors.base : inactiveBackground, 
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
          border: Border.all(
            color: isSelected ? colors.base : inactiveBackground, 
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  Text(
                    category,
                    style: AppStyles.chipLabel.copyWith(
                      color: isSelected ? AppColors.textDark : inactiveTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
