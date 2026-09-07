/// Kredi limiti bölümü ve **kimin göreceğini** belirleyen kapı.
///
/// 🔴 Aynı kural iki ekranda gerekiyor (profil ve ayarlar). FAZ 08'in ödeme
/// kapılarındaki dersle aynı sebeple tek dosyada tutuluyor: kopyalansaydı
/// biri güncellenip diğeri unutulurdu.
///
/// 🔴 **Kredi limiti herkese çizilmez.** Web (`pages/account.js`) kapıyı
/// `CanBypassPayment || CanOrderWithoutStock` diye kuruyor; ama sunucu
/// `transfer_only` modunda `CanBypassPayment`'ı **herkese** true döndürüyor
/// (K29.7 uyum katmanı) ve bölüm o hâliyle bütün kullanıcılarda açılırdı.
/// Bu yüzden gerçek kredi satırını gösteren `HasCreditLine` kullanılıyor.
/// `gateway` modunda sunucu iki alanı aynı yazdığı için web ile davranış
/// birebir aynı kalıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/personalization/controllers/user_settings_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/rounded_container.dart';
import '../texts/section_heading.dart';

/// Kredi limiti bölümü çizilsin mi — **saf** fonksiyon (test edilebilir).
///
/// [hasCreditLine] müşterinin gerçekten kendi kredi satırı var mı;
/// [canOrderWithoutStock] stoksuz sipariş yetkisi. İkisinden biri yeterli.
bool shouldShowCreditSection({required bool hasCreditLine, required bool canOrderWithoutStock}) =>
    hasCreditLine || canOrderWithoutStock;

/// Controller'ı okuyan sarmalayıcı. Yetkiler henüz yüklenmediyse ya da
/// controller kayıtlı değilse bölüm **hiç çizilmez** (güvenli taraf).
bool shouldShowCreditSectionForCurrentUser() {
  if (!Get.isRegistered<UserSettingsController>()) return false;
  final settings = UserSettingsController.instance;
  return shouldShowCreditSection(
    hasCreditLine: settings.hasCreditLine,
    canOrderWithoutStock: settings.canOrderWithoutStock,
  );
}

/// Başlık + kart. Yetkisi olmayan kullanıcıda `SizedBox.shrink()` döner.
class TCreditLimitSection extends StatelessWidget {
  const TCreditLimitSection({super.key, this.topSpacing = false});

  /// Ayarlar ekranında bölümden önce ekstra boşluk gerekiyor.
  final bool topSpacing;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // `Obx`'in izleyeceği değer ilk satırda okunur; kapı fonksiyonu
      // controller'ı doğrudan okuduğu için burada bir kez daha dokunuluyor.
      if (!Get.isRegistered<UserSettingsController>()) return const SizedBox.shrink();
      final settings = UserSettingsController.instance.settings.value;

      if (!shouldShowCreditSection(
        hasCreditLine: settings.hasCreditLine,
        canOrderWithoutStock: settings.canOrderWithoutStock,
      )) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topSpacing) const SizedBox(height: TSizes.spaceBtwSections),
          TSectionHeading(title: TTexts.creditLimit.tr, showActionButton: false),
          const SizedBox(height: TSizes.spaceBtwItems),
          TCreditLimitCard(
            creditLimit: settings.creditLimit,
            usedCredit: settings.usedCredit,
            availableCredit: settings.availableCredit,
          ),
        ],
      );
    });
  }
}

/// Kredi limiti kartı: toplam · kullanılan · kalan + ilerleme çubuğu.
///
/// TASARIM.md §5–6: referanstaki turuncu degrade kart kalktı; beyaz, 1px
/// çerçeveli, gölgesiz kutu geldi. Çubuk **kalan** krediyi gösteriyor
/// (web `account.js` de öyle: `width: 100 - pct`).
class TCreditLimitCard extends StatelessWidget {
  const TCreditLimitCard({
    super.key,
    required this.creditLimit,
    required this.usedCredit,
    required this.availableCredit,
  });

  final double creditLimit;
  final double usedCredit;
  final double availableCredit;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // Limit 0 ise (yetki var ama limit tanımlanmamış) çubuk boş kalır.
    final availableShare = creditLimit > 0 ? (availableCredit / creditLimit).clamp(0.0, 1.0) : 0.0;

    return TRoundedContainer(
      width: double.infinity,
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
      backgroundColor: dark ? TColors.darkSurface : TColors.white,
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Kalan kredi (öne çıkan sayı)
          Text(
            TTexts.availableCredit.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.xs),
          Text(TFormatter.formatCurrency(availableCredit), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- İlerleme çubuğu (kalan oran)
          ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
            child: LinearProgressIndicator(
              value: availableShare,
              minHeight: 8,
              backgroundColor: dark ? TColors.darkBorder : TColors.softGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(TColors.primary),
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            '${(availableShare * 100).round()}% ${TTexts.creditAvailableShare.tr}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Toplam / kullanılan kırılımı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(context, TTexts.creditTotal.tr, TFormatter.formatCurrency(creditLimit)),
              _stat(context, TTexts.usedCredit.tr, TFormatter.formatCurrency(usedCredit), alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
