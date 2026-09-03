import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Başlık çubuğu (TASARIM.md §6).
///
/// Beyaz zemin, **gölgesiz**, altında 1px çizgi. Referansta zemin saydamdı ve
/// bazı ekranlarda koyu kavisli bir başlık çiziliyordu; yeni tasarımda başlık
/// her yerde aynı sade beyaz bant. Ayrım gölgeyle değil çizgiyle veriliyor.
class TAppBarTheme {
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: TColors.white,
    surfaceTintColor: Colors.transparent,
    shape: Border(bottom: BorderSide(color: TColors.borderSecondary, width: TSizes.dividerHeight)),
    iconTheme: IconThemeData(color: TColors.iconPrimaryLight, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(color: TColors.iconPrimaryLight, size: TSizes.iconMd),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary, fontFamily: 'Poppins'),
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: TColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: Border(bottom: BorderSide(color: TColors.darkBorder, width: TSizes.dividerHeight)),
    iconTheme: IconThemeData(color: TColors.iconPrimaryDark, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(color: TColors.iconPrimaryDark, size: TSizes.iconMd),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.white, fontFamily: 'Poppins'),
  );
}
