/// Yatay ürün kartı — yatay kaydırılan raflarda (alt kategoriler, benzer
/// ürünler) kullanılır.
///
/// Görünüm dikey kartla aynı dili konuşur (TASARIM.md §6): beyaz, 12px köşe,
/// 1px çerçeve, gölgesiz; görsel açık gri altlıkta.
///
/// Karta dokunmak ürün detayını açar (FAZ 05'te bağlandı).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/shop/controllers/product/product_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../features/shop/screens/product_detail/product_detail.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../images/t_rounded_image.dart';
import '../../texts/t_brand_title_text_with_verified_icon.dart';
import '../../texts/t_product_title_text.dart';
import '../favourite_icon/favourite_icon.dart';
import '../ratings/t_product_rating_text.dart';
import 'widgets/add_to_cart_button.dart';
import 'widgets/product_card_pricing_widget.dart';
import 'widgets/product_sale_tag.dart';
import 'widgets/product_stock_badge.dart';

class TProductCardHorizontal extends StatelessWidget {
  const TProductCardHorizontal({super.key, required this.product, this.isNetworkImage = true});

  final ProductModel product;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    final salePercentage =
        ProductController.instance.calculateSalePercentage(product.price, product.oldPrice);
    final dark = THelperFunctions.isDarkMode(context);
    final thumbCacheWidth = (120 * MediaQuery.of(context).devicePixelRatio).round();

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        width: 310,
        height: TSizes.productCardHorizontalHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? TColors.darkSurface : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Görsel
            SizedBox(
              width: 120,
              height: double.infinity,
              child: Container(
                color: dark ? TColors.darkBorder : TColors.lightContainer,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(TSizes.sm),
                      child: Center(
                        child: TRoundedImage(
                          imageUrl: product.thumbnail,
                          isNetworkImage: isNetworkImage,
                          memCacheWidth: thumbCacheWidth,
                        ),
                      ),
                    ),
                    if (salePercentage != null) ProductSaleTagWidget(salePercentage: salePercentage),
                    Positioned(
                      top: TSizes.xs,
                      right: TSizes.xs,
                      child: TFavouriteIcon(productId: product.id, productModel: product),
                    ),
                  ],
                ),
              ),
            ),

            /// -- Ayrıntılar, fiyat, sepete ekle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      TBrandTitleWithVerifiedIcon(
                        title: product.brand!.name,
                        brandTextSize: TextSizes.small,
                        textAlign: TextAlign.left,
                      ),
                    TProductTitleText(title: product.title, smallSize: true, maxLines: 2),
                    const SizedBox(height: TSizes.xs),
                    TProductRatingText(rating: product.rating ?? 0, reviewsCount: product.reviewsCount ?? 0),
                    const Spacer(),
                    // Dikey karttaki ile aynı gerekçe: eşit bölüşen iki
                    // `Flexible` yerine doğal genişlik + gerekirse alt satır.
                    Wrap(
                      spacing: TSizes.xs,
                      runSpacing: TSizes.xs / 2,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        PricingWidget(product: product),
                        ProductStockBadge(product: product, compact: true),
                      ],
                    ),
                    const SizedBox(height: TSizes.xs),
                    ProductCardAddToCartButton(product: product, compact: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
