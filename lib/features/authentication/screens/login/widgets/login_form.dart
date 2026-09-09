import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../controllers/login_in_controller.dart';

/// Giriş formu: e-posta + şifre, "beni hatırla" ve şifremi unuttum.
class TLoginForm extends StatelessWidget {
  const TLoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Form(
      key: controller.loginFormKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
        child: Column(
          children: [
            /// Email
            TextFormField(
              controller: controller.email,
              validator: TValidator.validateEmail,
              decoration: InputDecoration(prefixIcon: const Icon(Iconsax.direct_right), labelText: TTexts.email.tr),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            /// Password
            Obx(
              () => TextFormField(
                obscureText: controller.hidePassword.value,
                controller: controller.password,
                validator: (value) => TValidator.validateEmptyText(TTexts.password.tr, value),
                decoration: InputDecoration(
                  labelText: TTexts.password.tr,
                  prefixIcon: const Icon(Iconsax.password_check),
                  suffixIcon: IconButton(
                    onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                    icon: Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields / 2),

            /// Remember Me & Forget Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Remember Me
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => Checkbox(
                        value: controller.rememberMe.value, onChanged: (value) => controller.rememberMe.value = value!)),
                     Text(TTexts.rememberMe.tr),
                  ],
                ),

                /// Forget Password
                TextButton(onPressed: () => Get.toNamed(TRoutes.forgetPassword), child: Text(TTexts.forgetPassword.tr)),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => controller.emailAndPasswordSignIn(), child: Text(TTexts.signIn.tr)),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            /// Create Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () => Get.toNamed(TRoutes.signup), child: Text(TTexts.createAccount.tr)),
            ),
          ],
        ),
      ),
    );
  }
}
