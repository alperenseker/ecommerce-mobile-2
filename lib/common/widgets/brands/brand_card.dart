/// Marka satırı kartı: logo + ad + ürün sayısı.
///
/// TASARIM.md §6: beyaz zemin, 1px çerçeve, gölgesiz.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/shop/models/brand_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/rounded_container.dart';
import '../images/t_circular_image.dart';
import '../texts/t_brand_title_text_with_verified_icon.dart';

/// A card widget representing a brand.
class TBrandCard extends StatelessWidget {
  /// Default constructor for the TBrandCard.
  ///
  /// Parameters:
  ///   - brand: The brand model to display.
  ///   - showBorder: A flag indicating whether to show a border around the card.
  ///   - onTap: Callback function when the card is tapped.
  const TBrandCard({
    super.key,
    required this.brand,
    required this.showBorder,
    this.onTap,
  });

  final BrandModel brand;
  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: TRoundedContainer(
        showBorder: showBorder,
        radius: TSizes.borderRadiusMd,
        borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
        backgroundColor: dark ? TColors.darkSurface : TColors.white,
        padding: const EdgeInsets.all(TSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// -- Logo
            Flexible(
              child: TCircularImage(
                image: brand.imageURL,
                isNetworkImage: true,
                backgroundColor: dark ? TColors.darkSurface : TColors.lightContainer,
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems / 2),

            /// -- Metinler
            // [Expanded] + [MainAxisSize.min]: metin dikeyde ortalansın ve
            // kartın sınırları dışına taşmasın.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TBrandTitleWithVerifiedIcon(
                    title: brand.name,
                    brandTextSize: TextSizes.large,
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    '${brand.productsCount ?? 0} ${TTexts.products.tr}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
