/// Ad/soyad değiştirme formu.
///
/// İki ayrı alan var çünkü sunucu adı ve soyadı ayrı tutuyor. (Adres
/// defterindeki tek alanlı "ad soyad" kuralı yalnız adres kaydı için geçerli.)
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/update_name_controller.dart';

class ChangeName extends StatelessWidget {
  const ChangeName({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateNameController());
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(TTexts.changeName.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TTexts.changeNameSubTitle.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            Form(
              key: controller.updateUserNameFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.firstName,
                    validator: (value) => TValidator.validateEmptyText(TTexts.firstName.tr, value),
                    expands: false,
                    decoration: InputDecoration(
                      labelText: TTexts.firstName.tr,
                      prefixIcon: const Icon(Iconsax.user),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.lastName,
                    validator: (value) => TValidator.validateEmptyText(TTexts.lastName.tr, value),
                    expands: false,
                    decoration: InputDecoration(
                      labelText: TTexts.lastName.tr,
                      prefixIcon: const Icon(Iconsax.user),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => controller.updateUserName(), child: Text(TTexts.save.tr)),
            ),
          ],
        ),
      ),
    );
  }
}
