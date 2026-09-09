import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Açık ve karanlık tema yazı ölçekleri.
///
/// Ölçüler `faz/TASARIM.md` §4'ten gelir. Referanstan iki fark var:
/// başlıklar biraz küçüldü (28/22/18) ve **sıkı harf aralığı** (-0.2) aldı;
/// büyük harfe çevirme yok — büyük harf yığını ekranı eskitiyordu.
class TTextTheme {
  TTextTheme._(); // Örnek oluşturulmasını engeller

  /// Açık tema yazı ölçeği
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),
    headlineMedium: const TextStyle().copyWith(fontSize: 22.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),
    headlineSmall: const TextStyle().copyWith(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.textPrimary),

    titleLarge: const TextStyle().copyWith(fontSize: 16.0, fontWeight: FontWeight.w700, color: TColors.textPrimary),
    titleMedium: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w600, color: TColors.textPrimary),
    titleSmall: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w400, color: TColors.textPrimary),

    bodyLarge: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.textPrimary),
    bodyMedium: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.normal, color: TColors.textPrimary),
    bodySmall: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.w500, color: TColors.textSecondary),

    labelLarge: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w600, color: TColors.textPrimary),
    labelMedium: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.normal, color: TColors.textSecondary),
  );

  /// Karanlık tema yazı ölçeği (TASARIM.md §8 metin renkleri)
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),
    headlineMedium: const TextStyle().copyWith(fontSize: 22.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),
    headlineSmall: const TextStyle().copyWith(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TColors.light),

    titleLarge: const TextStyle().copyWith(fontSize: 16.0, fontWeight: FontWeight.w700, color: TColors.light),
    titleMedium: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w600, color: TColors.light),
    titleSmall: const TextStyle().copyWith(fontSize: 15.0, fontWeight: FontWeight.w400, color: TColors.light),

    bodyLarge: const TextStyle().copyWith(fontSize: 14.0, fontWeight: FontWeight.w500, color: TColors.light),
    bodyMedium: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.normal, color: TColors.light),
    bodySmall: const TextStyle().copyWith(fontSize: 13.0, fontWeight: FontWeight.w500, color: TColors.darkGrey),

    labelLarge: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.w600, color: TColors.light),
    labelMedium: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.normal, color: TColors.darkGrey),
  );
}
