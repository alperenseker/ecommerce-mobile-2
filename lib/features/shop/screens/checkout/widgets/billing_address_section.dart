/// Ödeme ekranındaki teslimat / fatura adresi bölümü.
///
/// 🔴 **Şirket hesabında fatura adresi 1C'den gelir ve düzenlenemez**
/// (`GET /company/{iin}` → resmî adres). O yüzden şirket hesabında "değiştir"
/// düğmesi çizilmez, adres kilitli gösterilir ve sunucuya fatura adresi
/// olarak **teslimat adresinin kimliği** gönderilir (web
/// `pages/checkout.js` → `orderBody`: `isCompany ? shipping.id : billing.id`).
/// Bireysel hesapta fatura adresi zorunludur; "teslimatla aynı" seçeneği var.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../personalization/controllers/address_controller.dart';
import '../../../../personalization/models/address_model.dart';

class TAddressSection extends StatelessWidget {
  const TAddressSection({
    super.key,
    required this.isBillingAddress,
    this.isLocked = false,
  });

  final bool isBillingAddress;

  /// Kilitli bölüm: "değiştir" düğmesi çizilmez. Şirket hesabının fatura
  /// adresi için kullanılır — o adres 1C'nin, uygulamadan değiştirilemez.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final addressController = AddressController.instance;

    return Obx(
      () {
        final selected = isBillingAddress
            ? addressController.selectedBillingAddress.value
            : addressController.selectedAddress.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TSectionHeading(
              title: isBillingAddress ? TTexts.billingAddress.tr : TTexts.shippingAddress.tr,
              buttonTitle: TTexts.change.tr,
              showActionButton: !isLocked,
              onPressed: () => addressController.selectNewAddressPopup(
                context: context,
                isBillingAddress: isBillingAddress,
              ),
            ),

            // Kilitli fatura adresinin NEDEN değiştirilemediği yazılmazsa
            // müşteri düğmeyi arar; sebebi burada söyleniyor.
            if (isLocked) ...[
              const SizedBox(height: TSizes.xs),
              Row(
                children: [
                  const Icon(Iconsax.lock, size: TSizes.iconXs, color: TColors.darkGrey),
                  const SizedBox(width: TSizes.xs),
                  Expanded(
                    child: Text(
                      TTexts.billingAddressLocked.tr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],

            selected.id.isNotEmpty
                ? _buildAddressDetails(context, selected)
                : Text(TTexts.selectAddress.tr, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
      },
    );
  }

  /// Seçili adresin ayrıntıları.
  Widget _buildAddressDetails(BuildContext context, AddressModel selectedAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Text(selectedAddress.name, style: Theme.of(context).textTheme.bodyLarge),
        // Telefon yoksa satır HİÇ çizilmez: 1C fatura adresinde telefon boş
        // geliyor ve ekranda tek başına bir ahize ikonu kalıyordu.
        if (selectedAddress.formattedPhoneNo.trim().isNotEmpty) ...[
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Row(
            children: [
              const Icon(Iconsax.call, color: TColors.darkGrey, size: TSizes.iconXs),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Text(selectedAddress.formattedPhoneNo, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Iconsax.location, color: TColors.darkGrey, size: TSizes.iconXs),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
            Expanded(
              child: Text(
                selectedAddress.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
