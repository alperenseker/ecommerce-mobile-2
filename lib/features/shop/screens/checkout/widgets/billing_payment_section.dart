/// Ödeme yöntemi seçici — **yalnız `gateway` modundaki kredisiz müşteriye**
/// çizilir (web `pages/checkout.js` → `paymentHtml()`).
///
/// 🔴 `transfer_only` modunda ve kredili müşteride bu widget HİÇ çizilmez;
/// oralarda tek yol vardır ve seçenek sunmak yanıltıcı olurdu. Kart seçeneği
/// o modlarda çizilseydi müşteri sunucunun 409'unu (`payment_disabled`)
/// görürdü — bu ekranın en önemli kuralı budur.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/checkout_controller.dart';

class TBillingPaymentSection extends StatelessWidget {
  const TBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: TTexts.paymentMethods.tr, showActionButton: false),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(
          () => Column(
            children: [
              _TMethodPick(
                code: TPaymentMethodCodes.card,
                icon: Iconsax.card,
                title: TTexts.creditCard.tr,
                description: TTexts.creditCardText.tr,
                selected: controller.selectedMethodCode.value == TPaymentMethodCodes.card,
                onTap: () => controller.selectedMethodCode.value = TPaymentMethodCodes.card,
              ),
              _TMethodPick(
                code: TPaymentMethodCodes.bankTransfer,
                icon: Iconsax.bank,
                title: TTexts.bankTransfer.tr,
                description: TTexts.bankTransferText.tr,
                selected: controller.selectedMethodCode.value == TPaymentMethodCodes.bankTransfer,
                onTap: () => controller.selectedMethodCode.value = TPaymentMethodCodes.bankTransfer,
              ),
              _TMethodPick(
                code: TPaymentMethodCodes.cashOnDelivery,
                icon: Iconsax.truck,
                title: TTexts.cashOnDelivery.tr,
                description: TTexts.cashOnDeliveryText.tr,
                selected: controller.selectedMethodCode.value == TPaymentMethodCodes.cashOnDelivery,
                onTap: () => controller.selectedMethodCode.value = TPaymentMethodCodes.cashOnDelivery,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tek seçenek kutusu. TASARIM.md §6: seçilmemiş hâl beyaz zemin + ince
/// çerçeve, seçili hâl indigo çerçeve + `accent` zemin — bir listede üç dolu
/// indigo kutu ekranı bağırtıyor.
class _TMethodPick extends StatelessWidget {
  const _TMethodPick({
    required this.code,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  /// Sunucuya gidecek yöntem kodu — yalnız hata ayıklamada okunur, ekranda
  /// gösterilmez.
  final String code;
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        onTap: onTap,
        child: TRoundedContainer(
          showBorder: true,
          radius: TSizes.borderRadiusMd,
          padding: const EdgeInsets.all(TSizes.md),
          borderColor: selected ? TColors.primary : TColors.borderSecondary,
          backgroundColor: selected
              ? (dark ? TColors.darkContainer : TColors.accent)
              : (dark ? TColors.dark : TColors.white),
          child: Row(
            children: [
              Icon(icon, size: TSizes.iconMd, color: selected ? TColors.primary : TColors.darkGrey),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: TSizes.xs / 2),
                      Text(description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Iconsax.tick_circle5 : Iconsax.record,
                size: TSizes.iconMd,
                color: selected ? TColors.primary : TColors.borderPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
