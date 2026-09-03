import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// Bağlantı düğmesi. TASARIM.md §2 renk tablosu: bağlantılar indigo, w600
/// ("hepsini gör" bağlantıları dâhil). Karanlıkta da aynı indigo kalır.
class TTextButtonTheme {
  TTextButtonTheme._();

  static final lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: TColors.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );

  static final darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: TColors.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}
