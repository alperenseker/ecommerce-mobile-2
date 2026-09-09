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

import '../../../../common/styles/shadows.dart';
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
import '../../../../home_menu.dart';
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
  /// Sekme kipinde geri tuşu uygulamayı kapatmasın, ana sayfa sekmesine
  /// dönsün (mağaza ve profil sekmeleriyle aynı davranış). İtilerek açılan
  /// sepette (geri oklu) sistemin kendi geri davranışı korunur.
  Widget _wrapForTab(Widget child) {
    if (widget.showBackArrow) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppScreenController.instance.selectedMenu.value = 0;
      },
      child: child,
    );
  }

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
      return _wrapForTab(
        Scaffold(
          appBar: TAppBar(
            title: Text(TTexts.cart.tr),
            showBackArrow: widget.showBackArrow,
            showActions: false,
            showSkipButton: false,
          ),
          body: TEmptyState.signInRequired(message: TTexts.cartLoginText.tr),
        ),
      );
    }

    final controller = CartController.instance;
    final settingsController = SettingsController.instance;

    return _wrapForTab(
      Scaffold(
        /// -- "Hepsini temizle" eylemli başlık.
        appBar: TAppBar(
          title: Text(TTexts.cart.tr),
          showBackArrow: widget.showBackArrow,
          showActions: true,
          showSkipButton: false,
          actions: [
            Obx(
              () =>
                  controller.cartItems.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                        tooltip: TTexts.clearAll.tr,
                        icon: const Icon(Iconsax.trash, color: TColors.primary),
                        onPressed: controller.clearCartDialog,
                      ),
            ),
            const TAppBarActions(),
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
            child: Padding(padding: EdgeInsets.all(TSizes.defaultSpace), child: TCartItems()),
          );
        }),

        /// -- Alt özet: toplam tutar + kalem sayısı + ödemeye geç.
        ///
        /// 🔴 Şerit yeniden düzenlendi. Eskiden solda tutar, sağda içerik
        /// boyutlu bir düğme vardı: düğme ekranın sağ ucunda kalıyor, uzun
        /// çevirilerde ("Оформить заказ") tutarı sıkıştırıyordu. Artık tutar
        /// kendi satırında etiketiyle duruyor, düğme **tam genişlikte** ve
        /// başparmağın altında; şerit de üstteki listeden yuvarlak köşe ve
        /// kısık gölgeyle ayrılıyor (sayfanın üstüne çıkan katman).
        bottomNavigationBar: Obx(() {
          if (controller.cartItems.isEmpty) return const SizedBox.shrink();

          final dark = THelperFunctions.isDarkMode(context);
          final theme = Theme.of(context).textTheme;

          return Container(
            decoration: BoxDecoration(
              color: dark ? TColors.darkSurface : TColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
              border: Border(
                top: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary),
              ),
              boxShadow: [TShadowStyle.floatingBarShadow],
            ),
            // Kendi sayfası olarak açıldığında altında `NavigationBar` yok;
            // sistem çentiğini SafeArea karşılıyor. Sekme kipinde ise yüzen
            // çubuğun payını da SafeArea getiriyor.
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TSizes.defaultSpace,
                  TSizes.md,
                  TSizes.defaultSpace,
                  TSizes.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// -- Toplam satırı
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // Sözlükte "Toplam :" diye iki nokta üst üste ile
                            // duruyor; burada cümlenin ortasında olduğu için
                            // temizleniyor (karşılaştırma ekranıyla aynı yol).
                            '${TTexts.total.tr.replaceAll(':', '').trim()} · '
                            '${controller.noOfCartItems.value} ${TTexts.items.tr}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium!.apply(color: TColors.darkGrey),
                          ),
                        ),
                        const SizedBox(width: TSizes.sm),
                        TProductPriceText(
                          price: controller.totalCartPrice.value.toStringAsFixed(2),
                          isLarge: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.sm + 2),

                    /// -- Ödemeye geç (tam genişlik)
                    SizedBox(
                      width: double.infinity,
                      height: TSizes.buttonHeight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                          minimumSize: const Size(0, TSizes.buttonHeight),
                        ),
                        onPressed: () async {
                          // Sepet sunucuda ve web ile paylaşılıyor: ekran
                          // çizildiğinden beri oradaki bir siparişle tüketilmiş
                          // olabilir. Önce oku ki ödemeyi sunucuda artık olmayan
                          // bir sepetle açmayalım.
                          await controller.refreshFromBackend();
                          if (controller.cartItems.isEmpty) {
                            TLoaders.warningSnackBar(
                              title: TTexts.emptyCart.tr,
                              message: TTexts.cartMessage.tr,
                            );
                            return;
                          }
                          // Vergi/kargo ayarlarını tazele, ama başarısız bir
                          // istek ödemeye geçişi ASLA engellemesin.
                          try {
                            await settingsController.fetchSettingDetails();
                          } catch (_) {}
                          Get.to(() => const CheckoutScreen());
                        },
                        label: Text(TTexts.checkOut.tr),
                        icon: const Icon(Iconsax.arrow_right_3, size: TSizes.iconSm),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
