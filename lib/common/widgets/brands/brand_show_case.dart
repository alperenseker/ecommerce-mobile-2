/// Marka vitrini: marka kartı + o markanın ilk 3 ürün görseli.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/shop/models/brand_model.dart';
import '../../../features/shop/screens/brand/brand.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/rounded_container.dart';
import '../shimmers/shimmer.dart';
import 'brand_card.dart';

/// A widget showcasing a brand with its top 3 product images.
class TBrandShowcase extends StatelessWidget {
  /// Default constructor for the TBrandShowcase.
  ///
  /// Parameters:
  ///   - brand: The brand model to display.
  ///   - images: The list of top 3 product images for the brand.
  const TBrandShowcase({super.key, required this.brand, required this.images});

  final BrandModel brand;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: () => Get.to(() => BrandScreen(brand: brand)),
      child: TRoundedContainer(
        margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
        showBorder: true,
        radius: TSizes.borderRadiusMd,
        borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
        backgroundColor: dark ? TColors.darkSurface : TColors.white,
        child: Column(
          children: [
            /// Marka + ürün sayısı
            TBrandCard(showBorder: false, brand: brand),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /// Markanın ilk 3 ürün görseli
            Row(children: images.map((e) => brandTopProductImageWidget(e, context)).toList()),
          ],
        ),
      ),
    );
  }

  /// Vitrindeki tek ürün görseli.
  Widget brandTopProductImageWidget(String image, BuildContext context) {
    return Expanded(
      child: TRoundedContainer(
        height: 100,
        radius: TSizes.borderRadiusSm,
        padding: const EdgeInsets.all(TSizes.md),
        margin: const EdgeInsets.only(right: TSizes.sm),
        backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.darkBorder : TColors.lightContainer,
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          imageUrl: image,
          progressIndicatorBuilder: (context, url, downloadProgress) => const TShimmerEffect(width: 100, height: 100),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
