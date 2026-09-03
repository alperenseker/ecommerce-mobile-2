/// Telefon numarasıyla giriş ekranı.
///
/// ⚠️ Sunucuda karşılığı yok; karşılama ekranında bu seçenek yorumda. Ekran
/// referansla eşitlik için duruyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/phone_number_controller.dart';
import 'widget/phone_number_field.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = SignInController.instance;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Display back button
              TRoundedContainer(
                padding: EdgeInsets.zero,
                radius: TSizes.borderRadiusMd,
                backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
                child: IconButton(onPressed: () => Get.back(result: false), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
              ),

              const SizedBox(height: TSizes.spaceBtwSections * 2),

              /// -- Display the OTP image
              Lottie.asset(
                TImages.signInAnimation,
                width: THelperFunctions.screenWidth() * 0.875,
                height: THelperFunctions.screenHeight() * 0.4,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              /// -- Title
              Center(child: Text(TTexts.otpVerification.tr, style: Theme.of(context).textTheme.headlineLarge)),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Subtitle
              Center(child: Text(TTexts.signInSubTitle.tr, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge)),

              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Phone number Field
              const TPhoneNumberField(),

              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => controller.loginWithPhoneNumber(), child: Text(TTexts.tContinue.tr)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
