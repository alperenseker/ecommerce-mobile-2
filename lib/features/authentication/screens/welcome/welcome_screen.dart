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

/// Oturumu olmayan (ve tanıtımı görmüş) kullanıcının karşılama ekranı.
///
/// ⚠️ Temiz kurulumda burası **görünmez**: `isGuestUser` varsayılanı `true`
/// olduğu için açılış doğrudan ana menüye gidiyor; bu ekran ancak çıkış
/// yapıldıktan sonra çıkıyor. Referansta da aynen böyle.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final screenWidth = THelperFunctions.screenWidth();

    return Scaffold(
      // TASARIM.md §7: kimlik ekranları beyaz zeminde; sayfa zemini
      // (`TColors.light`) burada kullanılmıyor ki form kartı gibi okunmasın.
      backgroundColor: dark ? TColors.dark : TColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dark ? TColors.light : TColors.dark),
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
                  TTexts.welcomeToStore.tr,
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
                      // -- Telefon ve Google girişi referansta da yorumda:
                      // telefon OTP ucu sunucuda yok, Google ise bu projede
                      // hiç kurulmadı (Firebase yok).
                      // const SizedBox(height: TSizes.spaceBtwItems),
                      //
                      // /// -- Phone Login
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
                      // /// -- Google Sign-In Button
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
