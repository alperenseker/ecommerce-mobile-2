import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Başlık çubuğu teması.
///
/// TASARIM.md §6: **beyaz zemin, gölgesiz**, başlık `w700` 18px.
/// Altındaki 1px çizgi burada verilemiyor (AppBarTheme'in böyle bir alanı yok);
/// onu `common/widgets/appbar/appbar.dart` çiziyor — bu yüzden `elevation` ve
/// `scrolledUnderElevation` sıfır bırakıldı, yoksa kaydırınca gölge belirirdi.
class TAppBarTheme {
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: TColors.white,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.iconPrimaryLight, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(color: TColors.iconPrimaryLight, size: TSizes.iconMd),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary, fontFamily: 'Poppins'),
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: TColors.dark,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.iconPrimaryDark, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(color: TColors.iconPrimaryDark, size: TSizes.iconMd),
    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light, fontFamily: 'Poppins'),
  );
}
