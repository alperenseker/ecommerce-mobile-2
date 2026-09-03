/// Değerlendirme kartı için yükleme parıltısı.
///
/// Referansta her parça ayrı `Shimmer.fromColors` çağrısıydı ve renkler
/// gömülüydü; burada tek kaynak [TShimmerEffect] kullanılıyor (TASARIM.md §6).
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';
import 'shimmer.dart';

class TReviewCardShimmer extends StatelessWidget {
  const TReviewCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: TShimmerEffect(width: 40, height: 40, radius: 40),
          title: TShimmerEffect(width: 100, height: 15),
          trailing: SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                TShimmerEffect(width: 60, height: 15),
                SizedBox(height: TSizes.xs),
                TShimmerEffect(width: 70, height: 15),
              ],
            ),
          ),
        ),
        SizedBox(height: TSizes.sm),
        TShimmerEffect(width: double.infinity, height: 60),
        SizedBox(height: TSizes.sm),
        TShimmerEffect(width: 200, height: 20),
      ],
    );
  }
}
