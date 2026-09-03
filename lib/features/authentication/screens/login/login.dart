/// Giriş ekranı: başlık, giriş/kayıt sekmeleri ve giriş formu.
///
/// 🔴 Giriş formu **her durumda** açıktır: kayıt kapatmak girişi kapatmak
/// değildir (sunucu da hesapları dondurmuyor). Kayıt kapısı yalnız
/// `SignupScreen`'i etkiler.
library;

import 'package:flutter/material.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets/login_signup/auth_tabs.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              ///  Header
              TLoginHeader(),

              /// Giriş / Kayıt sekmesi (TASARIM.md §7 — web ile aynı geçiş)
              TAuthTabs(isLogin: true),

              /// Form
              TLoginForm(),

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
