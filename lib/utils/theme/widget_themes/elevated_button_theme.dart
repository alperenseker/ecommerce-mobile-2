import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Birincil (dolu) düğme teması.
///
/// TASARIM.md §6: dolu indigo, 8px köşe, **44px yükseklik**, gölgesiz,
/// büyük harf değil. Referans burada `padding: vertical: TSizes.buttonHeight`
/// kullanıyordu (o zaman değer 12'ydi); TASARIM buttonHeight'ı gerçek yükseklik
/// yaptığı için yükseklik artık `minimumSize` ile veriliyor — aynı satır
/// padding olarak bırakılsaydı düğme 100px'e çıkardı.
class TElevatedButtonTheme {
  TElevatedButtonTheme._(); // Örnek oluşturulmasını engeller

  /* -- Açık tema -- */
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.buttonPrimary,
      disabledForegroundColor: TColors.darkGrey,
      disabledBackgroundColor: TColors.buttonDisabled,
      side: const BorderSide(color: TColors.buttonPrimary),
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonVerticalPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textWhite, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );

  /* -- Karanlık tema -- */
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.buttonPrimary,
      disabledForegroundColor: TColors.darkGrey,
      disabledBackgroundColor: TColors.darkerGrey,
      side: const BorderSide(color: TColors.buttonPrimary),
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonVerticalPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      textStyle: const TextStyle(fontSize: 15, color: TColors.textWhite, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}
