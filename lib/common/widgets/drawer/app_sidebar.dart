/// Uygulamanın yan menüsü (drawer).
///
/// 🔴 Burası ÖNCE yalnız kategori ağacıydı (`TCategorySidebar`). Kataloğun
/// tamamı zaten mağaza sekmesinde ve süzgecinde var; yan menünün tek işi
/// kategori gezmek olunca hem tekrar oluyordu hem de kullanıcının sık gittiği
/// yerler (siparişler, iadeler, adresler, ayarlar, çıkış) hiçbir kısayolda
/// durmuyordu. Artık menü şu sırayla okunuyor:
///
///   1. kullanıcı başlığı (girişsizse "giriş yap")
///   2. **hesabım** — siparişler · adresler · bildirimler
///   3. **kategoriler** — eski ağaç, olduğu gibi (değişken derinlik)
///   4. **uygulama** — canlı destek · dil · ayarlar
///   5. altta sabit: çıkış (girişsizse giriş)
///
/// Favoriler, sepet ve mağaza BİLEREK yok: üçü de alt gezinmenin sekmesi,
/// menüye ikinci bir kapı açmak kullanıcıya iki ayrı yol öğretmek olurdu.
///
/// Kategori ağacı **değişken derinliktedir** ve özyinelemeli çizilir: canlıda
/// Foral 4 seviye (Foral → Фурнитура → ДВЕРНЫЕ/ОКОННЫЕ → 11 yaprak), Fores 2,
/// Stark Alpha 1. Sabit iki seviye basmak Foral'ın yapraklarını gizler.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../features/shop/controllers/categories_controller.dart';
import '../../../features/shop/models/category_model.dart';
import '../../../features/shop/screens/all_products/all_products.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../images/t_circular_image.dart';

class TAppSidebar extends StatelessWidget {
  const TAppSidebar({super.key});

  /// Menü ekranın tamamını kaplamaz; sağ kenarı yuvarlak ve arkasında sayfa
  /// görünür kalır. Geniş ekranlarda sonsuza kadar genişlemesin diye tavanı var.
  static const double _maxWidth = 340.0;
  static const double _edgeRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final width = (MediaQuery.sizeOf(context).width * 0.86).clamp(280.0, _maxWidth);

    // 🔴 Düz `Get.put` DEĞİL: menü her açılışta yeniden çiziliyor ve `put`
    // her seferinde YENİ bir controller kurup kategorileri baştan çekiyordu.
    // Kurulmuşsa var olan kullanılır.
    final categories = Get.isRegistered<CategoryController>()
        ? CategoryController.instance
        : Get.put(CategoryController());

    return Drawer(
      width: width,
      elevation: 0,
      backgroundColor: dark ? TColors.dark : TColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(_edgeRadius)),
      ),
      child: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              children: [
                _SectionLabel(TTexts.account.tr),
                _MenuTile(
                  icon: Iconsax.box,
                  label: TTexts.myOrders.tr,
                  onTap: () => _go(context, TRoutes.order),
                ),
                _MenuTile(
                  icon: Iconsax.location,
                  label: TTexts.myAddress.tr,
                  onTap: () => _go(context, TRoutes.userAddress),
                ),
                _MenuTile(
                  icon: Iconsax.notification,
                  label: TTexts.notifications.tr,
                  onTap: () => _go(context, TRoutes.notification),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),
                _SectionLabel(TTexts.categories.tr),
                Obx(() {
                  final controller = categories;
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.all(TSizes.md),
                      child: Center(child: CircularProgressIndicator(color: TColors.primary)),
                    );
                  }
                  final roots = controller.rootCategories;
                  if (roots.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(TSizes.md),
                      child: Center(child: Text(TTexts.noDataFound.tr)),
                    );
                  }
                  return Column(
                    children: roots.map((c) => _CategoryNode(category: c, depth: 0)).toList(),
                  );
                }),

                const SizedBox(height: TSizes.spaceBtwItems),
                _SectionLabel(TTexts.appSetting.tr),
                _MenuTile(
                  icon: Iconsax.headphone,
                  label: TTexts.liveSupport.tr,
                  onTap: () => _go(context, TRoutes.chat),
                ),
                _MenuTile(
                  icon: Iconsax.language_square,
                  label: TTexts.languages.tr,
                  onTap: () => _go(context, TRoutes.language),
                ),
                _MenuTile(
                  icon: Iconsax.setting_2,
                  label: TTexts.accountSetting.tr,
                  onTap: () => _go(context, TRoutes.settings),
                ),
              ],
            ),
          ),
          const _Footer(),
        ],
      ),
    );
  }

  /// Menüyü kapatıp hedefe gider — menü açık kalırsa geri dönüşte üstte duruyor.
  static void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    Get.toNamed(route);
  }
}

/// Kullanıcı başlığı: avatar + ad + e-posta. Girişsiz kullanıcıda "giriş yap".
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      // Yumuşak indigo panel: menünün başladığı yeri çizgiyle değil ZEMİNLE
      // ayırıyor — eski başlıktaki 1px çizgi menüyü ikiye bölünmüş
      // gösteriyordu.
      color: dark ? TColors.darkAccent : TColors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.md, TSizes.sm, TSizes.lg),
          child: Obx(() {
            final user = UserController.instance.user.value;
            final guest = AuthenticationRepository.instance.isGuestUser;
            final image = user.profilePicture;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Iconsax.close_circle, color: TColors.darkerGrey),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Row(
                  children: [
                    TCircularImage(
                      image: image,
                      isNetworkImage: image.isNotEmpty,
                      placeholderIcon: Iconsax.user,
                      placeholderIconColor: TColors.primary,
                      width: 52,
                      height: 52,
                      padding: 0,
                      backgroundColor: dark ? TColors.darkSurface : TColors.white,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            guest || user.fullName.trim().isEmpty
                                ? TTexts.guestUser.tr
                                : user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            guest || user.email.isEmpty ? TTexts.guestSignInPrompt.tr : user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  height: TSizes.buttonHeight - 6,
                  child: guest
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Get.toNamed(TRoutes.logIn);
                          },
                          child: Text(TTexts.signIn.tr),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Get.toNamed(TRoutes.userProfile);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: dark ? TColors.darkSurface : TColors.white,
                          ),
                          child: Text(TTexts.profile.tr),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Menünün dibindeki sabit çıkış satırı.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    if (AuthenticationRepository.instance.isGuestUser) return const SizedBox.shrink();
    final dark = THelperFunctions.isDarkMode(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary)),
      ),
      child: SafeArea(
        top: false,
        child: _MenuTile(
          icon: Iconsax.logout,
          label: TTexts.logout.tr,
          color: TColors.error,
          // Onay penceresini `UserController` açıyor; menü de kapanıyor ki
          // pencere menünün üstünde açılmasın.
          onTap: () {
            Navigator.of(context).pop();
            UserController.instance.logout();
          },
        ),
      ),
    );
  }
}

/// Bölüm etiketi — küçük, soluk, ayırıcı çizgi yerine geçer.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.sm, TSizes.defaultSpace, TSizes.xs),
      // 🔴 BÜYÜK HARFE ÇEVRİLMİYOR: Dart'ın `toUpperCase`i yerelden habersiz,
      // Türkçe "i"yi "I" yapıyor ("Koleksiyonum" → "KOLEKSIYONUM").
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!
            .apply(color: TColors.darkGrey, fontWeightDelta: 1)
            .copyWith(letterSpacing: 0.4),
      ),
    );
  }
}

/// Tek menü satırı: yumuşak kare içinde ikon + etiket.
class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Vurgulu satırlar için (çıkış kırmızı). Boşsa nötr çizilir.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final foreground = color ?? (dark ? TColors.light : TColors.textPrimary);
    final iconColor = color ?? TColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color == null
                    ? (dark ? TColors.darkSurface : TColors.lightGrey)
                    : color!.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: TSizes.spaceBtwItems - 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!.apply(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategori ağacının tek düğümü. Çocuğu varsa açılır liste, yoksa yaprak.
/// Kendini özyinelemeli çağırır — derinlik sınırı yoktur.
class _CategoryNode extends StatelessWidget {
  const _CategoryNode({required this.category, required this.depth});

  final CategoryModel category;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    final children = controller.getChildren(category.id);
    final dark = THelperFunctions.isDarkMode(context);
    final indent = TSizes.defaultSpace + (depth * TSizes.md);

    if (children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: indent, right: TSizes.defaultSpace),
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(Iconsax.minus, size: 14, color: TColors.darkGrey),
        horizontalTitleGap: TSizes.sm,
        minLeadingWidth: 0,
        title: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
        onTap: () {
          Navigator.of(context).pop();
          Get.to(
            () => AllProducts(
              title: category.name,
              futureMethod: controller.getCategoryProducts(categoryId: category.id),
            ),
          );
        },
      );
    }

    final isTopLevel = depth == 0;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: indent, right: TSizes.sm),
        childrenPadding: EdgeInsets.zero,
        dense: !isTopLevel,
        // Kök kategoriler menünün diğer satırlarıyla aynı yumuşak kareyi taşır;
        // alt dallar ince bir klasör ikonuyla geride kalır.
        leading: isTopLevel
            ? Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? TColors.darkSurface : TColors.lightGrey,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: const Icon(Iconsax.category_2, size: 18, color: TColors.primary),
              )
            : Icon(Iconsax.folder_2, size: 16, color: TColors.darkGrey),
        title: Text(
          category.name,
          style: isTopLevel
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(context).textTheme.bodyMedium,
        ),
        children: children.map((child) => _CategoryNode(category: child, depth: depth + 1)).toList(),
      ),
    );
  }
}
