/// E-posta doğrulama ekranının controller'ı.
///
/// Doğrulama bağlantısı gönderilir ve profil ucu 3 saniyede bir yoklanarak
/// `isEmailVerified` bayrağı beklenir; doğrulanınca başarı ekranına geçilir.
///
/// ⚠️ Buradaki `ApiAuth`, `api_authentication_repository.dart` içindeki
/// **`package:http` sürümüdür** (profil ucu yalnız orada var). Aynı adı
/// taşıyan `api_auth.dart` ile aynı dosyaya import edilmemeli.
library;

import 'dart:async';

import 'package:get/get.dart';

import '../../../common/widgets/success_screen/success_screen.dart';
import '../../../data/repositories/authentication/api_authentication_repository.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  Timer? _autoRedirectTimer;

  @override
  void onInit() {
    /// Send Email Whenever Verify Screen appears & Set Timer for auto redirect.
    sendEmailVerification();
    setTimerForAutoRedirect();

    super.onInit();
  }

  /// Send Email Verification link
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      TLoaders.successSnackBar(title: TTexts.emailSent.tr, message:  TTexts.emailCheckVerify.tr);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// Timer to automatically redirect on Email Verification
  setTimerForAutoRedirect() {
    _autoRedirectTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        final isVerified = await _isEmailVerified();
        if (isVerified) {
          timer.cancel();
          Get.off(
            () => SuccessScreen(
              image: TImages.successfullyRegisterAnimation,
              title: TTexts.yourAccountCreatedTitle.tr,
              subTitle: TTexts.yourAccountCreatedSubTitle,
              onPressed: () => AuthenticationRepository.instance.screenRedirect(),
            ),
          );
        }
      },
    );
  }

  /// Polls the backend user profile to check the verification flag.
  Future<bool> _isEmailVerified() async {
    try {
      final token = AuthenticationRepository.instance.customAuthToken.value;
      if (token.isEmpty) return false;
      final profile = await ApiAuth.getUserProfile(token);
      return profile['user']?['isEmailVerified'] ?? profile['isEmailVerified'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Manually Check if Email Verified
  checkEmailVerificationStatus() async {
    if (await _isEmailVerified()) {
      Get.off(
        () => SuccessScreen(
          image: TImages.successfullyRegisterAnimation,
          title: TTexts.yourAccountCreatedTitle.tr,
          subTitle: TTexts.yourAccountCreatedSubTitle,
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    }
  }

  @override
  void onClose() {
    _autoRedirectTimer?.cancel();
    super.onClose();
  }


}
