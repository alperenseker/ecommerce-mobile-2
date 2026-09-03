import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Birincil düğme (TASARIM.md §6).
///
/// Dolu indigo, 8px köşe, 44px yükseklik, **gölgesiz**, büyük harf yok.
/// Yükseklik dikey dolguyla değil `minimumSize` ile veriliyor: referansta
/// dolgu kullanıldığı için metin uzayınca düğme boyu kayıyordu.
class TElevatedButtonTheme {
  TElevatedButtonTheme._();

  /// Aydınlık tema
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.primary,
      disabledForegroundColor: TColors.darkGrey,
      disabledBackgroundColor: TColors.buttonDisabled,
      side: const BorderSide(color: TColors.primary),
      minimumSize: const Size(TSizes.buttonWidth, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textWhite, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );

  /// Karanlık tema — indigo aynı kalır (TASARIM.md §8)
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.primary,
      disabledForegroundColor: TColors.darkGrey,
      disabledBackgroundColor: TColors.darkerGrey,
      side: const BorderSide(color: TColors.primary),
      minimumSize: const Size(TSizes.buttonWidth, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textWhite, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}
