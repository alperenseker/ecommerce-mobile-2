/// Sepet ekranı.
///
/// 🔴 Girişsiz kullanıcıya **boş sepet gösterilmez**: sepet sunucuda
/// kullanıcıya bağlı, misafirin sepeti "boş" değil YOKTUR. Bu yüzden misafire
/// "önce giriş yapın" kapısı ve giriş düğmesi çizilir.
///
/// 🔴 Sepet sunucuda ve web uygulamasıyla PAYLAŞILIYOR. Ekran açılırken ve
/// ödemeye geçmeden hemen önce sunucudan yeniden okunur; kullanıcı siparişi
/// webden tamamlamış olabilir ve sunucu sepeti o an tüketmiştir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/appbar_actions.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/settings_controller.dart';
import '../../controllers/product/cart_controller.dart';
import '../checkout/checkout.dart';
import 'widgets/cart_items.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.showBackArrow = false});

  /// Sepet bir alt gezinme sekmesidir (geri oku yok). Kendi sayfası olarak
  /// açıldığında (ör. sepet ikonundan) `true` geçilir.
  final bool showBackArrow;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Sepet sunucuda ve web ile PAYLAŞILIYOR; yereldeki kopya ekran açılırken
    // çoktan eskimiş olabilir — en önemlisi sipariş webden tamamlanmışsa
    // sunucu sepeti tüketmiştir. Yeniden oku ki kullanıcı artık satın
    // alamayacağı kalemleri görmesin.
    if (!AuthenticationRepository.instance.isGuestUser) {
      CartController.instance.refreshFromBackend();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthenticationRepository.instance;

    // Misafir kapısı: sepet controller'ına hiç dokunulmaz (sepet kullanıcıya
    // bağlı, misafirde kurulacak bir durum yok).
    if (authRepo.isGuestUser) {
      return Scaffold(
        appBar: TAppBar(
          title: Text(TTexts.cart.tr),
          showBackArrow: widget.showBackArrow,
          showActions: false,
          showSkipButton: false,
        ),
        body: TEmptyState.signInRequired(message: TTexts.cartLoginText.tr),
      );
    }

    final controller = CartController.instance;
    final settingsController = SettingsController.instance;

    return Scaffold(
      /// -- "Hepsini temizle" eylemli başlık.
      appBar: TAppBar(
        title: Text(TTexts.cart.tr),
        showBackArrow: widget.showBackArrow,
        showActions: true,
        showSkipButton: false,
        actions: [
          Obx(
            () => controller.cartItems.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: TTexts.clearAll.tr,
                    icon: const Icon(Iconsax.trash, color: TColors.primary),
                    onPressed: controller.clearCartDialog,
                  ),
          ),
          // Sepetin kendi ekranındayız: başlıkta ikinci bir sepet düğmesi yok.
          const TAppBarActions(showCart: false),
        ],
      ),

      body: Obx(() {
        if (controller.loading.value && controller.cartItems.isEmpty) {
          return const TDelayedLoader();
        }

        if (controller.cartItems.isEmpty) {
          return TEmptyState(
            icon: Iconsax.shopping_bag,
            title: TTexts.whoopCartEmpty.tr,
            message: TTexts.cartEmptyText.tr,
            actionText: TTexts.letsFillIt.tr,
            onAction: () => Get.offNamed(TRoutes.homeMenu),
          );
        }

        return const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: TCartItems(),
          ),
        );
      }),

      /// -- Alt özet: toplam tutar + kalem sayısı + ödemeye geç.
      bottomNavigationBar: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();

        final dark = THelperFunctions.isDarkMode(context);
        return Container(
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.white,
            // Ayrım gölgeyle değil çizgiyle veriliyor (TASARIM.md §5).
            border: Border(
              top: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary),
            ),
          ),
          // Kendi sayfası olarak açıldığında altında `NavigationBar` yok;
          // sistem çentiğini SafeArea karşılıyor.
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
                vertical: TSizes.defaultSpace / 1.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TProductPriceText(
                        price: controller.totalCartPrice.value.toStringAsFixed(2),
                        isLarge: true,
                      ),
                      Text(
                        '${controller.noOfCartItems.value} ${TTexts.items.tr}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: TSizes.buttonHeight,
                    child: ElevatedButton(
                      // Genel düğme temasında yatay dolgu yok; içerik boyutlu
                      // düğmede etiket sıkışıyor, dolguyu geri veriyoruz.
                      // 🔴 `minimumSize` de geçilmeli: tema en küçük genişliği
                      // SONSUZ veriyor (düğmeler sayfa boyunca gerilsin diye)
                      // ve `Row` çocuğuna sonsuz genişlik veremez — çizim
                      // anında "BoxConstraints forces an infinite width" ile
                      // patlar. Yükseklik zaten üstteki `SizedBox`tan geliyor.
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: TSizes.xl),
                        minimumSize: const Size(0, TSizes.buttonHeight),
                      ),
                      onPressed: () async {
                        // Sepet sunucuda ve web ile paylaşılıyor: ekran
                        // çizildiğinden beri oradaki bir siparişle tüketilmiş
                        // olabilir. Önce oku ki ödemeyi sunucuda artık olmayan
                        // bir sepetle açmayalım.
                        await controller.refreshFromBackend();
                        if (controller.cartItems.isEmpty) {
                          TLoaders.warningSnackBar(title: TTexts.emptyCart.tr, message: TTexts.cartMessage.tr);
                          return;
                        }
                        // Vergi/kargo ayarlarını tazele, ama başarısız bir
                        // istek ödemeye geçişi ASLA engellemesin.
                        try {
                          await settingsController.fetchSettingDetails();
                        } catch (_) {}
                        Get.to(() => const CheckoutScreen());
                      },
                      child: Text(TTexts.checkOut.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
