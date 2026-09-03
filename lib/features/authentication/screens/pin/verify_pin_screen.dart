/// PIN doğrulama ekranı. Doğru PIN girilirse ana sayfaya geçilir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/login_signup/otp_code_field.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/pin_controller.dart';

class VerifyPinScreen extends StatelessWidget {
  const VerifyPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PinController controller = Get.put(PinController());
    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        showActions: true,
        showSkipButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: TSizes.defaultSpace * 2),

              /// Image
              Lottie.asset(TImages.pinCodeIllustration, width: 300),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Title
              Text(TTexts.verifyPINCode.tr, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// subTitle
              Text(TTexts.verifyPinCodeMessage.tr,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// PIN alanı
              Obx(
                () => TOtpCodeField(
                  length: 4,
                  hasError: controller.hasError.value,
                  onChanged: (code) => controller.setEnteredOTP(code),
                  onCompleted: (code) => controller.setEnteredOTP(code),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Verify Pin Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      if (await controller.verifyPin()) {
                        Get.offNamed(TRoutes.home);
                      }
                    },
                    child: Text(TTexts.verifyPin.tr)),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Forget Pin
              // TextButton(onPressed: () => Get.toNamed(TRoutes.updatePin), child: Text(TTexts.forgetPin.tr)),
              // const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}
