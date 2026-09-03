/// Oturum durumunun tek kaynağı: jeton, kullanıcı kimliği, misafir modu ve
/// açılışta hangi ekrana gidileceği kararı.
///
/// Jeton `GetStorage`'da tutulur ve `THttpClient`'ın auth interceptor'ı her
/// istekte buradan okur — böylece giriş/çıkış anında yeniden yapılandırma
/// gerekmez.
library;

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_model.dart';

import '../../../features/authentication/screens/onboarding/onboarding.dart';
import '../../../features/authentication/screens/welcome/welcome_screen.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../features/personalization/controllers/user_settings_controller.dart';
import '../../../home_menu.dart';
import '../../../routes/routes.dart';
import '../../../features/authentication/models/company_model.dart';
import '../../../utils/exceptions/registration_closed_exception.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../../../utils/popups/dialogs.dart';
import 'api_auth.dart';
import 'package:iconsax/iconsax.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();

  // Custom API Authentication Variables
  var customAuthToken = ''.obs;
  var customUserId = ''.obs;
  var isCustomAuthUser = false.obs;

  /// Getters
  String get getUserID => customUserId.value;

  bool get isUserLoggedIn => isCustomAuthUser.value && customAuthToken.value.isNotEmpty;

  bool get isGuestUser => deviceStorage.read('isGuestMode') ?? true;

  String get authToken => customAuthToken.value;

  /// Called from main.dart on app launch
  @override
  void onReady() {
    // Custom auth token'ı storage'dan oku
    customAuthToken.value = deviceStorage.read('customAuthToken') ?? '';
    customUserId.value = deviceStorage.read('customUserId') ?? '';
    isCustomAuthUser.value = deviceStorage.read('isCustomAuthUser') ?? false;

    FlutterNativeSplash.remove();
    screenRedirect();
  }

  /// Function to Show Relevant Screen
  screenRedirect() async {
    // Check if user is logged in via Custom API
    if (isCustomAuthUser.value && customAuthToken.value.isNotEmpty) {
      await deviceStorage.write('isGuestMode', false);

      // Kullanıcı kaydını çek
      await UserController.instance.fetchUserRecord();

      // Yöneticinin belirlediği ticari ayarlar (stoksuz sipariş, kredi
      // limiti, fiyat kategorisi). `await` güvenli: hata olursa kısıtlayıcı
      // varsayılanlara düşülür, giriş bozulmaz.
      if (Get.isRegistered<UserSettingsController>()) {
        await UserSettingsController.instance.fetchUserSettings();
      }

      // Initialize User Specific Storage
      await TLocalStorage.init(customUserId.value);
      Get.offAll(() => const HomeMenu());
      return;
    }

    // User is not logged in. Check if they chose guest mode.
    if (isGuestUser) {
      // User is in Guest Mode, navigate to HomeMenu
      Get.offAll(() => const HomeMenu());
    } else {
      // User is not logged in and not a guest.
      // This is for new users or users who have logged out and not chosen guest mode.
      deviceStorage.writeIfNull('isFirstTime', true);
      // If it's their first time, show OnBoarding, otherwise WelcomeScreen.
      bool isFirstTime = deviceStorage.read('isFirstTime') ?? true;
      if (isFirstTime) {
        Get.offAll(() => const OnBoardingScreen());
      } else {
        Get.offAll(() => const WelcomeScreen());
      }
    }
  }

  /* ---------------------------- Custom API Email & Password sign-in ---------------------------------*/

  /// [CustomAPIAuthentication] - SignIn
  Future<Map<String, dynamic>> loginWithEmailAndPassword(String email, String password) async {
    try {
      final response = await ApiAuth.loginWithEmailPassword(
        email: email,
        password: password,
      );

      if (response['success'] == true && response['token'] != null) {
        // Save token and user info to storage
        customAuthToken.value = response['token'];
        customUserId.value = response['user']['userId'];
        isCustomAuthUser.value = true;

        await deviceStorage.write('customAuthToken', customAuthToken.value);
        await deviceStorage.write('customUserId', customUserId.value);
        await deviceStorage.write('isCustomAuthUser', true);
        await deviceStorage.write('isGuestMode', false);

        // Save user data to local storage for UserController
        await deviceStorage.write('userData', response['user']);

        return response;
      } else {
        throw response['message'] ?? 'Login failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// [CustomAPIAuthentication] - REGISTER
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await ApiAuth.registerWithEmailPassword(
        name: name,
        surname: surname,
        email: email,
        password: password,
        phone: phone,
      );

      if (response['success'] == true) {
        // Kayıt başarılı, şimdi otomatik login yap
        if (response['token'] != null) {
          // Token varsa direkt login olmuş sayıyoruz
          customAuthToken.value = response['token'];
          customUserId.value = response['user']['userId'];
          isCustomAuthUser.value = true;

          await deviceStorage.write('customAuthToken', customAuthToken.value);
          await deviceStorage.write('customUserId', customUserId.value);
          await deviceStorage.write('isCustomAuthUser', true);
          await deviceStorage.write('isGuestMode', false);
          await deviceStorage.write('userData', response['user']);
        }

        return response;
      } else {
        throw response['message'] ?? 'Registration failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /* ---------------------------- Company / OTP registration flow ---------------------------------*/

  /// [Registration] - Pre-register to obtain a temporary token, which authorizes
  /// the subsequent company registry lookup. Returns the temp token.
  Future<String> preRegister({required String email, String accountType = 'company'}) async {
    final res = await ApiAuth.preRegister(email: email, accountType: accountType);
    if (res['success'] != true) {
      _throwIfRegistrationClosed(res);
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'Pre-registration failed';
    }
    return (res['tempToken'] ?? '').toString();
  }

  /// [Registration] - Look up official company info by IIN/BIN. Returns null when
  /// the company is not in the registry (caller falls back to manual entry).
  Future<CompanyModel?> getCompanyByIin(String iin, {String? tempToken}) async {
    final res = await ApiAuth.getCompanyByIin(iin, tempToken: tempToken);
    if (res['success'] == true && res['data'] != null && res['data'] is Map) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    return null;
  }

  /// [Registration] - Send the registration OTP to the email.
  ///
  /// FAZ 34 — [accountType] gönderilirse sunucu **o kayıt tipinin** anahtarına
  /// bakar (Faz 29 kapısı); gönderilmezse yalnız "ikisi de kapalı" durumunda
  /// reddeder.
  Future<void> sendRegistrationOtp(String email, {String? accountType}) async {
    final res = await ApiAuth.sendRegistrationOtp(contact: email, accountType: accountType);
    if (res['success'] != true) {
      _throwIfRegistrationClosed(res);
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'OTP could not be sent';
    }
  }

  /// [Registration] - Create the account (no auto-login). Returns the new userId.
  Future<String> registerAccount({
    required String name,
    required String surname,
    required String email,
    required String password,
    required String phone,
    String accountType = 'retail',
    String iin = '',
  }) async {
    final res = await ApiAuth.registerWithEmailPassword(
      name: name,
      surname: surname,
      email: email,
      password: password,
      phone: phone,
      accountType: accountType,
      iin: iin,
    );
    if (res['success'] != true) {
      _throwIfRegistrationClosed(res);
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'Registration failed';
    }
    return (res['userId'] ?? '').toString();
  }

  /// FAZ 34 — kayıt kapısının (Faz 29) 403 yanıtını **tipli** hataya çevirir.
  ///
  /// Üç kayıt ucu da aynı gövdeyi döndürüyor (`errorCode` + `message`). Kodu
  /// düz metin hata mesajının içinde kaybetmek yerine burada yakalıyoruz:
  /// ekran, hangi kayıt tipinin kapandığını bilmeden K29.2'nin "kapalı bölüm
  /// hiç görünmesin" kuralını uygulayamaz.
  void _throwIfRegistrationClosed(Map<String, dynamic> res) {
    final code = (res['errorCode'] ?? '').toString();
    if (code.isEmpty || !code.startsWith('registration_disabled')) return;
    final message = (res['message'] ?? '').toString();
    throw TRegistrationClosedException(code, message);
  }

  /// [ChangePassword] - Change the password for the logged-in user.
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final res = await ApiAuth.changePassword(
      userId: getUserID,
      oldPassword: oldPassword,
      newPassword: newPassword,
      token: authToken,
    );
    if (res['success'] != true) {
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'Failed to change password';
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User (for custom API users)
  Future<void> reAuthenticateWithEmailAndPassword(String email, String password) async {
    final response = await ApiAuth.loginWithEmailPassword(
      email: email,
      password: password,
    );

    if (response['success'] != true) {
      throw 'Re-authentication failed';
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    final success = await ApiAuth.sendEmailVerification(customAuthToken.value);
    if (!success) {
      throw 'Failed to send verification email';
    }
  }

  /// [EmailAuthentication] - FORGET PASSWORD - send the OTP code to the email.
  Future<void> sendPasswordResetEmail(String email) async {
    final success = await ApiAuth.sendPasswordResetEmail(email);
    if (!success) {
      throw 'Failed to send password reset email';
    }
  }

  /// [ForgetPassword] - Verify the OTP code emailed to the user.
  Future<void> verifyForgotPasswordOtp(String email, String code) async {
    final res = await ApiAuth.verifyForgotPasswordOtp(email: email, code: code);
    if (res['success'] != true) {
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'Invalid or expired code';
    }
  }

  /// [ForgetPassword] - Set the new password (after the OTP was verified).
  Future<void> resetForgotPassword(String email, String newPassword) async {
    final res = await ApiAuth.resetForgotPassword(email: email, newPassword: newPassword);
    if (res['success'] != true) {
      throw (res['message']?.toString().isNotEmpty == true) ? res['message'].toString() : 'Failed to reset password';
    }
  }

  /* ---------------------------- Phone Number sign-in ---------------------------------*/

  /// [PhoneAuthentication] - LOGIN - Register
  ///
  /// TODO: backend OTP endpoint'i eklenince burayı doldur. Şu an için bu
  /// özellik backend tarafında desteklenmiyor.
  Future<void> loginWithPhoneNo(String phoneNumber) async {
    throw 'Telefon ile giriş backend tarafında henüz desteklenmiyor.';
  }

  /// [PhoneAuthentication] - VERIFY PHONE NO BY OTP
  ///
  /// TODO: backend OTP endpoint'i eklenince burayı doldur.
  Future<bool> verifyOTP(String otp, String phoneNumber) async {
    throw 'Telefon ile giriş backend tarafında henüz desteklenmiyor.';
  }

  /* ---------------------------- ./end Federated identity & social sign-in ---------------------------------*/

  /// [LogoutUser]
  Future<void> logout() async {
    try {
      // Custom auth verilerini temizle
      customAuthToken.value = '';
      customUserId.value = '';
      isCustomAuthUser.value = false;
      await deviceStorage.remove('customAuthToken');
      await deviceStorage.remove('customUserId');
      await deviceStorage.remove('isCustomAuthUser');
      await deviceStorage.remove('userData');

      // Controller'lardaki kullanıcı durumunu da sıfırla
      UserController.instance.user.value = UserModel.empty();
      if (Get.isRegistered<UserSettingsController>()) {
        UserSettingsController.instance.clear();
      }
      await deviceStorage.write('isGuestMode', true);
      await deviceStorage.write('isFirstTime', false);
      screenRedirect();
    } catch (e) {
      throw e.toString();
    }
  }

  /// DELETE USER - Remove user account.
  Future<void> deleteAccount() async {
    // Custom API kullanıcısı için hesap silme
    // TODO: API'nizde delete endpoint'i varsa burada çağırın
    // await ApiService.deleteAccount(customAuthToken.value);

    // Local storage'ı temizle
    await deviceStorage.remove('customAuthToken');
    await deviceStorage.remove('customUserId');
    await deviceStorage.remove('isCustomAuthUser');
    await deviceStorage.remove('userData');
  }

  /// Show a reusable "Sign In Required" popup for guest users.
  /// [message] can be customized based on the action (default provided).
  void showSignInRequiredPopup({String? message}) {
    TDialogs.confirm(
      title: 'Sign In Required'.tr,
      message: message ?? 'You need to sign in to continue using this feature.'.tr,
      icon: Iconsax.login,
      confirmText: 'Sign In'.tr,
      barrierDismissible: false,
      onConfirm: () => Get.toNamed(TRoutes.welcome),
    );
  }
}
