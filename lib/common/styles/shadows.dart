import 'package:flutter/material.dart';

/// Gölge tanımları.
///
/// TASARIM.md §5: **sayfa akışında gölge yok** — kart/bölüm ayrımı 1px
/// `borderSecondary` çizgiyle veriliyor. Gölge yalnız gerçekten üste çıkan
/// katmanların hakkı (basılı kart, açılır katman). Referanstaki 50px bulanık,
/// 7px yayılan gölge bu yüzden çok daha kısıldı.
class TShadowStyle {
  static final verticalProductShadow = BoxShadow(
    color: const Color(0xFF14161B).withValues(alpha: 0.07),
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );

  static final horizontalProductShadow = BoxShadow(
    color: const Color(0xFF14161B).withValues(alpha: 0.07),
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );

  /// Sayfanın üstünde **yüzen** alt gezinme çubuğu için.
  ///
  /// Çubuk artık ekranın dibine yapışık değil, kenarlardan boşluklu duruyor;
  /// altındaki içerikten ayrılması için tek başına 1px çizgi yetmiyor. Gölge
  /// yine kısık (TASARIM.md §5): yayılma yok, bulanıklık az.
  static final floatingBarShadow = BoxShadow(
    color: const Color(0xFF14161B).withValues(alpha: 0.10),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  /// Sayfanın üstüne binen katmanlar (açılır levha, kayan çubuk) için.
  static final overlayShadow = BoxShadow(
    color: const Color(0xFF14161B).withValues(alpha: 0.14),
    blurRadius: 30,
    spreadRadius: 0,
    offset: const Offset(0, 10),
  );
}
