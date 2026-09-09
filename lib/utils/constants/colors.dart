import 'package:flutter/material.dart';

/// Uygulamanın tek renk kaynağı.
///
/// Değerler `faz/TASARIM.md` §2'den gelir; oradaki palet de web projesindeki
/// `assets/css/01-tokens.css` belirteçlerinin Flutter karşılığıdır. Sınıf ve
/// alan adları referans uygulamayla **birebir aynı** tutuldu: 339 dosya bu
/// adlarla renk okuyor, yalnız değerler indigo palete taşındı. Bu yüzden
/// buradaki hiçbir alan silinmez/yeniden adlandırılmaz — yalnız değer değişir.
///
/// Renk yalnızca anlam taşıdığı yerde kullanılır (eylem, uyarı, durum);
/// ayrımlar renk yerine 1px çizgi ile verilir.
class TColors {
  TColors._();

  // ---- MARKA / EYLEM (indigo) ----
  static const Color primary = Color(0xFF4A57E8);
  static const Color secondary = Color(0xFF3A45C4); // koyu indigo (basılı hâl)
  static const Color accent = Color(0xFFEEF0FE); // indigo yumuşak zemin

  // ---- METİN ----
  static const Color textPrimary = Color(0xFF14161B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textWhite = Colors.white;

  // ---- ZEMİN ----
  static const Color light = Color(0xFFF5F6F8); // sayfa zemini
  static const Color dark = Color(0xFF14161B);
  static const Color primaryBackground = Color(0xFFEEF0FE);

  // ---- KAP ZEMİNLERİ ----
  static const Color lightContainer = Color(0xFFF2F4F7);
  static Color darkContainer = TColors.white.withValues(alpha: 0.1);

  // ---- DÜĞME ----
  static const Color buttonPrimary = Color(0xFF4A57E8);
  static const Color buttonSecondary = Color(0xFF6B7280);
  static const Color buttonDisabled = Color(0xFFDDE1E8);

  // ---- ÇİZGİ ----
  static const Color borderPrimary = Color(0xFFD3D8E0);
  static const Color borderSecondary = Color(0xFFE5E8EE);

  // ---- DURUM ----
  static const Color error = Color(0xFFE03A3A);
  static const Color success = Color(0xFF12A277);
  static const Color warning = Color(0xFFB87503);
  static const Color info = Color(0xFF2C7BE5);

  // ---- NÖTRLER ----
  static const Color black = Color(0xFF14161B);
  static const Color darkerGrey = Color(0xFF3C4250);
  static const Color darkGrey = Color(0xFF9AA1AE);
  static const Color grey = Color(0xFFE5E8EE);
  static const Color softGrey = Color(0xFFF2F4F7);
  static const Color lightGrey = Color(0xFFF8F9FB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color iconPrimaryLight = Color(0xFF3C4250);
  static const Color disabledTextLight = Color(0xFFD3D8E0);
  static const Color iconPrimaryDark = Color(0xFFFFFFFF);

  // ---- YENİ: web paletinden gelen ek roller ----
  // Bu dört rol referansta yoktu; web'de anlam taşıyan renkleri karşılıyorlar.
  static const Color deal = Color(0xFFF04358); // indirim / sayaç balonu
  static const Color dealSoft = Color(0xFFFEECEF);
  static const Color star = Color(0xFFFFB020); // yıldız
  static const Color successSoft = Color(0xFFE5F7F1);
  static const Color warningSoft = Color(0xFFFFF5E2);
  static const Color errorSoft = Color(0xFFFDECEC);
  static const Color infoSoft = Color(0xFFEAF2FD);

  // ---- KARANLIK TEMA (TASARIM.md §8) ----
  // Karanlık temada `accent` yerine bu kullanılır: açık temadaki indigo yumuşak
  // zemin (#EEF0FE) koyu zeminde okunmuyor.
  static const Color darkSurface = Color(0xFF1E212A); // koyu kap
  static const Color darkBorder = Color(0xFF2A2E39); // koyu çizgi
  static const Color darkAccent = Color(0xFF232744); // koyu indigo yumuşak zemin
}
