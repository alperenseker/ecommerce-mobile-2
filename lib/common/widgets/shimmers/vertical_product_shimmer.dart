/// Dikey ürün kartı ızgarası için yükleme parıltısı.
///
/// Ölçüler [TProductCardVertical] ile aynı olmalı; yoksa kartlar gelince
/// ızgara zıplıyor. Yükseklik [TGridLayout] varsayılanıyla (300) hizalı.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';
import '../layouts/grid_layout.dart';
import 'shimmer.dart';

class TVerticalProductShimmer extends StatelessWidget {
  const TVerticalProductShimmer({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return TGridLayout(
      itemCount: itemCount,
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Görsel
          TShimmerEffect(width: double.infinity, height: 148),
          SizedBox(height: TSizes.spaceBtwItems / 2),

          /// Başlık
          TShimmerEffect(width: double.infinity, height: 12),
          SizedBox(height: TSizes.xs),
          TShimmerEffect(width: 110, height: 12),
          SizedBox(height: TSizes.sm),

          /// Fiyat
          TShimmerEffect(width: 80, height: 16),
          Spacer(),

          /// Sepete ekle düğmesi
          TShimmerEffect(width: double.infinity, height: 32),
        ],
      ),
    );
  }
}
