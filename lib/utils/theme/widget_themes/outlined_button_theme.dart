import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// İkincil düğme (TASARIM.md §6).
///
/// Beyaz zemin + `borderPrimary` çerçeve; **basılınca** indigo çerçeve ve
/// `accent` zemin. Durum renkleri `styleFrom` ile verilemediği için stil
/// elle kuruldu. Bir ızgarada 10 dolu indigo düğme ekranı bağırtıyor; sakin
/// düğme bu yüzden var.
class TOutlinedButtonTheme {
  TOutlinedButtonTheme._();

  static ButtonStyle _style({
    required Color background,
    required Color pressedBackground,
    required Color border,
    required Color foreground,
  }) {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(TSizes.buttonWidth, TSizes.buttonHeight)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: TSizes.sm)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius))),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return TColors.buttonDisabled;
        if (states.contains(WidgetState.pressed)) return pressedBackground;
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return TColors.darkGrey;
        if (states.contains(WidgetState.pressed)) return TColors.primary;
        return foreground;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return const BorderSide(color: TColors.buttonDisabled);
        if (states.contains(WidgetState.pressed)) return const BorderSide(color: TColors.primary);
        return BorderSide(color: border);
      }),
    );
  }

  /// Aydınlık tema
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: _style(
      background: TColors.white,
      pressedBackground: TColors.accent,
      border: TColors.borderPrimary,
      foreground: TColors.textPrimary,
    ),
  );

  /// Karanlık tema
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: _style(
      background: TColors.darkSurface,
      pressedBackground: TColors.darkAccent,
      border: TColors.darkBorder,
      foreground: TColors.light,
    ),
  );
}
