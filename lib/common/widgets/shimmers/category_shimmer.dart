/// Yatay kategori şeridi için yükleme parıltısı.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';
import 'shimmer.dart';

class TCategoryShimmer extends StatelessWidget {
  const TCategoryShimmer({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, _) => const SizedBox(width: TSizes.spaceBtwItems),
        itemBuilder: (_, _) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Görsel
              TShimmerEffect(width: 55, height: 55, radius: 55),
              SizedBox(height: TSizes.spaceBtwItems / 2),

              /// Metin
              TShimmerEffect(width: 55, height: 8),
            ],
          );
        },
      ),
    );
  }
}
