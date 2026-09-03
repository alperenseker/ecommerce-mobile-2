/// Dikey ürün kartı — ızgaraların temel taşı.
///
/// TASARIM.md §6: beyaz, 12px köşe, 1px `borderSecondary` çerçeve, **gölgesiz**;
/// görsel açık gri (`lightContainer`) altlıkta 8px köşeyle; kalp/karşılaştır
/// sağ üstte yuvarlak beyaz düğme; stok **hap** rozet; fiyat `w800`;
/// "sepete ekle" sakin düğme.
///
/// Yükseklik [TSizes.productCardHeight] (300) ile hizalıdır; başlık kısa
/// olduğunda araya [Spacer] giriyor, böylece fiyat + düğme her kartta aynı
/// hizada duruyor.
///
/// 🔴 FAZ 05 — karta dokununca açılacak `ProductDetailScreen` henüz yok;
/// `// FAZ 05` satırı o fazda açılacak.
library;

import 'package:flutter/material.dart';

import '../../../../features/shop/controllers/product/product_controller.dart';
import '../../../../features/shop/models/product_model.dart';
// FAZ 05 — import '../../../../features/shop/screens/product_detail/product_detail.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../images/t_rounded_image.dart';
import '../../texts/t_brand_title_text_with_verified_icon.dart';
import '../../texts/t_product_title_text.dart';
import '../favourite_icon/compare_icon.dart';
import '../favourite_icon/favourite_icon.dart';
import '../ratings/t_product_rating_text.dart';
import 'widgets/add_to_cart_button.dart';
import 'widgets/product_card_pricing_widget.dart';
import 'widgets/product_sale_tag.dart';
import 'widgets/product_stock_badge.dart';

class TProductCardVertical extends StatelessWidget {
  const TProductCardVertical({super.key, required this.product, this.isNetworkImage = true});

  final ProductModel product;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    final salePercentage =
        ProductController.instance.calculateSalePercentage(product.price, product.salePrice);
    final dark = THelperFunctions.isDarkMode(context);
    // Küçük resmi ekranda kaplayacağı boyutta çöz (tam çözünürlükte değil);
    // yoksa bir ızgara dolusu büyük fotoğraf belleği bitiriyor ve cihaz ısınıyor.
    final thumbCacheWidth = (160 * MediaQuery.of(context).devicePixelRatio).round();

    return GestureDetector(
      // FAZ 05 — onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // TASARIM.md §5: sayfa akışında gölge yok, ayrım 1px çizgi.
          color: dark ? TColors.darkSurface : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Görsel altlığı
            Container(
              height: TSizes.productCardImageHeight,
              width: double.infinity,
              color: dark ? TColors.darkBorder : TColors.lightContainer,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(TSizes.sm),
                    child: Center(
                      child: TRoundedImage(
                        imageUrl: product.thumbnail,
                        applyImageRadius: true,
                        isNetworkImage: isNetworkImage,
                        memCacheWidth: thumbCacheWidth,
                      ),
                    ),
                  ),

                  /// İndirim rozeti
                  if (salePercentage != null) ProductSaleTagWidget(salePercentage: salePercentage),

                  /// Kalp + karşılaştır
                  Positioned(
                    top: TSizes.xs,
                    right: TSizes.xs,
                    child: Column(
                      children: [
                        TFavouriteIcon(productId: product.id, productModel: product),
                        const SizedBox(height: TSizes.xs),
                        TCompareIcon(productModel: product),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// -- Başlık bloğu
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.sm, TSizes.sm, TSizes.sm, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst satır: marka varsa marka, yoksa stok kodu (web kartı da
                  // aynı sırayı kullanıyor: `Sku` yoksa şirket etiketi).
                  if (product.brand != null)
                    TBrandTitleWithVerifiedIcon(
                      title: product.brand!.name,
                      brandTextSize: TextSizes.small,
                      textAlign: TextAlign.left,
                    )
                  else if ((product.sku ?? '').isNotEmpty)
                    Text(
                      product.sku!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  const SizedBox(height: 2),
                  TProductTitleText(title: product.title, smallSize: true),
                  const SizedBox(height: TSizes.xs),
                  TProductRatingText(rating: product.rating ?? 0, reviewsCount: product.reviewsCount ?? 0),
                ],
              ),
            ),

            // Fiyat + düğme satırını hücrenin dibine iter; böylece başlık ne
            // kadar uzun olursa olsun düğme her kartta aynı hizada durur.
            const Spacer(),

            /// -- Fiyat + stok hapı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: PricingWidget(product: product)),
                  const SizedBox(width: TSizes.xs),
                  Flexible(child: ProductStockBadge(product: product, compact: true)),
                ],
              ),
            ),
            const SizedBox(height: TSizes.sm),

            /// -- Sepete ekle
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.sm, 0, TSizes.sm, TSizes.sm),
              child: ProductCardAddToCartButton(product: product),
            ),
          ],
        ),
      ),
    );
  }
}
