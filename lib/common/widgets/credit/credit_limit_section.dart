/// Kredi limiti bölümü ve onu **çizip çizmeme kapısı**.
///
/// 🔴 KAPI HERKESE AÇIK DEĞİL. Web (`pages/account.js`) bölümü
/// `CanBypassPayment || CanOrderWithoutStock` ile açıyor; ama sunucu
/// `paymentMode: transfer_only` iken `CanBypassPayment`'ı **her kullanıcıya**
/// `true` döndürüyor (canlıda doğrulandı: `HasCreditLine:false`,
/// `CanOrderWithoutStock:false` iken bile `CanBypassPayment:true`). O alana
/// bakılsaydı kredisi olmayan müşteride de "0 ₸ limit" kutusu açılırdı.
///
/// Bu yüzden kapı **`HasCreditLine || CanOrderWithoutStock`** okuyor:
/// `gateway` modunda sunucu iki alanı aynı yazdığı için web ile davranış
/// birebir aynı, `transfer_only` modunda ise yalnız gerçekten kredi satırı
/// açılmış müşteri bölümü görüyor.
///
/// Kural **tek yerde** durur: kredi gösteren her ekran
/// [shouldShowCreditSection] çağırır, yenisini yazmaz.
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

/// Kredi bölümü çizilsin mi. **Saf** fonksiyon — testle sabitlenir.
///
/// [hasCreditLine] sunucunun `HasCreditLine` alanı, [canOrderWithoutStock]
/// ise `CanOrderWithoutStock`. `CanBypassPayment` bilerek **alınmıyor**
/// (dosya başındaki not).
bool shouldShowCreditSection({
  required bool hasCreditLine,
  required bool canOrderWithoutStock,
}) =>
    hasCreditLine || canOrderWithoutStock;

/// Denetleyici üzerinden aynı kapı. Denetleyici hiç kurulmamışsa (misafir,
/// erken çizim) bölüm çizilmez.
bool creditSectionVisible() {
  if (!Get.isRegistered<UserSettingsController>()) return false;
  final s = UserSettingsController.instance;
  return shouldShowCreditSection(
    hasCreditLine: s.hasCreditLine,
    canOrderWithoutStock: s.canOrderWithoutStock,
  );
}

/// Toplam / kullanılan / kalan + ilerleme çubuğu.
///
/// TASARIM.md §5–6: sayfa akışında gölge yok, ayrım 1px çizgi; bu yüzden
/// referanstaki turuncu gradyan kart yerine beyaz, çerçeveli sade kutu.
class TCreditLimitSection extends StatelessWidget {
  const TCreditLimitSection({
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
    final theme = Theme.of(context);

    // Limit 0 iken bölüm gene çizilebilir (yetki var, limit henüz girilmemiş);
    // çubuk sıfıra düşer, sıfıra bölme yapılmaz.
    final usedRatio = creditLimit > 0 ? (usedCredit / creditLimit).clamp(0.0, 1.0) : 0.0;

    return TRoundedContainer(
      width: double.infinity,
      showBorder: true,
      radius: TSizes.cardRadiusLg,
      padding: const EdgeInsets.all(TSizes.md),
      backgroundColor: dark ? TColors.darkSurface : TColors.white,
      borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Kalan kredi (baş satır)
          Text(
            TTexts.availableCredit.tr,
            style: theme.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            TFormatter.formatCurrency(availableCredit),
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Kullanım çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
            child: LinearProgressIndicator(
              value: usedRatio,
              minHeight: 8,
              backgroundColor: dark ? TColors.darkBorder : TColors.softGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(TColors.primary),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Toplam / kullanılan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: TTexts.creditTotal.tr, value: TFormatter.formatCurrency(creditLimit)),
              _Stat(label: TTexts.usedCredit.tr, value: TFormatter.formatCurrency(usedCredit), alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
