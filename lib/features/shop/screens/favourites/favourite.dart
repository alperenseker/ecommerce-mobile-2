/// Beğenilen ürünler (istek listesi) ekranı.
///
/// 🔴 Ekran alt gezinmeden kaldırıldı; kapısı artık **profil sekmesi**.
/// Bununla birlikte düzeni de değişti: eskiden iki sütunlu standart ürün
/// ızgarasıydı ve listeden bir ürünü çıkarmanın tek yolu kartın üstündeki
/// küçük kalbe nişan almaktı. Burada ürün ARANMIYOR, birikmiş liste
/// gözden geçiriliyor — o yüzden düzen **geniş satırlar**: solda görsel,
/// ortada ad ve fiyat, sağda "sepete ekle" ile "listeden çıkar". Bir
/// ekranda iki kat daha çok ürün görünüyor ve iki eylem de parmak boyutunda.
///
/// 🔴 Liste sunucuda kullanıcıya bağlı; misafire boş liste değil "önce giriş
/// yapın" kapısı gösterilir.
///
/// Karttaki kalp ile bu liste aynı kaynaktan (`FavouriteController.favorites`)
/// besleniyor, bu yüzden kendiliğinden senkron.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/appbar_actions.dart';
import '../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/products/product_cards/widgets/product_stock_badge.dart';
import '../../../../common/widgets/shimmers/shimmer.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/favourites_controller.dart';
import '../../controllers/product/product_controller.dart';
import '../../models/product_model.dart';
import '../product_detail/product_detail.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthenticationRepository.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        showBackArrow: true,
        showActions: true,
        showSkipButton: false,
        title: Text(TTexts.likedProducts.tr),
        actions: const [TAppBarActions()],
      ),
      body: authRepo.isGuestUser
          ? TEmptyState.signInRequired(message: TTexts.wishlistLoginText.tr)
          : const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final controller = FavouriteController.instance;

    return Obx(() {
      // `favorites` okunuyor: kalp değişince liste yeniden kurulsun.
      final favouriteCount = controller.favorites.length;

      return FutureBuilder<List<ProductModel>>(
        // ignore: discarded_futures
        future: controller.favoriteProducts(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && favouriteCount > 0) {
            return const _RowShimmer();
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return TEmptyState(
              icon: Iconsax.heart,
              title: TTexts.wishlistEmpty.tr,
              message: TTexts.wishlistEmptyText.tr,
              actionText: TTexts.letsAddSome.tr,
              onAction: () => Get.offAllNamed(TRoutes.homeMenu),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              TSizes.defaultSpace,
              TSizes.md,
              TSizes.defaultSpace,
              TSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
            ),
            // İlk satır özet + "hepsini sepete at" şeridi.
            itemCount: products.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: TSizes.sm),
            itemBuilder: (_, index) => index == 0
                ? _Header(products: products)
                : _FavouriteRow(product: products[index - 1]),
          );
        },
      );
    });
  }
}

/// Üstteki özet şeridi: kaç ürün + stokta olanların hepsini sepete at.
///
/// İstekler sırayla gider (bkz. [FavouriteController.addAllToCart]); işlem
/// sürerken düğme kilitlenir, yoksa kullanıcı arka arkaya basıp aynı ürünleri
/// birden çok kez ekliyor.
class _Header extends StatelessWidget {
  const _Header({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final controller = FavouriteController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        // Yumuşak indigo panel: listenin ne olduğunu söyleyen tek yer.
        color: dark ? TColors.darkAccent : TColors.accent,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.heart5, color: TColors.primary, size: TSizes.iconMd),
          const SizedBox(width: TSizes.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${products.length} ${TTexts.products.tr}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  TTexts.likedProductsSubTitle.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Obx(
            () => SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed:
                    controller.isBulkAdding.value ? null : () => controller.addAllToCart(products),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: controller.isBulkAdding.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: TColors.white),
                      )
                    : const Icon(Iconsax.shopping_bag, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek beğenilen ürün: görsel · ad + fiyat + stok · sepete ekle / listeden çıkar.
class _FavouriteRow extends StatelessWidget {
  const _FavouriteRow({required this.product});

  final ProductModel product;

  /// Kare görsel altlığı.
  static const double _imageSize = 92.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context).textTheme;
    final orderable = TProductStock.resolve(product).canOrder;

    return Material(
      color: dark ? TColors.darkSurface : TColors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(product: product)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
          padding: const EdgeInsets.all(TSizes.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -- Görsel
              Container(
                width: _imageSize,
                height: _imageSize,
                padding: const EdgeInsets.all(TSizes.xs),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkBorder : TColors.lightContainer,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: TRoundedImage(
                  imageUrl: product.thumbnail,
                  isNetworkImage: true,
                  applyImageRadius: true,
                  memCacheWidth: (_imageSize * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
              ),
              const SizedBox(width: TSizes.sm + 2),

              /// -- Ad · fiyat · stok
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelMedium,
                      ),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyLarge,
                    ),
                    const SizedBox(height: TSizes.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.isPriceHidden
                                ? TTexts.priceOnRequest.tr
                                : '₸${ProductController.instance.getProductPrice(product)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: product.isPriceHidden
                                ? theme.bodySmall
                                : theme.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: TSizes.sm),
                        ProductStockBadge(product: product, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TSizes.xs),

              /// -- Eylemler: listeden çıkar (üstte) · sepete ekle (altta)
              Column(
                children: [
                  _ActionButton(
                    icon: Iconsax.heart5,
                    color: TColors.deal,
                    background: dark ? TColors.darkSurface : TColors.dealSoft,
                    tooltip: TTexts.remove.tr,
                    onTap: () => FavouriteController.instance
                        .toggleFavoriteProduct(product.id, product),
                  ),
                  const SizedBox(height: TSizes.xs + 2),
                  _ActionButton(
                    icon: Iconsax.shopping_bag,
                    color: orderable ? TColors.primary : TColors.darkGrey,
                    background: orderable
                        ? (dark ? TColors.darkAccent : TColors.accent)
                        : (dark ? TColors.darkSurface : TColors.softGrey),
                    tooltip: (orderable ? TTexts.addToBag : TTexts.outOfStock).tr,
                    onTap: orderable
                        ? () {
                            final cart = CartController.instance;
                            cart.addOneToCart(cart.convertToCartItem(product, 1));
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satırın sağındaki yuvarlak eylem düğmesi.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: color)),
        ),
      ),
    );
  }
}

/// Liste yüklenirken görünen iskelet — gerçek satırlarla aynı ölçüde.
class _RowShimmer extends StatelessWidget {
  const _RowShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: TSizes.sm),
      itemBuilder: (_, _) => const TShimmerEffect(
        width: double.infinity,
        height: 110,
        radius: TSizes.cardRadiusLg,
      ),
    );
  }
}
