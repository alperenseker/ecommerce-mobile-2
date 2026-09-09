import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/forget_password_controller.dart';

/// Şifremi unuttum — 3. adım: yeni şifreyi belirle.
///
/// 🔴 Alanların altındaki canlı kural listesi ile `TValidator.validatePassword`
/// **aynı dört kuralı** anlatmak zorunda; biri değişirse öteki de değişsin,
/// yoksa liste yeşile döner ama form reddeder.
class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [IconButton(onPressed: () => Get.offAllNamed(TRoutes.logIn), icon: const Icon(CupertinoIcons.clear))],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: controller.resetPasswordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Password'.tr, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text('Create a new password for your account.'.tr,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// New password
                Obx(
                  () => TextFormField(
                    controller: controller.newPassword,
                    obscureText: controller.hidePassword.value,
                    onChanged: (value) => controller.passwordValue.value = value,
                    validator: (value) =>
                        _passwordRulesMet(value ?? '') ? null : 'Password does not meet the requirements'.tr,
                    decoration: InputDecoration(
                      labelText: TTexts.newPassword.tr,
                      prefixIcon: const Icon(Iconsax.password_check),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                        icon: Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Confirm password — şifre tekrarı eşleşmeli.
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPassword,
                    obscureText: controller.hidePassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirm your password'.tr;
                      if (value != controller.newPassword.text) return 'Passwords do not match'.tr;
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password'.tr,
                      prefixIcon: const Icon(Iconsax.password_check),
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Live requirement checklist
                Obx(() {
                  final value = controller.passwordValue.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rule(context, 'At least 6 characters'.tr, value.length >= 6),
                      _rule(context, 'At least one uppercase letter'.tr, value.contains(RegExp(r'[A-Z]'))),
                      _rule(context, 'At least one number'.tr, value.contains(RegExp(r'[0-9]'))),
                      _rule(context, 'At least one special character'.tr,
                          value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))),
                    ],
                  );
                }),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => controller.resetPassword(email), child: Text(TTexts.submit.tr)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dört şifre kuralının hepsi sağlandı mı.
  bool _passwordRulesMet(String v) =>
      v.length >= 6 &&
      v.contains(RegExp(r'[A-Z]')) &&
      v.contains(RegExp(r'[0-9]')) &&
      v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  /// Tek kural satırı — sağlandıysa yeşil tik, değilse soluk daire.
  Widget _rule(BuildContext context, String text, bool met) {
    final color = met ? TColors.success : TColors.darkGrey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(met ? Iconsax.tick_circle5 : Iconsax.minus_cirlce, size: 18, color: color),
          const SizedBox(width: TSizes.sm),
          Text(text, style: Theme.of(context).textTheme.bodyMedium!.apply(color: color)),
        ],
      ),
    );
  }
}
