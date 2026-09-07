/// Hesap (ayarlar) ekranı — kişiselleştirme yüzeyinin giriş noktası.
///
/// Sıralama referanstakiyle aynı: kullanıcı kartı → hesap ayarları →
/// uygulama ayarları → çıkış. Referansta yorum satırına alınmış olan
/// kuponlar, iade talepleri ve bildirimler bu projede **açık** (FAZ 09
/// kapsamı); rotalarının hepsi kayıtlı.
///
/// 🔴 Kredi limiti bölümü **herkese çizilmez** — bkz. [_CreditLimitSection].
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/credit/credit_limit_section.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/list_tiles/settings_menu_tile.dart';
import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../home_menu.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/user_controller.dart';
import '../address/address.dart';
import '../profile/profile.dart';

/// Destek sohbetini doğrudan açar.
///
/// Sohbetin kendisi (bul-ya-da-oluştur + mesaj yükleme) `ChatScreen` içinde
/// kendi kurtarılabilir yükleme durumuyla çözülüyor; buradan bir diyalogla
/// beklemek, yavaş/başarısız bir çağrıda kullanıcıyı kilitliyordu.
void _openLiveSupport() => Get.toNamed(TRoutes.chat);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final authRepo = AuthenticationRepository.instance;

    return PopScope(
      // Bu ekran bir sekme değil; sistem geri tuşu kullanıcıyı boşluğa
      // düşürmesin diye ana menüye dönülür.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Get.offAll(const HomeMenu());
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              /// -- Başlık + kullanıcı kartı
              TPrimaryHeaderContainer(
                child: Column(
                  children: [
                    TAppBar(
                      leadingIcon: Iconsax.arrow_left_24,
                      leadingOnPressed: () => Get.offAll(const HomeMenu()),
                      title: Text(TTexts.account.tr, style: Theme.of(context).textTheme.headlineSmall),
                      showActions: false,
                      showSkipButton: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                      child: TUserProfileTile(onPressed: () => Get.to(() => const ProfileScreen())),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// -- Hesap ayarları
                    TSectionHeading(title: TTexts.accountSetting.tr, showActionButton: false),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    TSettingsMenuTile(
                      icon: Iconsax.safe_home,
                      title: TTexts.myAddress.tr,
                      subTitle: TTexts.addressSubTitle.tr,
                      onTap: () => Get.to(() => const UserAddressScreen()),
                    ),
                    TSettingsMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: TTexts.myCart.tr,
                      subTitle: TTexts.cartSubTitle.tr,
                      onTap: () => Get.toNamed(TRoutes.cart),
                    ),
                    TSettingsMenuTile(
                      icon: Iconsax.bag_tick,
                      title: TTexts.myOrders.tr,
                      subTitle: TTexts.ordersSubTitle.tr,
                      onTap: () => Get.toNamed(TRoutes.order),
                    ),
                    TSettingsMenuTile(
                      icon: Iconsax.discount_shape,
                      title: TTexts.myCoupons.tr,
                      subTitle: TTexts.myCouponsSubTitle.tr,
                      onTap: () => Get.toNamed(TRoutes.coupon),
                    ),
                    TSettingsMenuTile(
                      icon: Iconsax.refresh_circle,
                      title: TTexts.returnRequest.tr,
                      subTitle: TTexts.requestsSubTitle.tr,
                      onTap: () => Get.toNamed(TRoutes.returnRequest),
                    ),
                    TSettingsMenuTile(
                      icon: Iconsax.notification,
                      title: TTexts.notifications.tr,
                      subTitle: TTexts.notificationsSubTitle.tr,
                      onTap: () => Get.toNamed(TRoutes.notification),
                    ),

                    /// -- Kredi limiti (yalnız yetkili kullanıcıda; kapı ortak
                    /// dosyada: `common/widgets/credit/credit_limit_section.dart`)
                    const TCreditLimitSection(topSpacing: true),

                    /// -- Uygulama ayarları
                    const SizedBox(height: TSizes.spaceBtwSections),
                    TSectionHeading(title: TTexts.appSetting.tr, showActionButton: false),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    TSettingsMenuTile(
                      icon: Iconsax.support,
                      title: TTexts.chat.tr,
                      subTitle: TTexts.chatSubTitle.tr,
                      // 🔴 Misafir kapısı BURADA kapalı (`guestMode: false`):
                      // girişsiz kullanıcı "önce giriş yapın" balonuna
                      // düşmez, ekran açılır ve içinde giriş bağlantısı
                      // gösterilir (FAZ 10 — duvara çarptırma yok).
                      guestMode: false,
                      onTap: () => _openLiveSupport(),
                    ),
                    TSettingsMenuTile(
                      icon: Icons.language,
                      title: TTexts.languages.tr,
                      subTitle: '',
                      // Dil girişten bağımsız: misafir de değiştirebilmeli.
                      guestMode: false,
                      onTap: () => Get.toNamed(TRoutes.language),
                    ),

                    /// -- Çıkış
                    const SizedBox(height: TSizes.spaceBtwSections),
                    if (!authRepo.isGuestUser) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => controller.logout(),
                          child: Text(TTexts.logout.tr),
                        ),
                      ),
                    ],
                    const SizedBox(height: TSizes.spaceBtwSections * 2.5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
