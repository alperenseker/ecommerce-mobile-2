/// Şifre değiştirme formu: mevcut şifre + yeni şifre + tekrar.
///
/// Doğrulama `TValidator.validatePassword` üzerinden yapılıyor: en az 6
/// karakter (sunucunun kuralı) **artı** büyük harf/rakam/özel karakter
/// (istemcinin ek kuralı, referansla aynı — bkz. `utils/validators`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(TTexts.changePassword.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TTexts.changePasswordSubTitle.tr,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              Form(
                key: controller.changePasswordFormKey,
                child: Column(
                  children: [
                    /// -- Mevcut şifre
                    Obx(
                      () => TextFormField(
                        controller: controller.currentPassword,
                        obscureText: controller.hideCurrent.value,
                        validator: (value) => TValidator.validateEmptyText(TTexts.currentPassword.tr, value),
                        decoration: InputDecoration(
                          labelText: TTexts.currentPassword.tr,
                          prefixIcon: const Icon(Iconsax.password_check),
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideCurrent.value = !controller.hideCurrent.value,
                            icon: Icon(controller.hideCurrent.value ? Iconsax.eye_slash : Iconsax.eye),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// -- Yeni şifre
                    Obx(
                      () => TextFormField(
                        controller: controller.newPassword,
                        obscureText: controller.hideNew.value,
                        validator: TValidator.validatePassword,
                        decoration: InputDecoration(
                          labelText: TTexts.newPassword.tr,
                          prefixIcon: const Icon(Iconsax.password_check),
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideNew.value = !controller.hideNew.value,
                            icon: Icon(controller.hideNew.value ? Iconsax.eye_slash : Iconsax.eye),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),

                    /// -- Yeni şifre (tekrar)
                    Obx(
                      () => TextFormField(
                        controller: controller.confirmPassword,
                        obscureText: controller.hideConfirm.value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return TValidator.validateEmptyText(TTexts.confirmPassword.tr, value);
                          }
                          // Eşleşme kontrolü: sunucuya gitmeden burada yakalanır.
                          if (value.trim() != controller.newPassword.text.trim()) {
                            return TTexts.passwordsDoNotMatch.tr;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: TTexts.confirmNewPassword.tr,
                          prefixIcon: const Icon(Iconsax.password_check),
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideConfirm.value = !controller.hideConfirm.value,
                            icon: Icon(controller.hideConfirm.value ? Iconsax.eye_slash : Iconsax.eye),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => controller.changePassword(), child: Text(TTexts.save.tr)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
