import 'package:flutter/material.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets/login_signup/auth_tabs.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

/// Giriş ekranı.
///
/// 🔴 Bu ekran **kayıt kapısından etkilenmez**: kayıt kapatmak hesap dondurmak
/// değildir, giriş her durumda açık kalır.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      // TASARIM.md §7: kimlik ekranları beyaz zeminde.
      backgroundColor: dark ? TColors.dark : TColors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              ///  Header
              const TLoginHeader(),

              /// Giriş ↔ kayıt sekmesi (TASARIM.md §6). Ekranlar ayrı kaldı;
              /// sekme yalnız görünüş.
              const SizedBox(height: TSizes.spaceBtwSections),
              const TAuthTabs(current: TAuthTab.login),

              /// Form
              const TLoginForm(),

              /// Divider
              // TFormDivider(dividerText: TTexts.orSignInWith.capitalize!),
              // const SizedBox(height: TSizes.spaceBtwSections),

              /// Footer
              //const TSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
