/// Salt okunur yıldız göstergesi (yarım yıldızları da çizer).
library;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';

class TRatingBarIndicator extends StatelessWidget {
  const TRatingBarIndicator({super.key, required this.rating, this.itemSize = 20});

  final double rating;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemSize: itemSize,
      unratedColor: TColors.grey,
      // TASARIM.md §2: yıldız `star` rengi; indigo eylem rengi değil.
      itemBuilder: (_, _) => const Icon(Iconsax.star1, color: TColors.star),
    );
  }
}
