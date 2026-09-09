import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

/// Kayıt ekranı.
///
/// 🔴 Kayıt kapısı: sunucu perakende/şirket kaydını ayrı ayrı kapatabiliyor.
/// İkisi de kapalıysa form **hiç çizilmez**, yerine kapalı bloğu gelir.
/// Giriş ekranı bundan etkilenmez — kayıt kapatmak hesap dondurmak değildir;
/// bu ekranın altındaki düğme doğrudan girişe götürür.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final publicSettings = PublicSettingsController.instance;
    // Anahtar uygulama açıldıktan sonra çevrilmiş olabilir; ekran her
    // açılışında yeniden okunuyor (önbellek atlanarak).
    WidgetsBinding.instance.addPostFrameCallback((_) => publicSettings.reload());

    return Scaffold(
      // TASARIM.md §7: kimlik ekranları beyaz zeminde.
      backgroundColor: dark ? TColors.dark : TColors.white,
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
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Giriş ↔ kayıt sekmesi (TASARIM.md §6).
              const TAuthTabs(current: TAuthTab.signup),
              const SizedBox(height: TSizes.spaceBtwSections),

              Obx(
                () => publicSettings.isRegistrationClosed
                    ? const _RegistrationClosedPanel()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

/// "Kayıt geçici olarak kapalıdır" bloğu + girişe dönüş.
class _RegistrationClosedPanel extends StatelessWidget {
  const _RegistrationClosedPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TTexts.registrationClosedTitle.tr, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.spaceBtwSections),

        /// Uyarı kutusu — metin boşsa hiç çizilmiyor (TAuthNotice kuralı).
        TAuthNotice(text: TTexts.registrationClosedText.tr, type: TAuthNoticeType.warning),
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
