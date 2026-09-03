import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Süzgeç/etiket hapları. Seçili hap indigo, seçilmeyen yumuşak gri zeminde
/// ince çerçeveli — TASARIM.md §6'daki "hap rozet" diliyle aynı.
class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    backgroundColor: TColors.softGrey,
    disabledColor: TColors.grey.withValues(alpha: 0.4),
    side: const BorderSide(color: TColors.borderSecondary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: const TextStyle(color: TColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    backgroundColor: TColors.darkSurface,
    disabledColor: TColors.darkerGrey,
    side: const BorderSide(color: TColors.darkBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: const TextStyle(color: TColors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
  );
}
