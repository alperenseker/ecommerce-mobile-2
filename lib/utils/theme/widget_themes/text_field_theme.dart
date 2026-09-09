import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Form alanı teması.
///
/// TASARIM.md §6: 48px yükseklik, 8px köşe, `borderPrimary` çerçeve, odakta
/// **indigo** çerçeve. Referansta odak rengi siyahtı ve hata rengi `warning`
/// kullanılıyordu; ikisi de düzeltildi — hata `error`, odak `primary`.
///
/// Yükseklik `constraints` ile veriliyor (referansta bu satır yorumdaydı);
/// `contentPadding` olmadan `constraints` tek başına metni ortalamıyor, ikisi
/// birlikte 48px'i tutturuyor.
class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    filled: true,
    fillColor: TColors.white,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,
    constraints: const BoxConstraints(minHeight: TSizes.inputFieldHeight),
    contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + TSizes.xs),
    labelStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.textSecondary, fontFamily: 'Poppins'),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error, fontFamily: 'Poppins'),
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.textSecondary, fontFamily: 'Poppins'),
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
    constraints: const BoxConstraints(minHeight: TSizes.inputFieldHeight),
    contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + TSizes.xs),
    labelStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.darkGrey, fontFamily: 'Poppins'),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error, fontFamily: 'Poppins'),
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.darkGrey, fontFamily: 'Poppins'),
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
