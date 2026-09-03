import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/widget_themes/appbar_theme.dart';
import '../theme/widget_themes/bottom_sheet_theme.dart';
import '../theme/widget_themes/checkbox_theme.dart';
import '../theme/widget_themes/chip_theme.dart';
import '../theme/widget_themes/elevated_button_theme.dart';
import '../theme/widget_themes/outlined_button_theme.dart';
import '../theme/widget_themes/text_button_theme.dart';
import '../theme/widget_themes/text_field_theme.dart';
import '../theme/widget_themes/text_theme.dart';

/// Uygulama teması.
///
/// Sayfa zemini beyaz kalır; bölümler arası ayrım gölgeyle değil 1px
/// `borderSecondary` çizgiyle verilir (TASARIM.md §5). Karanlık tema
/// referanstan korunmuştur, değerleri TASARIM.md §8'den gelir.
class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    disabledColor: TColors.grey,
    brightness: Brightness.light,
    primaryColor: TColors.primary,
    textTheme: TTextTheme.lightTextTheme,
    chipTheme: TChipTheme.lightChipTheme,
    scaffoldBackgroundColor: TColors.white,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    textButtonTheme: TTextButtonTheme.lightTextButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primary,
      brightness: Brightness.light,
      primary: TColors.primary,
      surface: TColors.white,
      error: TColors.error,
    ),
    dividerTheme: const DividerThemeData(
      color: TColors.borderSecondary,
      thickness: TSizes.dividerHeight,
      space: TSizes.dividerHeight,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: TColors.primary),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: TColors.primary,
      selectionHandleColor: TColors.primary,
      selectionColor: Color(0x334A57E8),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    disabledColor: TColors.darkerGrey,
    brightness: Brightness.dark,
    primaryColor: TColors.primary,
    textTheme: TTextTheme.darkTextTheme,
    chipTheme: TChipTheme.darkChipTheme,
    scaffoldBackgroundColor: TColors.darkBackground,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    textButtonTheme: TTextButtonTheme.darkTextButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TColors.primary,
      brightness: Brightness.dark,
      primary: TColors.primary,
      surface: TColors.darkSurface,
      error: TColors.error,
    ),
    dividerTheme: const DividerThemeData(
      color: TColors.darkBorder,
      thickness: TSizes.dividerHeight,
      space: TSizes.dividerHeight,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: TColors.primary),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: TColors.white,
      selectionHandleColor: TColors.white,
      selectionColor: Color(0x33FFFFFF),
    ),
  );
}
