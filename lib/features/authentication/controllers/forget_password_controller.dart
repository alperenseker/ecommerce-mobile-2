import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../screens/login/login.dart';
import '../screens/password_configuration/new_password.dart';
import '../screens/password_configuration/reset_password.dart';

/// "Şifremi unuttum" akışının üç adımını tek denetleyici yürütür:
/// e-posta → kod → yeni şifre. Adımlar ayrı ekran olduğu için form anahtarları
/// da ayrı; aynı denetleyici `Get.put` ile üçünde de bulunuyor, böylece
/// e-posta ve kod adımlar arasında kaybolmuyor.
class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// OTP step
  final otpCode = TextEditingController();
  GlobalKey<FormState> otpFormKey = GlobalKey<FormState>();

  /// New-password step
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final hidePassword = true.obs;
  GlobalKey<FormState> resetPasswordFormKey = GlobalKey<FormState>();

  /// Yeni şifre alanının canlı kopyası: kural listesi her tuşta yeşile
  /// dönebilsin diye ayrı bir gözlenebilir tutuluyor (TextEditingController
  /// `Obx`'i tetiklemiyor).
  final RxString passwordValue = ''.obs;

  /// Send Reset Password EMail
  sendPasswordResetEmail() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {TFullScreenLoader.stopLoading(); return;}

      // Form Validation
      if (!forgetPasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Send EMail to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email.text.trim());

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      TLoaders.successSnackBar(title: TTexts.emailSent.tr, message: TTexts.emailSentMessage.tr);
      Get.to(() => ResetPasswordScreen(email: email.text.trim()));

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// 1. adım — e-postayla gelen kodu doğrula, sonra yeni şifre ekranına geç.
  Future<void> verifyOtp(String email) async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!otpFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.verifyForgotPasswordOtp(email, otpCode.text.trim());

      TFullScreenLoader.stopLoading();
      // Önceki denemeden kalan şifre metni temizlenmezse sonraki adım dolu
      // açılıyor.
      newPassword.clear();
      confirmPassword.clear();
      passwordValue.value = '';
      Get.to(() => NewPasswordScreen(email: email));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// 2. adım — yeni şifreyi yaz (kod zaten doğrulandı). Başarılıysa kullanıcı
  /// giriş ekranına döner.
  Future<void> resetPassword(String email) async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!resetPasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.resetForgotPassword(email, newPassword.text.trim());

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: TTexts.changeYourPasswordTitle.tr,
        message: TTexts.passwordResetDone.tr,
      );
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  resendPasswordResetEmail(String email) async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {TFullScreenLoader.stopLoading(); return;}

      // Send EMail to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email.trim());

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      TLoaders.successSnackBar(title: TTexts.emailSent.tr, message: TTexts.emailResetPassword.tr);

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }
}
