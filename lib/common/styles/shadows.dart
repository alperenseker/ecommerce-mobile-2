import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';

/// Gölge tanımları (TASARIM.md §5).
///
/// Sayfa akışında gölge YOKTUR; ayrım 1px `TColors.borderSecondary` çizgiyle
/// verilir. Buradaki gölgeler yalnız akışın üstüne çıkan katmanlar içindir.
class TShadowStyle {
  /// Basıldığında hafifçe yükselen kart/ürün kutusu.
  static final verticalProductShadow = BoxShadow(
    color: TColors.black.withValues(alpha: 0.07),
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );

  /// Yatay listelerdeki kart da aynı yüksekliği kullanır; iki ayrı ad
  /// referanstan geliyor, kullanım yerleri bozulmasın diye korundu.
  static final horizontalProductShadow = BoxShadow(
    color: TColors.black.withValues(alpha: 0.07),
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );

  /// Diyalog, sayfa altı sayfası gibi ekranın üstünde duran katmanlar.
  static final overlayShadow = BoxShadow(
    color: TColors.black.withValues(alpha: 0.14),
    blurRadius: 30,
    offset: const Offset(0, 10),
  );
}
