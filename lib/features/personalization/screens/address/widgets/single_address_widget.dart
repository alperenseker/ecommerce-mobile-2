/// Adres listesindeki tek satır: seçili hâli işaretler, kalem düğmesi
/// güncelleme ekranını açar.
///
/// ⚠️ FAZ 09'un dosyası; ödeme ekranındaki adres seçme alt sayfası onsuz
/// çalışamadığı için FAZ 07'de erken getirildi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/address_controller.dart';
import '../../../models/address_model.dart';
import '../update_address.dart';

class TSingleAddress extends StatelessWidget {
  const TSingleAddress({
    super.key,
    required this.address,
    required this.onTap,
    required this.isBillingAddress,
  });

  final AddressModel address;
  final VoidCallback onTap;
  final bool isBillingAddress;

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    return Obx(
      () {
        final selectedAddressId =
            isBillingAddress ? controller.selectedBillingAddress.value.id : controller.selectedAddress.value.id;
        final isAddressSelected = selectedAddressId == address.id;

        return GestureDetector(
          onTap: onTap,
          child: TRoundedContainer(
            showBorder: true,
            radius: TSizes.borderRadiusMd,
            padding: const EdgeInsets.all(TSizes.md),
            width: double.infinity,
            // TASARIM.md §6: seçili hâl `accent` zemin + indigo çerçeve.
            backgroundColor: isAddressSelected
                ? (dark ? TColors.darkContainer : TColors.accent)
                : (dark ? TColors.dark : TColors.white),
            borderColor: isAddressSelected ? TColors.primary : TColors.borderSecondary,
            margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAddressSelected ? Iconsax.tick_circle5 : Iconsax.record,
                  color: isAddressSelected ? TColors.primary : TColors.borderPrimary,
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: TSizes.xs),
                      Text(address.formattedPhoneNo, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: TSizes.xs),
                      Text(address.toString(), softWrap: true, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems / 2),
                TCircularIcon(
                  backgroundColor: Colors.transparent,
                  width: 36,
                  height: 36,
                  size: TSizes.iconSm,
                  color: TColors.darkGrey,
                  icon: Iconsax.edit,
                  onPressed: () => Get.to(() => UpdateAddressScreen(address: address)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
