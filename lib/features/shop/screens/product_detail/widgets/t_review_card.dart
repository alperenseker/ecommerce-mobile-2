/// Tek bir yorum kartı: avatar · ad · tarih · yıldız · metin.
///
/// TASARIM.md §6: gölgesiz, 1px çizgiyle ayrılan kap; yıldız `star` rengi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../models/product_review_model.dart';
import '../../product_reviews/widgets/rating_star.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.reviewModel});

  final ReviewModel reviewModel;

  /// Profil görseli genelde boş geliyor; o zaman adın baş harfi kullanılır.
  Widget _buildAvatar() {
    final image = reviewModel.userProfileImage;
    if (image != null && image.isNotEmpty) {
      return CircleAvatar(foregroundImage: NetworkImage(image), backgroundColor: TColors.accent);
    }
    final name = reviewModel.userName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: TColors.accent,
      child: Text(initial, style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _buildAvatar(),
          title: Text(
            reviewModel.userName.isEmpty ? '—' : reviewModel.userName,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              TRatingBarIndicator(rating: reviewModel.rating, itemSize: 12),
              const SizedBox(width: TSizes.sm),
              Text(
                TFormatter.formatDate(reviewModel.createdAt),
                style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.darkGrey),
              ),
            ],
          ),
        ),
        if (reviewModel.title.isNotEmpty) ...[
          Text(
            reviewModel.title,
            style: Theme.of(context).textTheme.bodyLarge!.apply(fontWeightDelta: 2),
          ),
          const SizedBox(height: TSizes.xs),
        ],
        if (reviewModel.reviewText.isNotEmpty)
          ReadMoreText(
            reviewModel.reviewText,
            trimLines: 4,
            colorClickableText: TColors.primary,
            trimMode: TrimMode.Line,
            trimCollapsedText: TTexts.showMore.tr,
            trimExpandedText: TTexts.showLess.tr,
            style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkerGrey),
            moreStyle: const TextStyle(fontWeight: FontWeight.bold, color: TColors.primary),
            lessStyle: const TextStyle(fontWeight: FontWeight.bold, color: TColors.primary),
          ),
      ],
    );
  }
}
