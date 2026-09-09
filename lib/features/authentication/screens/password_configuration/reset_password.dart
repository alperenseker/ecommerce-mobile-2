import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/forget_password_controller.dart';

/// Şifremi unuttum — 2. adım: e-postayla gelen kodu doğrula. Kod doğruysa yeni
/// şifre ekranına geçilir.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [IconButton(onPressed: () => Get.offAllNamed(TRoutes.logIn), icon: const Icon(CupertinoIcons.clear))],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(image: const AssetImage(TImages.deliveredEmailIllustration), width: THelperFunctions.screenWidth() * 0.6),
              const SizedBox(height: TSizes.spaceBtwSections),

              Text(TTexts.changeYourPasswordTitle.tr, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(TTexts.changeYourPasswordSubTitle.tr, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// OTP code form
              Form(
                key: controller.otpFormKey,
                child: TextFormField(
                  controller: controller.otpCode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  validator: (value) => TValidator.validateEmptyText(TTexts.verificationCode.tr, value),
                  decoration: InputDecoration(
                    labelText: TTexts.verificationCode.tr,
                    prefixIcon: const Icon(Iconsax.password_check),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Verify
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => controller.verifyOtp(email), child: Text(TTexts.submit.tr)),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Resend code
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => controller.resendPasswordResetEmail(email), child: Text(TTexts.resendEmail.tr)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
