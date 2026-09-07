/// Kart ödemesi seçiliyken kart formunun YERİNE gösterilen kutu.
///
/// 🔴 Kart bilgisi uygulamada **toplanmaz**: numara, son kullanma ve CVV
/// Halyk ePay'in PCI güvenli sayfasında giriliyor, o sayfa "Siparişi ver"e
/// basınca WebView'de açılıyor. Web'deki `injectEpayNote`'un karşılığıdır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class TEpaySecureNote extends StatelessWidget {
  const TEpaySecureNote({super.key});

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      radius: TSizes.borderRadiusMd,
      padding: const EdgeInsets.all(TSizes.md),
      backgroundColor: TColors.successSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.shield_tick, color: TColors.success, size: TSizes.iconMd),
          const SizedBox(width: TSizes.spaceBtwItems / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TTexts.securePaymentTitle.tr,
                  style: Theme.of(context).textTheme.titleSmall?.apply(color: TColors.textPrimary),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  TTexts.securePaymentNote.tr,
                  style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.darkerGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
