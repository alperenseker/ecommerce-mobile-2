/// Var olan bir adresi güncelleme formu.
///
/// ⚠️ FAZ 09'un dosyası; adres listesi satırındaki kalem düğmesi buraya
/// gittiği için FAZ 07'de erken getirildi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/address_controller.dart';
import '../../models/address_model.dart';

class UpdateAddressScreen extends StatelessWidget {
  const UpdateAddressScreen({super.key, required this.address});

  final AddressModel address;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());
    controller.initUpdateAddressValues(address);
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(TTexts.updateAddress.tr),
        showActions: false,
        showSkipButton: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: controller.addressFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ad soyad — sunucuda ayrık tutuluyor, çeviri controller'da.
                TextFormField(
                  controller: controller.name,
                  validator: (value) => TValidator.validateEmptyText(TTexts.name.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.user), labelText: TTexts.name.tr),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Telefon
                TextFormField(
                  controller: controller.phoneNumber,
                  validator: (value) => TValidator.validateEmptyText(TTexts.phoneNo.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.mobile), labelText: TTexts.phoneNo.tr),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Adres satırı 1 (AddressLine1)
                TextFormField(
                  controller: controller.street,
                  validator: (value) => TValidator.validateEmptyText(TTexts.address.tr, value),
                  minLines: 1,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: TTexts.street.tr,
                    prefixIcon: const Icon(Iconsax.building_31),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Adres satırı 2 (isteğe bağlı)
                TextFormField(
                  controller: controller.addressLine2,
                  minLines: 1,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: TTexts.addressLine2.tr,
                    prefixIcon: const Icon(Iconsax.building_31),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Şehir + posta kodu
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.city,
                        validator: (value) => TValidator.validateEmptyText(TTexts.city.tr, value),
                        expands: false,
                        decoration: InputDecoration(
                          labelText: TTexts.city.tr,
                          prefixIcon: const Icon(Iconsax.building),
                        ),
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwInputFields),
                    Expanded(
                      child: TextFormField(
                        controller: controller.postalCode,
                        validator: (value) => TValidator.validateEmptyText(TTexts.postalCode.tr, value),
                        expands: false,
                        decoration: InputDecoration(
                          labelText: TTexts.postalCode.tr,
                          prefixIcon: const Icon(Iconsax.code),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Ülke
                TextFormField(
                  controller: controller.country,
                  validator: (value) => TValidator.validateEmptyText(TTexts.country.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.global), labelText: TTexts.country.tr),
                ),
                const SizedBox(height: TSizes.defaultSpace),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.updateAddress(address),
                    child: Text(TTexts.save.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
