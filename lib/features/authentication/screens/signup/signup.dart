/// Kayıt ekranı: başlık, giriş/kayıt sekmeleri ve kayıt formu.
///
/// 🔴 KAYIT KAPISI (K29.2): kayıt tümüyle kapalıyken form **hiç çizilmez**,
/// yerine "geçici olarak kapalı" bloğu ve girişe dönüş düğmesi gelir. Kapalı
/// olan tek bir kayıt tipi ise seçenek hiç çizilmez — bunu `TSignupForm`
/// yapıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/login_signup/auth_notice.dart';
import '../../../../common/widgets/login_signup/auth_tabs.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/public_settings_controller.dart';
import 'widgets/signup_form.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final publicSettings = PublicSettingsController.instance;
    // Anahtar uygulama açıldıktan sonra çevrilmiş olabilir.
    WidgetsBinding.instance.addPostFrameCallback((_) => publicSettings.reload());

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Back Button
              TRoundedContainer(
                padding: EdgeInsets.zero,
                radius: TSizes.borderRadiusMd,
                backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
                child: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Giriş / Kayıt sekmesi (TASARIM.md §7)
              const TAuthTabs(isLogin: false),

              /// FAZ 34 — K29.2: kayıt tümüyle kapalıyken form **hiç
              /// çizilmez**, yerine kapalı mesajı gösterilir.
              ///
              /// 🔴 Giriş ekranı bundan etkilenmez: kayıt kapatmak hesap
              /// dondurmak değildir (sunucu da `users.isactive`'e dokunmuyor).
              /// Bu ekranın altındaki bağlantı doğrudan girişe götürür.
              Obx(
                () => publicSettings.isRegistrationClosed
                    ? const _RegistrationClosedPanel()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: TSizes.spaceBtwSections),
                          Text(TTexts.signupTitle.tr, style: Theme.of(context).textTheme.headlineMedium),
                          const TSignupForm(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Kayıt geçici olarak kapalıdır" ekranı + girişe dönüş.
class _RegistrationClosedPanel extends StatelessWidget {
  const _RegistrationClosedPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TSizes.spaceBtwSections),
        Text(TTexts.registrationClosedTitle.tr, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.spaceBtwSections),
        TAuthNotice(
          message: TTexts.registrationClosedText.tr,
          tone: TAuthNoticeTone.warning,
          icon: Iconsax.info_circle,
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        /// Giriş her durumda açık.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offAllNamed(TRoutes.logIn),
            child: Text(TTexts.signIn.tr),
          ),
        ),
      ],
    );
  }
}
