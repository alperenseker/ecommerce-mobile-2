/// Genel ödeme modu `transfer_only` iken **kredisiz** müşteriye gösterilen
/// kutu.
///
/// 🔴 Neden ayrı bir widget: o modda sunucu `CanBypassPayment`'ı herkes için
/// true döndürüyor (K29.7 uyum katmanı) ve ona bakan kod bu müşteriyi
/// "kredili müşteri" sanıp [TOrderAccountPanel]'i, yani "sipariş hesabınıza
/// işlenecek / kredi limitiniz" metinlerini gösterirdi. Kredisi olmayan bir
/// müşteriye kredi anlatmak yanlış bilgidir; burada ödemenin neden alınmadığı
/// açıkça yazılıyor. Kredili müşteri (`HasCreditLine`) hesap panelini görmeye
/// devam eder.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class TPaymentModeNote extends StatelessWidget {
  const TPaymentModeNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: TTexts.paymentMethod.tr, showActionButton: false),
        const SizedBox(height: TSizes.spaceBtwItems),
        TRoundedContainer(
          radius: TSizes.borderRadiusMd,
          padding: const EdgeInsets.all(TSizes.md),
          // TASARIM.md: bilgi kutusu `infoSoft` zemin + `info` ikon; eski
          // yarı saydam indigo zemin karanlık temada okunmuyordu.
          backgroundColor: TColors.infoSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Iconsax.bank, color: TColors.info, size: TSizes.iconMd),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TTexts.bankTransferOnlyTitle.tr,
                      style: Theme.of(context).textTheme.titleSmall?.apply(color: TColors.textPrimary),
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      TTexts.bankTransferOnlyNote.tr,
                      style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.darkerGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
