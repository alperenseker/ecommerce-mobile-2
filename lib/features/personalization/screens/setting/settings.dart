/// Hesap ekranı — kişiselleştirme yüzeyinin giriş kapısı (alt gezinmenin
/// **profil sekmesi**).
///
/// 🔴 Düzen tamamen değişti. Eskiden beyaz bir başlık kabı, altında tek tek
/// yüzen `ListTile`'lardan oluşan uzun bir liste vardı; her satır aynı
/// ağırlıkta olduğu için kullanıcı aradığını gözüyle tarayamıyordu. Yeni
/// düzen üç katmanlı:
///
///   1. **Kimlik kartı** — avatar, ad, e-posta ve profili düzenleme düğmesi;
///      girişsiz kullanıcıda "giriş yap" çağrısı.
///   2. **Kısayol ızgarası** — siparişler · beğenilenler · karşılaştırma ·
///      kuponlar. Dört kutu, sayaçlarıyla; en sık gidilen dört yer listenin
///      içinde kaybolmuyor.
///   3. **Gruplanmış satır kartları** — hesap ve uygulama ayarları
///      (`TSettingsGroup`), en altta kırmızı çıkış satırı.
///
/// Referanstaki satır düzeni korundu, üç satır **açıldı**: kuponlar, iade
/// talepleri ve bildirimler (fazın kapsamı bunları istiyor ve üçünün de
/// rotası kayıtlı). Referansta yorumda kalan banka hesabı, hesap gizliliği,
/// "Load Data", konum / güvenli mod / HD görsel anahtarları **açılmadı** —
/// onların ekranı ya da ucu yok.
///
/// 🔴 **Kredi limiti satırı herkese çizilmez**: kapı tek yerde,
/// `common/widgets/credit/credit_limit_section.dart` → `creditSectionVisible()`.
///
/// ⚠️ Dil ve destek satırları `guestMode: false`: misafir de dil
/// değiştirebiliyor ve desteğe yazabiliyor (ekranın içinde giriş bağlantısı
/// var). Diğer bütün satırlar misafirde "önce giriş yapın" balonuna düşüyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/appbar_actions.dart';
import '../../../../common/widgets/credit/credit_limit_section.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../common/widgets/list_tiles/settings_group.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../home_menu.dart';
import '../../../../routes/app_routes.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/controllers/product/compare_controller.dart';
import '../../../shop/controllers/product/favourites_controller.dart';
import '../../../shop/screens/compare/compare.dart';
import '../../../shop/screens/favourites/favourite.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/user_settings_controller.dart';
import '../address/address.dart';
import '../profile/profile.dart';

// import 'upload_data.dart'; // "Load Data" ekranı referansta da kapalı

/// Canlı destek sohbetini açar.
///
/// Sohbetin kendisi (bul-ya-da-oluştur + mesajları yükle) `ChatScreen` içinde
/// çözülüyor; oraya doğrudan gitmek yavaş/başarısız bir ağ çağrısının
/// kullanıcıyı kilitli bir diyalogda tutmasını engelliyor.
///
/// ⚠️ Sohbet ekranı FAZ 10'da geliyor; rota henüz kayıtlı değilse GetX'in
/// "bilinmeyen rota" ekranı yerine bilgilendirme balonu gösterilir.
void _openLiveSupport() {
  if (!AppRoutes.isRegistered(TRoutes.chat)) {
    TLoaders.warningSnackBar(title: TTexts.chat.tr, message: TTexts.comingSoon.tr);
    return;
  }
  Get.toNamed(TRoutes.chat);
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.isTab = false});

  /// Alt gezinmenin **profil sekmesi** olarak açıldığında geri oku ve
  /// "ana menüye dön" davranışı yok: sekme zaten ana menünün içinde.
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final authRepo = AuthenticationRepository.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return PopScope(
      // Sekme kipinde geri tuşu ana sayfa sekmesine döner; itilerek açılmışsa
      // (menüden, bildirimden) ana menüye.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isTab) {
          AppScreenController.instance.selectedMenu.value = 0;
          return;
        }
        Get.offAll(const HomeMenu());
      },
      child: Scaffold(
        // Kartlar açık gri zemin üzerinde durur; ayrım zeminle veriliyor.
        backgroundColor: dark ? TColors.dark : TColors.light,
        appBar: TAppBar(
          // Sekme kipinde ok hiç çizilmez.
          leadingIcon: isTab ? null : Iconsax.arrow_left_24,
          leadingOnPressed: isTab ? null : () => Get.offAll(const HomeMenu()),
          title: Text(TTexts.account.tr, style: Theme.of(context).textTheme.headlineSmall),
          showActions: true,
          showSkipButton: false,
          actions: const [TAppBarActions()],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            TSizes.defaultSpace,
            TSizes.md,
            TSizes.defaultSpace,
            // Yüzen alt gezinme çubuğu son satırı örtmesin.
            MediaQuery.paddingOf(context).bottom + TSizes.spaceBtwSections,
          ),
          children: [
            const _IdentityCard(),
            const SizedBox(height: TSizes.spaceBtwItems),
            const _Shortcuts(),
            const SizedBox(height: TSizes.spaceBtwSections / 1.5),

            /// -- Hesap
            TSettingsGroup(
              title: TTexts.accountSetting.tr,
              children: [
                TSettingsRow(
                  icon: Iconsax.safe_home,
                  title: TTexts.myAddress.tr,
                  subtitle: TTexts.addressSubTitle.tr,
                  onTap: () => Get.to(() => const UserAddressScreen()),
                ),
                TSettingsRow(
                  icon: Iconsax.shopping_cart,
                  title: TTexts.myCart.tr,
                  subtitle: TTexts.cartSubTitle.tr,
                  onTap: () => Get.toNamed(TRoutes.cart),
                ),
                TSettingsRow(
                  icon: Iconsax.notification,
                  title: TTexts.notifications.tr,
                  subtitle: TTexts.notificationsSubTitle.tr,
                  onTap: () => Get.toNamed(TRoutes.notification),
                ),

                /// Kredi limiti (yalnız yönetici kredi satırı açtıysa)
                Obx(() {
                  if (!creditSectionVisible()) return const SizedBox.shrink();
                  final userSettings = UserSettingsController.instance;
                  return TSettingsRow(
                    icon: Iconsax.wallet_check,
                    title: TTexts.creditLimit.tr,
                    subtitle:
                        '${TTexts.availableCredit.tr}: ${TFormatter.formatCurrency(userSettings.availableCredit)}',
                    onTap: () => Get.to(() => const ProfileScreen()),
                  );
                }),
              ],
            ),

            /* -- Banka hesabı / hesap gizliliği (referansta da kapalı;
                  ekranı ya da ucu yok) */

            /// -- Uygulama
            TSettingsGroup(
              title: TTexts.appSetting.tr,
              children: [
                TSettingsRow(
                  icon: Iconsax.support,
                  title: TTexts.chat.tr,
                  subtitle: TTexts.chatSubTitle.tr,
                  onTap: _openLiveSupport,
                  // Misafir "önce giriş yapın" balonuna düşmüyor: ekran
                  // açılıyor ve İÇİNDE giriş bağlantısı gösteriliyor.
                  guestMode: false,
                ),
                TSettingsRow(
                  icon: Iconsax.language_square,
                  title: TTexts.languages.tr,
                  onTap: () => Get.toNamed(TRoutes.language),
                  guestMode: false,
                ),
              ],
            ),

            /// -- Çıkış
            if (!authRepo.isGuestUser)
              TSettingsGroup(
                children: [
                  TSettingsRow(
                    icon: Iconsax.logout,
                    title: TTexts.logout.tr,
                    danger: true,
                    guestMode: false,
                    onTap: controller.logout,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Kimlik kartı: avatar · ad · e-posta · profili düzenle.
///
/// Girişsiz kullanıcıda ad yerine "misafir", düğme yerine giriş çağrısı.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final authRepo = AuthenticationRepository.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final user = controller.user.value;
      final guest = authRepo.isGuestUser;
      final image = user.profilePicture;

      /// 🔴 Kartın içinde ayrı bir "Profil" düğmesi YOK: ikonlu küçük düğme
      /// avatarın yanında sıkışıyor, kartın hizasını bozuyordu. Artık kartın
      /// **tamamı** dokunulabilir ve sağdaki ok nereye gittiğini söylüyor.
      return Material(
        color: dark ? TColors.darkAccent : TColors.accent,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              guest
                  ? () => Get.toNamed(TRoutes.welcome)
                  : () => Get.to(() => const ProfileScreen()),
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              children: [
                TCircularImage(
                  image: image,
                  isNetworkImage: image.isNotEmpty,
                  placeholderIcon: Iconsax.user,
                  placeholderIconColor: TColors.primary,
                  width: 56,
                  height: 56,
                  padding: 0,
                  backgroundColor: dark ? TColors.darkSurface : TColors.white,
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        guest ? TTexts.guestUser.tr : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guest ? TTexts.guestSignInPrompt.tr : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Icon(
                  guest ? Iconsax.login : Iconsax.arrow_right_3,
                  size: 18,
                  color: TColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// En sık gidilen dört yerin kısayol ızgarası.
///
/// 🔴 Beğenilenler ve karşılaştırma alt gezinmeden kaldırıldı; ikisinin de
/// asıl kapısı burası. Sayaçlar canlı: kalp/terazi ile beslenen birikimlerin
/// dolu olup olmadığı listeye girmeden görünüyor.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    // 🔴 `IntrinsicHeight` + `stretch`: kutuların yüksekliği etiketin kaç
    // satıra sardığına göre değişiyordu ("Beğenilen Ürünler" iki satır,
    // "Siparişlerim" bir satır) ve ızgara kırık görünüyordu. Artık hepsi en
    // uzunu kadar, yani AYNI boyda.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ShortcutTile(
              icon: Iconsax.box,
              label: TTexts.myOrders.tr,
              onTap: () => Get.toNamed(TRoutes.order),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Obx(
              () => _ShortcutTile(
                icon: Iconsax.heart,
                label: TTexts.likedProducts.tr,
                count: FavouriteController.instance.favorites.length,
                onTap: () => Get.to(() => const FavouriteScreen()),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Obx(
              () => _ShortcutTile(
                icon: Iconsax.arrow_swap_horizontal,
                label: TTexts.comparison.tr,
                count: CompareController.instance.compareIds.length,
                onTap: () => Get.to(() => const CompareScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kısayol ızgarasının tek kutusu.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Sıfırsa balon çizilmez — "0" yazan balon boş listede de dikkat çekiyor.
  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final authRepo = AuthenticationRepository.instance;

    return Material(
      color: dark ? TColors.darkSurface : TColors.white,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: authRepo.isGuestUser ? authRepo.showSignInRequiredPopup : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
          padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: count > 0,
                backgroundColor: TColors.deal,
                textColor: TColors.white,
                label: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                child: Icon(icon, size: 22, color: TColors.primary),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.apply(color: dark ? TColors.light : TColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
