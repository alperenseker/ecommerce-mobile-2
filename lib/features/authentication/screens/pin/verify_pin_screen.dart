import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/login_signup/otp_code_field.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/pin_controller.dart';

/// PIN doğrulama ekranı.
///
/// 🔴 Doğrulama **istemcide** yapılıyor (kayıtlı PIN ile karşılaştırma); bu
/// ekranı bir güvenlik kapısı gibi kullanma.
class VerifyPinScreen extends StatelessWidget {
  const VerifyPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PinController controller = Get.put(PinController());
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
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
                  obscure: true,
                  hasError: controller.hasError.value,
                  onChanged: controller.setEnteredOTP,
                  onCompleted: controller.setEnteredOTP,
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

              // PIN'i unuttum — güncelleme akışı telefon OTP'sine bağlı ve o uç
              // sunucuda yok; referansta da yorumda.
              // TextButton(onPressed: () => Get.toNamed(TRoutes.updatePin), child: Text(TTexts.forgetPin.tr)),
              // const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}
