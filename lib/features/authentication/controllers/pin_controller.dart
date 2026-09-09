import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';

/// PIN ekranlarının denetleyicisi (kur / doğrula / güncelle).
///
/// 🔴 PIN **yalnız istemcide** doğrulanıyor: `UserController.user.value.pin`
/// ile karşılaştırılıyor ve sunucuya yazılmıyor
/// (`updateUserRecordWithPin` içindeki TODO). Yani PIN bir kolaylık, güvenlik
/// katmanı değil — para/veri koruyan bir kararı PIN'e dayandırma.
///
/// ⚠️ [updatePin] telefon OTP'sine bağlı; o uç sunucuda olmadığı için
/// güncelleme ekranı bugün çalışmıyor.
class PinController extends GetxController {
  var enteredOTP = ''.obs;
  var hasError = false.obs;

  void setEnteredOTP(String value) {
    enteredOTP.value = value;
  }

  /// Add new Pin
  setNewPin() async {
    try {
      if (enteredOTP.value.isEmpty || enteredOTP.value.length < 4) {
        hasError.value = true;
        TLoaders.errorSnackBar(title: TTexts.invalidPin.tr, message: TTexts.pinCharacters.tr);
        return;
      }

      hasError.value = false;

      // Start Loading
      TFullScreenLoader.openLoadingDialog(TTexts.storingPin.tr, TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final userController = UserController.instance;
      await userController.updateUserRecordWithPin(enteredOTP.value);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(title: TTexts.congratulations.tr, message: TTexts.pinCodeSuccessMessage.tr);

      // Move to Referral Screen
      // Get.toNamed(TRoutes.navigation);
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: e.toString());
    }
  }

  /// Method to Update Pin Code
  updatePin() async {
    try {
      if (enteredOTP.value.isEmpty || enteredOTP.value.length < 4) {
        hasError.value = true;
        TLoaders.errorSnackBar(title: TTexts.invalidPin.tr, message: TTexts.pinCharacters.tr);
        return;
      }

      hasError.value = false;

      // Start Loading
      TFullScreenLoader.openLoadingDialog(TTexts.updatingPin.tr, TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final userController = UserController.instance;

      // Trigger the OTP resend logic
      await AuthenticationRepository.instance.loginWithPhoneNo(userController.user.value.phoneNumber);

      // Redirect to OTP screen for verification
      bool otpVerified = await Get.toNamed(
        TRoutes.otpVerification,
        parameters: {
          'phoneNumberWithCountryCode': userController.user.value.phoneNumber,
          'phoneNumber': userController.user.value.phoneNumber,
        },
      );

      if (otpVerified) {
        // Update User Record with new Pin
        await userController.updateUserRecordWithPin(enteredOTP.value);

        // Remove Loader
        TFullScreenLoader.stopLoading();

        // Show Success Message
        TLoaders.successSnackBar(title: TTexts.congratulations.tr, message: TTexts.pinCodeSuccessMessage.tr);

        // Move Back
        Get.back();
      } else {
        // Stop loading dialog
        TFullScreenLoader.stopLoading();
        return;
      }
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: e.toString());
    }
  }

  /// Method to Update Pin Code
  Future<bool> verifyPin() async {
    try {
      if (enteredOTP.value.isEmpty || enteredOTP.value.length < 4) {
        hasError.value = true;
        TLoaders.errorSnackBar(title: TTexts.invalidPin.tr, message: TTexts.pinCharacters);
        return false;
      }

      hasError.value = false;

      // Start Loading
      TFullScreenLoader.popUpCircular();

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return false;
      }

      final userController = UserController.instance;
      if (userController.user.value.pin != enteredOTP.value) {
        hasError.value = true;
        TLoaders.errorSnackBar(title: TTexts.invalidPin.tr, message: TTexts.inValidPinMessage.tr);
        TFullScreenLoader.stopLoading();
        return false;
      }

      // Remove Loader
      TFullScreenLoader.stopLoading();

      return true;
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: e.toString());
      return false;
    }
  }
}
