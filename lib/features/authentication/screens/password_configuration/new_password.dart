/// Şifremi unuttum — 3. adım: yeni şifreyi belirle.
///
/// Alanların altındaki canlı kural listesi, yazıldıkça her kuralı yeşile
/// çevirir; kurallar `TValidator.validatePassword` ile **aynı** olmalıdır,
/// yoksa liste yeşil görünürken form reddedilir.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/forget_password_controller.dart';

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return Scaffold(
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
                Text('New Password', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text('Create a new password for your account.',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// New password
                Obx(
                  () => TextFormField(
                    controller: controller.newPassword,
                    obscureText: controller.hidePassword.value,
                    onChanged: (value) => controller.passwordValue.value = value,
                    validator: (value) =>
                        _passwordRulesMet(value ?? '') ? null : 'Password does not meet the requirements',
                    decoration: InputDecoration(
                      labelText: TTexts.newPassword,
                      prefixIcon: const Icon(Iconsax.password_check),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                        icon: Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Confirm password — iki alan eşleşmeli.
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPassword,
                    obscureText: controller.hidePassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirm your password';
                      if (value != controller.newPassword.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Iconsax.password_check),
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
                      _rule(context, 'At least 6 characters', value.length >= 6),
                      _rule(context, 'At least one uppercase letter', value.contains(RegExp(r'[A-Z]'))),
                      _rule(context, 'At least one number', value.contains(RegExp(r'[0-9]'))),
                      _rule(context, 'At least one special character',
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

  /// All four password rules satisfied.
  bool _passwordRulesMet(String v) =>
      v.length >= 6 &&
      v.contains(RegExp(r'[A-Z]')) &&
      v.contains(RegExp(r'[0-9]')) &&
      v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  /// One checklist row — green tick when [met], otherwise a muted circle.
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
