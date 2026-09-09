import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/login_signup/otp_code_field.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/otp_controller.dart';

/// Telefon OTP ekranı (6 hane).
///
/// ⚠️ Telefon doğrulama ucu sunucuda yok; ekran referanstaki gibi duruyor ama
/// bugün çalışmıyor.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OTPController.instance;
    controller.init();

    final dark = THelperFunctions.isDarkMode(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: dark ? TColors.dark : TColors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Display back button
                TRoundedContainer(
                  padding: EdgeInsets.zero,
                  radius: TSizes.borderRadiusMd,
                  backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
                  child: IconButton(
                      onPressed: () => Get.back(result: false), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                ),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// Title
                Center(
                  child: Text(TTexts.enter6digitOTPCode.tr,
                      style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                /// Subtitle
                Text('${TTexts.otpSubTitle.tr} ${THelperFunctions.maskPhoneNumber(controller.phoneNumber.value)}',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// OTP alanı
                TOtpCodeField(
                  length: 6,
                  onChanged: (code) => controller.otp = code,
                  onCompleted: (code) => controller.otp = code,
                ),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// Continue Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.loader.value ? null : () => controller.verifyOTP(),
                      child: Text(controller.loader.value ? 'Verifying...'.tr : TTexts.tContinue.tr),
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// Footer Text
                Center(child: Text(TTexts.otpFooter.tr, style: Theme.of(context).textTheme.titleSmall)),

                /// Sayaç bitmeden "tekrar gönder" tıklanamaz.
                Center(
                  child: Obx(
                    () => RichText(
                      text: TextSpan(
                        text: '',
                        style: Theme.of(context).textTheme.titleSmall,
                        children: [
                          TextSpan(
                            text: TTexts.resendOTP.tr,
                            recognizer: (controller.secondsRemaining.value > 0) ? null : TapGestureRecognizer()
                              ?..onTap = () => controller.resendOTP(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: (controller.secondsRemaining.value > 0) ? TColors.darkGrey : TColors.primary),
                          ),
                          if (controller.secondsRemaining.value > 0)
                            TextSpan(
                              text: " ${TTexts.inText.tr} ${controller.secondsRemaining.value}",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: TColors.darkGrey),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
