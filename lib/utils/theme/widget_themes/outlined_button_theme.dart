import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// İkincil (çerçeveli) düğme teması.
///
/// TASARIM.md §6: beyaz zemin + `borderPrimary` çerçeve; basılınca indigo
/// çerçeve + `accent` zemin. Basılı hâl `WidgetStateProperty` ile veriliyor,
/// çünkü `styleFrom` tek bir sabit çerçeve rengi alıyor.
class TOutlinedButtonTheme {
  TOutlinedButtonTheme._(); // Örnek oluşturulmasını engeller

  /* -- Açık tema -- */
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.textPrimary,
      backgroundColor: TColors.white,
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonVerticalPadding, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
          return const BorderSide(color: TColors.primary);
        }
        return const BorderSide(color: TColors.borderPrimary);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return TColors.accent;
        return TColors.white;
      }),
    ),
  );

  /* -- Karanlık tema -- */
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.light,
      backgroundColor: Colors.transparent,
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonVerticalPadding, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textWhite, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
          return const BorderSide(color: TColors.primary);
        }
        return const BorderSide(color: TColors.darkBorder);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return TColors.darkAccent;
        return Colors.transparent;
      }),
    ),
  );
}
