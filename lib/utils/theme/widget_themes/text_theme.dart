import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Aydınlık ve karanlık metin ölçeği (TASARIM.md §4).
///
/// Başlıklar sıkı harf aralıklı (-0.2) ve **büyük harf değil**; etiketler w600,
/// gövde w400. Ölçek referanstakinden bir tık küçüktür (gövde 14 → 13), çünkü
/// yeni tasarım aynı ekrana daha fazla bilgi sığdırıyor.
class TTextTheme {
  TTextTheme._();

  /// Aydınlık tema metinleri
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),
    headlineMedium: const TextStyle().copyWith(fontSize: 22.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),
    headlineSmall: const TextStyle().copyWith(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),

    titleLarge: const TextStyle().copyWith(fontSize: 16.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),
    titleMedium: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w600, color: TColors.textPrimary),
    titleSmall: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.textPrimary),

    bodyLarge: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.textPrimary),
    bodyMedium: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.w400, color: TColors.textPrimary),
    bodySmall: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w400, color: TColors.textSecondary),

    labelLarge: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w600, color: TColors.textPrimary),
    labelMedium: const TextStyle().copyWith(fontSize: 11.0, fontWeight: FontWeight.w500, color: TColors.textSecondary),
  );

  /// Karanlık tema metinleri (TASARIM.md §8: metin #F5F6F8, ikincil #9AA1AE)
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),
    headlineMedium: const TextStyle().copyWith(fontSize: 22.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),
    headlineSmall: const TextStyle().copyWith(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),

    titleLarge: const TextStyle().copyWith(fontSize: 16.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),
    titleMedium: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w600, color: TColors.light),
    titleSmall: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.light),

    bodyLarge: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.light),
    bodyMedium: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.w400, color: TColors.light),
    bodySmall: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w400, color: TColors.darkGrey),

    labelLarge: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w600, color: TColors.light),
    labelMedium: const TextStyle().copyWith(fontSize: 11.0, fontWeight: FontWeight.w500, color: TColors.darkGrey),
  );
}
