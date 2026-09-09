import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Çip (süzgeç etiketi) teması.
///
/// Seçili çip indigo, seçili olmayan beyaz + `borderPrimary` çerçeve —
/// TASARIM.md §6'daki ikincil düğme diliyle aynı. Gölge yok.
class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    elevation: 0,
    pressElevation: 0,
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    backgroundColor: TColors.white,
    disabledColor: TColors.softGrey,
    side: const BorderSide(color: TColors.borderPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusSm)),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: const TextStyle(color: TColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    elevation: 0,
    pressElevation: 0,
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    backgroundColor: TColors.darkSurface,
    disabledColor: TColors.darkerGrey,
    side: const BorderSide(color: TColors.darkBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusSm)),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: const TextStyle(color: TColors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
  );
}
