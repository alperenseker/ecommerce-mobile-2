import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Onay kutusu teması.
///
/// Seçiliyken indigo dolgu + beyaz tik; seçili değilken şeffaf zemin ve
/// `borderPrimary` çerçeve. Referansta seçili olmayan hâlde tik rengi siyahtı,
/// zemin şeffaf olduğu için görünmüyordu; çerçeve rengi eklendi.
class TCheckboxTheme {
  TCheckboxTheme._(); // Örnek oluşturulmasını engeller

  /// Açık tema
  static CheckboxThemeData lightCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.xs)),
    side: const BorderSide(width: 1.5, color: TColors.borderPrimary),
    checkColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TColors.white;
      } else {
        return TColors.black;
      }
    }),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TColors.primary;
      } else {
        return Colors.transparent;
      }
    }),
  );

  /// Karanlık tema
  static CheckboxThemeData darkCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.xs)),
    side: const BorderSide(width: 1.5, color: TColors.darkBorder),
    checkColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TColors.white;
      } else {
        return TColors.black;
      }
    }),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TColors.primary;
      } else {
        return Colors.transparent;
      }
    }),
  );
}
