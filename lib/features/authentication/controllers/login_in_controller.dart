import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../personalization/controllers/user_settings_controller.dart';

/// Giriş ekranının denetleyicisi.
///
/// Girişten sonraki sıra bilinçli: önce jeton alınır, sonra bildirim jetonu
/// yazılır, sonra kullanıcı kaydı ve **ticari yetkiler** (`usersettings`)
/// yüklenir. Yetki çağrısı ayrı bir `try` içinde: 🔴 yetkiler alınamasa bile
/// giriş bozulmaz, en kısıtlayıcı varsayılana düşülür.
class LoginController extends GetxController {
  static LoginController get instance => Get.isRegistered() ? Get.find() : Get.put(LoginController());

  /// Variables
  final hidePassword = true.obs;
  final rememberMe = false.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
  }

  /// -- Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(TTexts.loggingYouIn.tr, TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.customToast(message: TTexts.noInternetAccess.tr);
        return;
      }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Save Data if Remember Me is selected
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      // Login user using EMail & Password Authentication
      await AuthenticationRepository.instance.loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      final token = await TNotificationService.getToken();
      final userController = Get.put(UserController());
      await userController.updateUserRecordWithToken(token);
      // Assign user data to RxUser of UserController to use in app
      await userController.fetchUserRecord();

      // 🔴 Yönetici yetkileri (`CanBypassPayment`, `CanOrderWithoutStock`,
      // `PriceCategory`). Ayrı `try` içinde: bu çağrı düşerse giriş yine de
      // tamamlanır, denetleyici en kısıtlayıcı varsayılanda kalır.
      try {
        if (Get.isRegistered<UserSettingsController>()) {
          await UserSettingsController.instance.fetchUserSettings();
        } else {
          await Get.put(UserSettingsController()).fetchUserSettings();
        }
      } catch (_) {}

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      await AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

}
