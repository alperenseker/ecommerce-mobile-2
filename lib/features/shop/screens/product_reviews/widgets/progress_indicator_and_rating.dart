/// Değerlendirme özeti: solda büyük ortalama, sağda 5→1 dağılım çubukları.
///
/// 🔴 Ortalama ve dağılım **sunucunun `Summary` alanından** gelir; gelen
/// sayfadaki 20 yorumdan hesaplanan ortalama, 300 yorumlu bir üründe yanlış
/// olurdu. Özet gelmezse `ReviewController.distributionOf` sayfadan hesaplar.
///
/// Referanstaki sürüm sabit değerler (4.8 / 1.0 / 0.8 …) basıyordu; burada
/// gerçek veriyle çalışıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/repositories/reviews/reviews_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import 'rating_progress_indicator.dart';
import 'rating_star.dart';

class TOverallProductRating extends StatelessWidget {
  const TOverallProductRating({super.key, required this.summary});

  final ReviewSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalReviews;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w800),
              ),
              TRatingBarIndicator(rating: summary.averageRating, itemSize: 14),
              const SizedBox(height: TSizes.xs),
              Text(
                '$total ${TTexts.reviews.tr}',
                style: Theme.of(context).textTheme.bodySmall!.apply(color: TColors.darkGrey),
              ),
            ],
          ),
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          flex: 7,
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = summary.ratingDistribution[star] ?? 0;
              return TRatingProgressIndicator(
                text: '$star',
                // Sıfır yorumda 0/0 yerine boş çubuk.
                value: total == 0 ? 0 : count / total,
                count: count,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
