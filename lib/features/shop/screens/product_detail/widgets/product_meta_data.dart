/// Ürün künyesi: ad · ürün kodu · stok hapı · puan · fiyat kutusu.
///
/// TASARIM.md §6 ve web `pages/product.js` → `priceBoxHtml`:
///   * fiyat `w800`, `textPrimary` (renkli değil),
///   * indirim varsa eski fiyat üstü çizili + mercan (`deal`) yüzde rozeti,
///   * 🔴 fiyat gizliyse rakam yerine "fiyat için sorunuz" — `Price: 0` gelen
///     ürünlerde "₸0" yazmak müşteriyi yanıltıyordu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../common/widgets/products/product_cards/widgets/product_stock_badge.dart';
import '../../../../../common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/product_controller.dart';
import '../../../models/product_model.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- Ad
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(height: 1.3),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// -- Ürün kodu · stok hapı
        Wrap(
          spacing: TSizes.sm,
          runSpacing: TSizes.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if ((product.sku ?? '').isNotEmpty)
              Text(
                '${TTexts.sku.tr}: ${product.sku}',
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
              ),
            ProductStockBadge(product: product),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 1.5),

        /// -- Puan + yorum sayısı. Yorumu olmayan üründe sıfır yıldız satırı
        ///    çizilmez (kart ile aynı kural, bkz. `TProductRatingText`).
        if ((product.reviewsCount ?? 0) > 0)
          Row(
            children: [
              const Icon(Iconsax.star1, color: TColors.star, size: TSizes.iconSm),
              const SizedBox(width: TSizes.xs),
              Text(
                (product.rating ?? 0).toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyLarge!.apply(fontWeightDelta: 2),
              ),
              const SizedBox(width: TSizes.xs),
              Text(
                '(${product.reviewsCount} ${TTexts.reviews.tr})',
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
              ),
            ],
          ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// -- Fiyat kutusu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: darkMode ? TColors.darkSurface : TColors.lightGrey,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            border: Border.all(color: darkMode ? TColors.darkBorder : TColors.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: TSizes.sm,
                runSpacing: TSizes.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Ödenecek fiyat (fiyat gizliyse "fiyat için sorunuz").
                  TProductPriceText(
                    price: controller.getProductPrice(product),
                    isLarge: true,
                    priceHidden: product.isPriceHidden,
                  ),

                  // Eski fiyat + indirim rozeti — yalnız gerçek indirimde.
                  if (product.hasDiscount) ...[
                    Text(
                      '₸${product.oldPrice}',
                      style: Theme.of(context).textTheme.titleMedium!.apply(
                            decoration: TextDecoration.lineThrough,
                            color: TColors.darkGrey,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm,
                        vertical: TSizes.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.deal,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium!
                            .apply(color: TColors.white, fontWeightDelta: 2),
                      ),
                    ),
                  ],
                ],
              ),

              /// KDV oranı — sunucu metin gönderiyor ("18"), boşsa satır yok.
              if (!product.isPriceHidden && (product.vatRate ?? '').isNotEmpty) ...[
                const SizedBox(height: TSizes.xs),
                Text(
                  '${TTexts.vat.tr} ${product.vatRate}%',
                  style: Theme.of(context).textTheme.bodySmall!.apply(color: TColors.darkGrey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// -- Marka (sunucu bugün marka göndermiyor; gelirse çizilir)
        if (product.brand != null)
          Row(
            children: [
              TCircularImage(
                width: 32,
                height: 32,
                isNetworkImage: true,
                image: product.brand!.imageURL,
                overlayColor: darkMode ? TColors.white : TColors.black,
              ),
              TBrandTitleWithVerifiedIcon(
                title: product.brand!.name,
                brandTextSize: TextSizes.medium,
              ),
            ],
          ),
      ],
    );
  }
}
