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

/// Uygulamanın açık ve karanlık teması.
///
/// Yapı referans uygulamayla aynı (aynı 9 bileşen teması, aynı alan adları);
/// değerler `faz/TASARIM.md`'den geliyor.
///
/// Referanstan iki ek var:
///  * **`colorScheme` açıkça veriliyor.** Referans yalnız `primaryColor`
///    ayarlıyordu; Material 3 bileşenleri (NavigationBar göstergesi, diyalog,
///    SnackBar) rengi `colorScheme`'den okuduğu için turuncu yerine indigo
///    istiyorsak burada tanımlamak zorunlu.
///  * **`dividerTheme`.** TASARIM.md §1: ayrımlar gölge değil 1px çizgi.
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

    /// Sayfa zemini beyaz değil, hafif gri-mavi: kartlar beyaz kalınca ayrım
    /// gölgesiz de okunuyor (TASARIM.md §1-§2).
    scaffoldBackgroundColor: TColors.light,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    textButtonTheme: TTextButtonTheme.lightTextButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    dividerTheme: const DividerThemeData(
      color: TColors.borderSecondary,
      thickness: TSizes.dividerHeight,
      space: TSizes.dividerHeight,
    ),
    colorScheme: const ColorScheme.light(
      primary: TColors.primary,
      onPrimary: TColors.white,
      primaryContainer: TColors.accent,
      onPrimaryContainer: TColors.secondary,
      secondary: TColors.secondary,
      onSecondary: TColors.white,
      surface: TColors.white,
      onSurface: TColors.textPrimary,
      surfaceContainerHighest: TColors.lightContainer,
      outline: TColors.borderPrimary,
      outlineVariant: TColors.borderSecondary,
      error: TColors.error,
      onError: TColors.white,
      errorContainer: TColors.errorSoft,
    ),
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
    scaffoldBackgroundColor: TColors.dark,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    textButtonTheme: TTextButtonTheme.darkTextButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    dividerTheme: const DividerThemeData(
      color: TColors.darkBorder,
      thickness: TSizes.dividerHeight,
      space: TSizes.dividerHeight,
    ),
    colorScheme: const ColorScheme.dark(
      primary: TColors.primary,
      onPrimary: TColors.white,
      primaryContainer: TColors.darkAccent,
      onPrimaryContainer: TColors.light,
      secondary: TColors.secondary,
      onSecondary: TColors.white,
      surface: TColors.darkSurface,
      onSurface: TColors.light,
      surfaceContainerHighest: TColors.darkSurface,
      outline: TColors.darkBorder,
      outlineVariant: TColors.darkBorder,
      error: TColors.error,
      onError: TColors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: TColors.primary,
      selectionHandleColor: TColors.primary,
      selectionColor: Color(0x334A57E8),
    ),
  );
}
