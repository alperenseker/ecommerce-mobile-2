/// Profil ekranı: kimlik, iletişim, hesap tipi, fiyat kategorisi, güvenlik ve
/// (yetkisi varsa) kredi limiti.
///
/// 🔴 Düzen tamamen değişti. Eskiden avatar, altında `Divider`larla ayrılmış
/// "etiket — değer — ok" satırları vardı: satırların üçe bölünmüş hizası uzun
/// değerlerde kayıyor, salt okunur satırla düzenlenebilir satır aynı
/// görünüyordu. Artık üstte **avatar kartı**, altında konularına göre
/// **gruplanmış satır kartları** (`TSettingsGroup`) var; salt okunur satırlar
/// kilit ikonu taşıyor ve dokunmaya tepki vermiyor, düzenlenebilir olanlar ok
/// gösteriyor.
///
/// 🔴 **Şirket / İP hesabında şirket adı · direktör · BİN SALT OKUNUR.**
/// O üç alan 1C'den geliyor (`GET /company/{iin}`), uygulamadan
/// değiştirilemez; satırların ikonu kilit ve altlarında sebebi yazıyor.
/// Bireysel hesapta ad satırı `ChangeName` ekranını açar.
///
/// 🔴 Fiyat kategorisi satırı KALDIRILDI: bayi iskontosunu belirleyen bir
/// yönetici alanı, müşteriye bir şey anlatmıyordu.
///
/// 🔴 **Kredi bölümü herkese çizilmez**: kapı tek yerde,
/// `common/widgets/credit/credit_limit_section.dart` → `creditSectionVisible()`.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/credit/credit_limit_section.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../common/widgets/list_tiles/settings_group.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/user_settings_controller.dart';
import 'change_name.dart';
import 'change_password.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        showBackArrow: true,
        showSkipButton: false,
        showActions: false,
        title: Text(TTexts.profile.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          TSizes.md,
          TSizes.defaultSpace,
          MediaQuery.paddingOf(context).bottom + TSizes.spaceBtwSections,
        ),
        children: [
          /// -- Avatar kartı
          const _AvatarCard(),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Kimlik
          Obx(() {
            final user = controller.user.value;
            if (user.isCompanyLike) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TSettingsGroup(
                    title: TTexts.profileInfo.tr,
                    children: [
                      // Sunucu şirket adını `FirstName`, direktörü `LastName`
                      // alanında taşıyor (kayıt akışı 1C'den böyle dolduruyor).
                      TSettingsRow(
                        icon: Iconsax.buildings_2,
                        title: TTexts.companyName.tr,
                        value: user.firstName,
                        locked: true,
                      ),
                      TSettingsRow(
                        icon: Iconsax.user_tag,
                        title: TTexts.director.tr,
                        value: user.lastName,
                        locked: true,
                      ),
                      if (user.iin.isNotEmpty)
                        TSettingsRow(
                          icon: Iconsax.card,
                          title: TTexts.iinBin.tr,
                          value: user.iin,
                          locked: true,
                        ),
                    ],
                  ),
                  // Kilidin sebebi yazılmazsa müşteri düzenleme düğmesini arıyor.
                  const _LockedNote(),
                  const SizedBox(height: TSizes.spaceBtwSections / 1.5),
                ],
              );
            }
            return TSettingsGroup(
              title: TTexts.profileInfo.tr,
              children: [
                TSettingsRow(
                  icon: Iconsax.user,
                  title: TTexts.name.tr,
                  value: user.fullName,
                  onTap: () => Get.to(() => const ChangeName()),
                ),
                TSettingsRow(
                  icon: Iconsax.tag_user,
                  title: TTexts.username.tr,
                  value: user.userName,
                  locked: true,
                ),
              ],
            );
          }),

          /// -- İletişim + hesap tipi + fiyat kategorisi
          Obx(() {
            final user = controller.user.value;
            return TSettingsGroup(
              title: TTexts.personalInfo.tr,
              children: [
                TSettingsRow(
                  icon: Iconsax.sms,
                  title: TTexts.email.tr,
                  value: user.email,
                  locked: true,
                ),
                if (user.phoneNumber.isNotEmpty)
                  TSettingsRow(
                    icon: Iconsax.call,
                    title: TTexts.phoneNo.tr,
                    value: user.phoneNumber,
                    locked: true,
                  ),
                TSettingsRow(
                  icon: Iconsax.profile_2user,
                  title: TTexts.accountType.tr,
                  value: (user.isCompanyLike ? TTexts.accountTypeCompany : TTexts.accountTypeRetail).tr,
                  locked: true,
                ),
              ],
            );
          }),

          /// -- Güvenlik
          TSettingsGroup(
            title: TTexts.security.tr,
            children: [
              TSettingsRow(
                icon: Iconsax.lock_1,
                title: TTexts.password.tr,
                value: TTexts.changePassword.tr,
                onTap: () => Get.to(() => const ChangePasswordScreen()),
              ),
            ],
          ),

          /// -- Kredi limiti (yalnız yetkisi olana)
          Obx(() {
            if (!creditSectionVisible()) return const SizedBox.shrink();
            final userSettings = UserSettingsController.instance;
            return Padding(
              padding: const EdgeInsets.only(bottom: TSizes.spaceBtwSections / 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: TSizes.xs, bottom: TSizes.sm),
                    child: Text(
                      TTexts.creditLimit.tr,
                      style: Theme.of(context).textTheme.labelMedium!
                          .apply(color: TColors.darkGrey, fontWeightDelta: 1)
                          .copyWith(letterSpacing: 0.4),
                    ),
                  ),
                  TCreditLimitSection(
                    creditLimit: userSettings.creditLimit,
                    usedCredit: userSettings.usedCredit,
                    availableCredit: userSettings.availableCredit,
                  ),
                ],
              ),
            );
          }),

          /// -- Hesabı sil
          TSettingsGroup(
            children: [
              TSettingsRow(
                icon: Iconsax.trash,
                title: TTexts.deleteAccount.tr,
                danger: true,
                guestMode: false,
                onTap: controller.deleteAccountWarningPopup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar kartı — sayfanın kime ait olduğunu söyleyen tek yer.
class _AvatarCard extends StatelessWidget {
  const _AvatarCard();

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: TSizes.lg, horizontal: TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkAccent : TColors.accent,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Obx(() {
        final user = controller.user.value;
        final image = user.profilePicture;
        return Column(
          children: [
            // `Center` şart: satır tam genişlik kaplıyor ve `TCircularImage`
            // sınırsız genişlik alınca daireden hapa dönüşüyor.
            Center(
              child: TCircularImage(
                image: image,
                width: 84,
                height: 84,
                padding: 0,
                isNetworkImage: image.isNotEmpty,
                placeholderIcon: Iconsax.user,
                placeholderIconColor: TColors.primary,
                backgroundColor: dark ? TColors.darkSurface : TColors.white,
              ),
            ),
            const SizedBox(height: TSizes.md),
            Text(
              user.fullName.trim().isEmpty ? TTexts.guestUser.tr : user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (user.email.isNotEmpty)
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      }),
    );
  }
}

/// "Bu bilgiler 1C'den geliyor" notu. Kilidin sebebi yazılmazsa müşteri
/// düzenleme düğmesini arıyor.
class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TSizes.xs, TSizes.sm, TSizes.xs, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle, size: TSizes.iconXs, color: TColors.darkGrey),
          const SizedBox(width: TSizes.xs),
          Expanded(
            child: Text(
              TTexts.companyDataFrom1C.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
