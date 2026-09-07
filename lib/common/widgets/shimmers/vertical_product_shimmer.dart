/// Dikey ürün kartı ızgarası için yükleme parıltısı.
///
/// Ölçüler ürün kartıyla aynı olmalı; yoksa kartlar gelince
/// ızgara zıplıyor.
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
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Görsel
          TShimmerEffect(width: double.infinity, height: TSizes.productCardImageHeight),
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
