/// Puan + paylaş satırı.
///
/// Referansta ürün detayının en üstünde duruyordu; künye ([TProductMetaData])
/// artık puanı kendi içinde gösterdiği için ekranda çağrılmıyor. KURALLAR §4
/// gereği dosya silinmedi — sıfır yorumlu üründe hiç çizilmemesi tek fark
/// (kart ve künye ile aynı kural).
///
/// Paylaş düğmesi referansta da yorumdaydı: uygulama paylaşım paketi
/// taşımıyor (`pubspec.yaml` değişmez, KURALLAR §2).
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class TRatingAndShare extends StatelessWidget {
  const TRatingAndShare({super.key, required this.rating, required this.reviewCount});

  final String rating;
  final String reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Puan
        Row(
          children: [
            const Icon(Iconsax.star1, color: TColors.star, size: TSizes.iconMd),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: rating, style: Theme.of(context).textTheme.bodyLarge),
                  TextSpan(text: ' ($reviewCount)'),
                ],
              ),
            ),
          ],
        ),

        /// Paylaş düğmesi — bkz. dosya başlığı.
        // IconButton(onPressed: () {}, icon: const Icon(Icons.share, size: TSizes.iconMd))
      ],
    );
  }
}
