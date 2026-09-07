/// Profil ekranı: hesap kimliği, kişisel bilgiler, hesap tipi/fiyat kategorisi,
/// güvenlik (şifre) ve —yetkisi varsa— kredi limiti.
///
/// 🔴 Şirket hesabında şirket adı / direktör / BİN **salt okunur**: bu alanlar
/// 1C'den geliyor, uygulamadan değiştirilemez. Kilit ikonu ve altındaki not
/// bunu söylüyor.
///
/// 🔴 Kredi limiti bölümü **herkese çizilmez** — bkz. [_CreditSection].
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/credit/credit_limit_section.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/user_settings_controller.dart';
import 'change_name.dart';
import 'change_password.dart';
import 'widgets/profile_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showSkipButton: false,
        showActions: false,
        title: Text(TTexts.profile.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -- Avatar
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final networkImage = controller.user.value.profilePicture;
                  return TCircularImage(
                    image: networkImage,
                    width: 80,
                    height: 80,
                    padding: 0,
                    isNetworkImage: networkImage.isNotEmpty,
                    placeholderIcon: Icons.person,
                    placeholderIconColor: TColors.white,
                    backgroundColor: networkImage.isNotEmpty ? null : TColors.primary,
                  );
                }),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Hesap kimliği
              TSectionHeading(title: TTexts.profileInfo.tr, showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),
              Obx(() {
                final user = controller.user.value;

                // Şirket / İP hesabı: 1C'den gelen üç alan, hepsi kilitli.
                if (user.isCompanyLike) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TProfileMenu(
                        onPressed: () {},
                        title: TTexts.companyName.tr,
                        value: user.firstName,
                        icon: Iconsax.lock,
                      ),
                      TProfileMenu(
                        onPressed: () {},
                        title: TTexts.director.tr,
                        value: user.lastName,
                        icon: Iconsax.lock,
                      ),
                      if (user.iin.isNotEmpty)
                        TProfileMenu(
                          onPressed: () {},
                          title: TTexts.iinBin.tr,
                          value: user.iin,
                          icon: Iconsax.lock,
                        ),
                      const SizedBox(height: TSizes.sm),
                      const _LockedNote(),
                    ],
                  );
                }

                // Bireysel hesap: ad düzenlenebilir.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TProfileMenu(
                      onPressed: () => Get.to(() => const ChangeName()),
                      title: TTexts.name.tr,
                      value: user.fullName,
                    ),
                    TProfileMenu(onPressed: () {}, title: TTexts.username.tr, value: user.userName),
                  ],
                );
              }),
              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Kişisel bilgiler
              TSectionHeading(title: TTexts.personalInfo.tr, showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),
              Obx(() {
                final user = controller.user.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TProfileMenu(onPressed: () {}, title: TTexts.email.tr, value: user.email, icon: Iconsax.lock),
                    if (user.phoneNumber.isNotEmpty)
                      TProfileMenu(
                        onPressed: () {},
                        title: TTexts.phoneNo.tr,
                        value: user.formattedPhoneNo,
                        icon: Iconsax.lock,
                      ),

                    /// Hesap tipi ve fiyat kategorisi — ikisi de sunucunun
                    /// kararı, ekrandan değiştirilemez.
                    TProfileMenu(
                      onPressed: () {},
                      title: TTexts.accountType.tr,
                      value: user.isCompanyLike ? TTexts.accountTypeCompany.tr : TTexts.accountTypeRetail.tr,
                      icon: Iconsax.lock,
                    ),
                    const _PriceCategoryRow(),
                  ],
                );
              }),
              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Güvenlik
              TSectionHeading(title: TTexts.security.tr, showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),
              TProfileMenu(
                onPressed: () => Get.to(() => const ChangePasswordScreen()),
                title: TTexts.password.tr,
                value: TTexts.changePassword.tr,
                icon: Iconsax.lock_1,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Kredi limiti (yalnız yetkili kullanıcıda; kapı ortak
              /// dosyada: `common/widgets/credit/credit_limit_section.dart`)
              const TCreditLimitSection(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Hesabı sil
              Center(
                child: TextButton(
                  onPressed: () => controller.deleteAccountWarningPopup(),
                  child: Text(
                    TTexts.deleteAccount.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.error),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Bu bilgiler 1C'den geliyor" notu — kilitli alanların neden kilitli
/// olduğunu söylemezsek kullanıcı düzenlemeye çalışıp takılıyor.
class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return TRoundedContainer(
      radius: TSizes.borderRadiusSm,
      padding: const EdgeInsets.all(TSizes.sm),
      backgroundColor: dark ? TColors.darkAccent : TColors.infoSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle, size: TSizes.iconSm, color: TColors.info),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              TTexts.companyDataFrom1C.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fiyat kategorisi satırı. Sunucu boş döndürdüyse satır **hiç çizilmez** —
/// boş bir "Fiyat kategorisi: —" satırı bilgi vermiyor.
class _PriceCategoryRow extends StatelessWidget {
  const _PriceCategoryRow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.isRegistered<UserSettingsController>()) return const SizedBox.shrink();
      final category = UserSettingsController.instance.settings.value.priceCategory.trim();
      if (category.isEmpty) return const SizedBox.shrink();
      return TProfileMenu(
        onPressed: () {},
        title: TTexts.priceCategory.tr,
        value: category,
        icon: Iconsax.lock,
      );
    });
  }
}
