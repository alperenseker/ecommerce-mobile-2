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

/// Kayıt akışının denetleyicisi — iki ayrı yol yürütür.
///
/// **Bireysel:** OTP gönder → doğrula → `Auth/register`.
/// **Şirket:** `Auth/pre-register` (geçici jeton) → `company/{iin}` → şirket
/// doğrulama penceresi → OTP → kayıt.
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

  /// 'retail' (bireysel) veya 'company'. Hem formun hangi alanları çizeceğini
  /// hem hangi kayıt akışının koşacağını belirler.
  final accountType = 'retail'.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// Ekranın ve kayıt akışının kullandığı **etkin** hesap tipi.
  ///
  /// Kapalı bir kayıt tipi seçili kalırsa müşteri formu doldurup 403 yer. Açık
  /// olan tek tip varsa seçim ona çekilir.
  ///
  /// 🔴 Bu bir **türetilmiş değer**, bir yan etki değil: [accountType]'a yazan
  /// bir dinleyici (`ever`) kurulmadı. Dinleyici, anahtarın okunması ile
  /// kullanıcının "Hesap Oluştur"a basması arasında yarışa girebilirdi;
  /// türetilmiş değerde böyle bir aralık yok — kapalı bir hesap tipi sunucuya
  /// **hiçbir zaman** gönderilemez.
  String get effectiveAccountType {
    if (!retailRegistrationEnabled && companyRegistrationEnabled) return 'company';
    if (!companyRegistrationEnabled && retailRegistrationEnabled) return 'retail';
    return accountType.value;
  }

  bool get isCompany => effectiveAccountType == 'company';

  AuthenticationRepository get _repo => AuthenticationRepository.instance;

  PublicSettingsController get _publicSettings => PublicSettingsController.instance;

  /// Hangi kayıt tipleri açık. Ekran bunlara bakarak kapalı bölümü **hiç
  /// çizmez**; sunucudaki 403 yine de tek gerçek kapıdır.
  bool get retailRegistrationEnabled => _publicSettings.retailRegistrationEnabled;
  bool get companyRegistrationEnabled => _publicSettings.companyRegistrationEnabled;

  /// Tek seçenek kaldıysa hesap tipi seçicisi tümden gizlenir.
  bool get showAccountTypeSelector => retailRegistrationEnabled && companyRegistrationEnabled;

  /// -- Kayıt girişi: ortak alanlar doğrulanır, sonra ilgili akış çağrılır.
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
      // 🔴 Anahtar, ekran açıldıktan SONRA çevrilmiş olabilir. Sunucunun
      // `errorCode`'u ekrana işlenir: kapanan bölüm bir daha çizilmez ve varsa
      // kalan seçeneğe geçilir.
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

  /// Bireysel: OTP gönder → doğrula → kayıt.
  Future<void> _retailFlow() async {
    await _sendOtpThenRegister(
      name: firstName.text.trim(),
      surname: lastName.text.trim(),
      accountType: 'retail',
      iin: '',
    );
  }

  /// Şirket: ön kayıt → BİN/İİN ile 1C sorgusu → onay (ya da elle giriş) →
  /// OTP → kayıt.
  Future<void> _companyFlow() async {
    final iinText = iin.text.trim();

    TFullScreenLoader.openLoadingDialog(TTexts.weAreProcessingInformation.tr, TImages.docerAnimation);
    // `company/{iin}` sorgusu jeton ister; ön kayıt tam da bunun için geçici
    // bir jeton üretiyor (jetonsuz çağrı 401 dönüyor).
    final tempToken = await _repo.preRegister(email: email.text.trim(), accountType: 'company');
    final company = await _repo.getCompanyByIin(iinText, tempToken: tempToken);
    TFullScreenLoader.stopLoading();

    if (company == null || company.isEmpty) {
      // ⚠️ 1C'de bulunmayan şirket `retail` + `iin` olarak açılıyor. Web
      // (`login-register.js`) aynı durumda `AccountType: company` gönderiyor —
      // iki proje burada ayrışıyor. Referans mobildeki hâl korundu
      // (KURALLAR §2); hangisinin doğru olduğu sunucu tarafına sorulmalı.
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

  /// İki akışın ortak kuyruğu: OTP gönder, doğrulama ekranını aç, dönüşte kaydı
  /// oluştur.
  Future<void> _sendOtpThenRegister({
    required String name,
    required String surname,
    required String accountType,
    required String iin,
  }) async {
    TFullScreenLoader.openLoadingDialog(TTexts.weAreProcessingInformation.tr, TImages.docerAnimation);
    // 🔴 Hesap tipi gönderiliyor: sunucu o tipin anahtarına bakıp gerekiyorsa
    // OTP üretmeden reddediyor. Tip gönderilmese kapı yalnız "ikisi de kapalı"
    // durumunda çalışırdı.
    await _repo.sendRegistrationOtp(email.text.trim(), accountType: accountType);
    TFullScreenLoader.stopLoading();

    final verified = await Get.to<bool>(() => RegisterOtpScreen(email: email.text.trim())) ?? false;
    if (!verified) return;

    await _doRegister(name: name, surname: surname, accountType: accountType, iin: iin);
  }

  /// Hesabı oluşturur ve giriş ekranına döner (otomatik giriş yapılmaz).
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
