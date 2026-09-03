/// Karşılama ekranı — girişsiz kullanıcının gördüğü ilk ekran.
///
/// Yalnız **e-posta/şifre** ile giriş sunuluyor: telefon ve Google girişleri
/// sunucuda karşılığı olmadığı için referansta da yorumda bırakılmış, aynen
/// korundu.
library;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();

    return Scaffold(
      appBar: AppBar(
        // Karşılamada başlık bandı görünmez: ekranın kendi zeminiyle akıyor.
        backgroundColor: Colors.transparent,
        shape: const Border(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.spaceBtwSections),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              /// -- Lottie Animation (Header)
              BounceInDown(
                duration: const Duration(milliseconds: 800),
                child: Lottie.asset(
                  repeat: true,
                  width: screenWidth * 0.6,
                  'assets/images/animations/Animation - 1745236705111.json',
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Title
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Welcome to Fores Store',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),

              /// -- Subtitle
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Text(
                  TTexts.shopSmartBetter.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Login Buttons Card
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    children: [
                      /// -- Email Login
                      SizedBox(
                        width: screenWidth * 0.8,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email_outlined, size: TSizes.iconMd, color: TColors.textWhite),
                          onPressed: () => Get.toNamed(TRoutes.logIn, arguments: 'EmailPassword'),
                          label: Text(TTexts.loginWithEmailPass.tr),
                        ),
                      ),
                      // -- Phone & Google login temporarily disabled; only
                      // email/password is offered for now.
                      // const SizedBox(height: TSizes.spaceBtwItems),
                      //
                      // /// -- Phone Login (Larger icon)
                      // SizedBox(
                      //   width: screenWidth * 0.8,
                      //   child: OutlinedButton.icon(
                      //     icon: const Icon(Icons.phone_android, size: TSizes.iconMd),
                      //     onPressed: () => Get.toNamed(TRoutes.phoneSignIn),
                      //     label: Text(TTexts.loginWithPhoneNo.tr),
                      //   ),
                      // ),
                      // const SizedBox(height: TSizes.spaceBtwItems),
                      //
                      // /// -- Google Sign-In Button (Larger icon)
                      // SizedBox(
                      //   width: screenWidth * 0.8,
                      //   child: OutlinedButton.icon(
                      //     icon: Image.asset(TImages.google, width: 28, height: 28),
                      //     onPressed: () => controller.googleSignIn(),
                      //     label: Text(TTexts.signInWithGoogle.tr),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Footer
              FadeInUp(
                delay: const Duration(milliseconds: 1100),
                child: RichText(
                  text: TextSpan(
                    text: TTexts.haveAnAccount.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: TColors.textSecondary),
                    children: [
                      TextSpan(
                        text: TTexts.signUp.tr,
                        recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(TRoutes.signup),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: TColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
