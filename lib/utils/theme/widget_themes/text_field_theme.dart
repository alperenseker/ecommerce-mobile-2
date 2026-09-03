import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Form alanı (TASARIM.md §6): 48px yükseklik, 8px köşe, `borderPrimary`
/// çerçeve; odakta indigo çerçeve.
///
/// Yükseklik `constraints` ile değil dolguyla veriliyor: referansta
/// `BoxConstraints.expand` denenmiş ve hata metni ile ön/son ikonlar taşdığı
/// için yorumda bırakılmıştı. 14 dikey dolgu + 20 satır yüksekliği ≈ 48px.
class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    filled: true,
    fillColor: TColors.white,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,
    contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 14),
    labelStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.textSecondary, fontFamily: 'Poppins'),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error, fontFamily: 'Poppins'),
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.primary, fontFamily: 'Poppins'),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.borderPrimary),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.borderPrimary),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1.5, color: TColors.primary),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1.5, color: TColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    filled: true,
    fillColor: TColors.darkSurface,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,
    contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 14),
    labelStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error, fontFamily: 'Poppins'),
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.primary, fontFamily: 'Poppins'),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.darkBorder),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.darkBorder),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1.5, color: TColors.primary),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1.5, color: TColors.error),
    ),
  );
}
