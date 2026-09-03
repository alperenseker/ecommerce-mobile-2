/// Ürün kartındaki küçük puan satırı.
///
/// Değerlendirmesi olmayan üründe hiç çizilmez: web kartı da böyle
/// (`product-card.js` → `ratingHtml`), sıfır yıldız satırı kartı uzatıyor ve
/// "kötü ürün" izlenimi veriyordu.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';

class TProductRatingText extends StatelessWidget {
  const TProductRatingText({
    super.key,
    required this.rating,
    this.reviewsCount = 0,
  });

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    if (reviewsCount <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Iconsax.star1, color: TColors.star, size: 12),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 2),
        Text(
          '($reviewsCount)',
          style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.darkGrey),
        ),
      ],
    );
  }
}
