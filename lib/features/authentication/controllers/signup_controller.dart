/// Kayıt akışının controller'ı — iki ayrı akış yürütür:
///
///   BİREYSEL : OTP gönder → doğrula → `Auth/register`
///   ŞİRKET   : `Auth/pre-register` (geçici jeton) → `company/{iin}` →
///              şirket doğru mu penceresi → OTP → kayıt
///              (şirket 1C'de yoksa bilgiler elle girilir)
///
/// 🔴 KAYIT KAPISI: sunucu perakende/şirket kaydını ayrı ayrı kapatabilir.
/// Kapalı seçenek ekrana **hiç çizilmez**; hata göstermek yerine o bölüm yok
/// sayılır. Giriş formu her durumda açık kalır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../features/personalization/controllers/public_settings_controller.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/registration_closed_exception.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../screens/login/login.dart';
import '../screens/signup/register_otp_screen.dart';
import '../screens/signup/widgets/company_dialogs.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs;
  final privacyPolicy = true.obs;
  final email = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final phoneNumber = TextEditingController();
  final iin = TextEditingController();
  final selectedCountryCode = RxString('+44');

  /// 'retail' (individual) or 'company'. Drives the conditional UI (name vs IIN)
  /// and which sign-up flow runs.
  final accountType = 'retail'.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// Ekranın ve kayıt akışının kullandığı **etkin** hesap tipi.
  ///
  /// FAZ 34 — kapalı bir kayıt tipi seçili kalırsa müşteri formu doldurup
  /// 403 yer. Açık olan tek tip varsa seçim ona çekilir.
  ///
  /// 🔴 Bu bir **türetilmiş değer**, bir yan etki değil: [accountType]'a
  /// yazan bir dinleyici (`ever`) kurulmadı. Dinleyici, anahtarın okunması
  /// ile kullanıcının "Hesap Oluştur"a basması arasında yarışa girebilirdi;
  /// türetilmiş değerde böyle bir aralık yok — kapalı bir hesap tipi
  /// sunucuya **hiçbir zaman** gönderilemez.
  String get effectiveAccountType {
    if (!retailRegistrationEnabled && companyRegistrationEnabled) return 'company';
    if (!companyRegistrationEnabled && retailRegistrationEnabled) return 'retail';
    return accountType.value;
  }

  bool get isCompany => effectiveAccountType == 'company';

  AuthenticationRepository get _repo => AuthenticationRepository.instance;

  PublicSettingsController get _publicSettings => PublicSettingsController.instance;

  /// FAZ 34 — hangi kayıt tipleri açık (K29.2). Ekran bunlara bakarak
  /// kapalı bölümü **hiç çizmez**; sunucudaki 403 yine de tek gerçek kapıdır.
  bool get retailRegistrationEnabled => _publicSettings.retailRegistrationEnabled;
  bool get companyRegistrationEnabled => _publicSettings.companyRegistrationEnabled;

  /// Tek seçenek kaldıysa hesap tipi seçicisi tümden gizlenir.
  bool get showAccountTypeSelector => retailRegistrationEnabled && companyRegistrationEnabled;

  /// -- SIGNUP entry point. Validates shared inputs then dispatches to the
  /// retail or company flow.
  Future<void> signup() async {
    try {
      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.customToast(message: TTexts.noInternetAccess.tr);
        return;
      }

      // Form Validation (only the rendered fields are validated)
      if (!signupFormKey.currentState!.validate()) return;

      // Privacy Policy Check
      if (!privacyPolicy.value) {
        TLoaders.warningSnackBar(title: TTexts.privacyPolicy.tr, message: TTexts.acceptPrivacyPolicyMessage.tr);
        return;
      }

      if (isCompany) {
        await _companyFlow();
      } else {
        await _retailFlow();
      }
    } on TRegistrationClosedException catch (e) {
      // FAZ 34 — anahtar, ekran açıldıktan SONRA çevrilmiş olabilir. Sunucunun
      // `errorCode`'u ekrana işlenir: kapanan bölüm bir daha çizilmez ve
      // varsa kalan seçeneğe geçilir (K29.2).
      TFullScreenLoader.stopLoading();
      _publicSettings.applyRegistrationError(e.errorCode);
      TLoaders.warningSnackBar(
        title: TTexts.registrationClosedTitle.tr,
        message: e.isAll ? TTexts.registrationClosedText.tr : TTexts.registrationTypeClosed.tr,
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// Individual: send OTP -> verify -> register.
  Future<void> _retailFlow() async {
    await _sendOtpThenRegister(
      name: firstName.text.trim(),
      surname: lastName.text.trim(),
      accountType: 'retail',
      iin: '',
    );
  }

  /// Company: pre-register -> look up by IIN/BIN -> confirm (or manual entry) ->
  /// send OTP -> verify -> register.
  Future<void> _companyFlow() async {
    final iinText = iin.text.trim();

    TFullScreenLoader.openLoadingDialog(TTexts.weAreProcessingInformation.tr, TImages.docerAnimation);
    final tempToken = await _repo.preRegister(email: email.text.trim(), accountType: 'company');
    final company = await _repo.getCompanyByIin(iinText, tempToken: tempToken);
    TFullScreenLoader.stopLoading();

    if (company == null || company.isEmpty) {
      // 1C'de yok → bilgiler elle alınır ve hesap `retail` + iin olarak açılır
      // (referanstaki karar; şirket hesabı sunucuda 1C eşleşmesi bekliyor).
      final manual = await showIpCompanyDialog();
      if (manual == null) return;
      await _sendOtpThenRegister(
        name: manual['name']!,
        surname: manual['director']!,
        accountType: 'retail',
        iin: iinText,
      );
    } else {
      final confirmed = await showCompanyConfirmDialog(company);
      if (!confirmed) return;
      await _sendOtpThenRegister(
        name: company.nameRu,
        surname: company.director,
        accountType: 'company',
        iin: iinText,
      );
    }
  }

  /// Shared tail: send the registration OTP, open the verification screen, and
  /// register on success.
  Future<void> _sendOtpThenRegister({
    required String name,
    required String surname,
    required String accountType,
    required String iin,
  }) async {
    TFullScreenLoader.openLoadingDialog(TTexts.weAreProcessingInformation.tr, TImages.docerAnimation);
    // FAZ 34 — hesap tipi gönderiliyor: sunucu o tipin anahtarına bakıp
    // gerekiyorsa OTP üretmeden reddediyor (Faz 29 kapısı). Tip gönderilmese
    // kapı yalnız "ikisi de kapalı" durumunda çalışırdı.
    await _repo.sendRegistrationOtp(email.text.trim(), accountType: accountType);
    TFullScreenLoader.stopLoading();

    final verified = await Get.to<bool>(() => RegisterOtpScreen(email: email.text.trim())) ?? false;
    if (!verified) return;

    await _doRegister(name: name, surname: surname, accountType: accountType, iin: iin);
  }

  /// Create the account, then return to the login screen (no auto-login).
  Future<void> _doRegister({
    required String name,
    required String surname,
    required String accountType,
    required String iin,
  }) async {
    TFullScreenLoader.openLoadingDialog(TTexts.weAreProcessingInformation.tr, TImages.docerAnimation);
    await _repo.registerAccount(
      name: name,
      surname: surname,
      email: email.text.trim(),
      password: password.text.trim(),
      phone: phoneNumber.text.trim(),
      accountType: accountType,
      iin: iin,
    );
    TFullScreenLoader.stopLoading();

    TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.congratulationMessage.tr);

    // Return to the login screen so the user can sign in with the new account.
    Get.offAll(() => const LoginScreen());
  }
}
