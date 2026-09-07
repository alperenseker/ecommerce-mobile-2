/// Kredili müşteriye (`HasCreditLine`) kart formunun yerine gösterilen panel:
/// kredi limiti dökümü + "sipariş hesabınıza işlenecek, yönetici onaylayacak"
/// notu.
///
/// 🔴 Bu panel **yalnız gerçekten kredi satırı olan** müşteriye çizilir.
/// `CanBypassPayment`'a bakan bir kod `transfer_only` modunda kredisi olmayan
/// herkese "kredi limitiniz" yazardı — yanlış bilgi. Kredisiz müşteri
/// [TPaymentModeNote]'u görür.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_settings_controller.dart';

class TOrderAccountPanel extends StatelessWidget {
  const TOrderAccountPanel({super.key, required this.grandTotal});

  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final settings = UserSettingsController.instance.settings.value;
    final hasCredit = settings.hasCreditLimit;
    final remaining = settings.availableCredit - grandTotal;
    final exceeded = hasCredit && remaining < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: TTexts.payOnAccount.tr, showActionButton: false),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Kredi dökümü — yalnız limit tanımlıysa. Limit 0 ise "0 ₸ limit"
        /// yazmak yanıltıcı olurdu; o durumda kontrol de koşmuyor.
        if (hasCredit)
          TRoundedContainer(
            showBorder: true,
            radius: TSizes.borderRadiusMd,
            padding: const EdgeInsets.all(TSizes.md),
            backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
            child: Column(
              children: [
                _row(context, TTexts.creditLimit.tr, TFormatter.formatCurrency(settings.creditLimit)),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                _row(context, TTexts.usedCredit.tr, TFormatter.formatCurrency(settings.usedCredit)),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                _row(context, TTexts.availableCredit.tr, TFormatter.formatCurrency(settings.availableCredit)),
                const Divider(),
                _row(context, TTexts.thisOrder.tr, TFormatter.formatCurrency(grandTotal)),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                _row(
                  context,
                  TTexts.remainingAfterOrder.tr,
                  TFormatter.formatCurrency(remaining),
                  valueColor: exceeded ? TColors.error : TColors.primary,
                  bold: true,
                ),
              ],
            ),
          ),
        if (hasCredit) const SizedBox(height: TSizes.spaceBtwItems),

        /// Onay / hesaba işleme notu
        TRoundedContainer(
          radius: TSizes.borderRadiusMd,
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: exceeded ? TColors.errorSoft : TColors.infoSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                exceeded ? Iconsax.warning_2 : Iconsax.info_circle,
                color: exceeded ? TColors.error : TColors.info,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Expanded(
                child: Text(
                  exceeded ? TTexts.creditLimitExceededMessage.tr : TTexts.payOnAccountNote.tr,
                  style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.darkerGrey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: (bold ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.bodyMedium)!
              .apply(color: valueColor),
        ),
      ],
    );
  }
}
