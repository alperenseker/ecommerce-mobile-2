/// Yeni adres ekleme formu.
///
/// ⚠️ FAZ 09'un dosyası; adresi olmayan müşteri ödeme ekranından çıkamayacağı
/// için FAZ 07'de erken getirildi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/address_controller.dart';

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(TTexts.addNewAddress.tr),
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
                TextFormField(
                  controller: controller.name,
                  validator: (value) => TValidator.validateEmptyText(TTexts.name.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.user), labelText: TTexts.name.tr),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                TextFormField(
                  controller: controller.phoneNumber,
                  validator: (value) => TValidator.validateEmptyText(TTexts.phoneNo.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.mobile), labelText: TTexts.phoneNo.tr),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.street,
                        validator: (value) => TValidator.validateEmptyText(TTexts.street.tr, value),
                        expands: false,
                        decoration: InputDecoration(
                          labelText: TTexts.street.tr,
                          prefixIcon: const Icon(Iconsax.building_31),
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
                        controller: controller.state,
                        expands: false,
                        decoration: InputDecoration(
                          labelText: TTexts.state.tr,
                          prefixIcon: const Icon(Iconsax.activity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                TextFormField(
                  controller: controller.country,
                  validator: (value) => TValidator.validateEmptyText(TTexts.country.tr, value),
                  decoration: InputDecoration(prefixIcon: const Icon(Iconsax.global), labelText: TTexts.country.tr),
                ),
                const SizedBox(height: TSizes.defaultSpace),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.addNewAddresses(),
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
