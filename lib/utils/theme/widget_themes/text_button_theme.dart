import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// Yazı düğmesi teması.
///
/// TASARIM.md §6'da "hepsini gör" bağlantısı indigo ve `w600`; yazı düğmesi
/// uygulamadaki bağlantıların ortak biçimi olduğu için renk `primary` yapıldı
/// (referansta siyahtı, bağlantı olduğu anlaşılmıyordu).
class TTextButtonTheme {
  TTextButtonTheme._(); // Örnek oluşturulmasını engeller

  /* -- Açık tema -- */
  static final lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: TColors.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );

  /* -- Karanlık tema -- */
  static final darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: TColors.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}
