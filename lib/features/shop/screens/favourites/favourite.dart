/// Favoriler (istek listesi) ekranı.
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
import '../../../../common/widgets/appbar/profile_action_icon.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/device/device_utility.dart';
import '../../controllers/product/favourites_controller.dart';
import '../../models/product_model.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthenticationRepository.instance;

    return PopScope(
      canPop: false,
      // Geri tuşu bu sekmeden uygulamayı kapatmasın, ana menüye dönsün.
      onPopInvokedWithResult: (bool didPop, Object? result) async => await Get.offAllNamed(TRoutes.homeMenu),
      child: Scaffold(
        appBar: TAppBar(
          showActions: true,
          showSkipButton: false,
          title: Text(TTexts.wishlist.tr),
          actions: const [TProfileActionIcon()],
        ),
        body: authRepo.isGuestUser
            ? TEmptyState.signInRequired(message: TTexts.wishlistLoginText.tr)
            : const _FavouriteBody(),
      ),
    );
  }
}

class _FavouriteBody extends StatelessWidget {
  const _FavouriteBody();

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
          /// Yükleniyor — üstten hizalı shimmer ızgarası.
          if (snapshot.connectionState == ConnectionState.waiting && favouriteCount > 0) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(TSizes.defaultSpace),
              child: TVerticalProductShimmer(itemCount: 6),
            );
          }

          final products = snapshot.data ?? [];

          /// Boş durum.
          if (products.isEmpty) {
            return TEmptyState(
              icon: Iconsax.heart,
              title: TTexts.wishlistEmpty.tr,
              message: TTexts.wishlistEmptyText.tr,
              actionText: TTexts.letsAddSome.tr,
              onAction: () => Get.offAllNamed(TRoutes.homeMenu),
            );
          }

          /// Ürün ızgarası + "hepsini sepete at".
          return SingleChildScrollView(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulkAddBar(products: products),
                const SizedBox(height: TSizes.spaceBtwItems),
                TGridLayout(
                  itemCount: products.length,
                  itemBuilder: (_, index) => TProductCardVertical(product: products[index]),
                ),
                SizedBox(height: TDeviceUtils.getBottomNavigationBarHeight() + TSizes.defaultSpace),
              ],
            ),
          );
        },
      );
    });
  }
}

/// Ürün sayısı + "stokta olanların hepsini sepete at" satırı.
///
/// İstekler sırayla gider (bkz. [FavouriteController.addAllToCart]); işlem
/// sürerken düğme kilitlenir, yoksa kullanıcı arka arkaya basıp aynı ürünleri
/// birden çok kez ekliyor.
class _BulkAddBar extends StatelessWidget {
  const _BulkAddBar({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final controller = FavouriteController.instance;

    return Row(
      children: [
        Text(
          '${products.length} ${TTexts.products.tr}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        Obx(
          () => OutlinedButton(
            onPressed: controller.isBulkAdding.value ? null : () => controller.addAllToCart(products),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.isBulkAdding.value)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TColors.primary),
                  )
                else
                  const Icon(Iconsax.shopping_bag, size: 14),
                const SizedBox(width: TSizes.xs),
                Text(TTexts.addAllToCart.tr),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
