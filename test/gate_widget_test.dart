// GEÇİCİ: kayıt kapısı ve OTP alanı davranış testleri. Faz sonunda silinecek.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/common/widgets/login_signup/otp_code_field.dart';
import 'package:tstore_ecommerce_app/features/authentication/controllers/signup_controller.dart';
import 'package:tstore_ecommerce_app/features/authentication/screens/login/login.dart';
import 'package:tstore_ecommerce_app/features/authentication/screens/signup/signup.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/public_settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/public_settings_model.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';

/// Ağa çıkmayan sahte anahtar denetleyicisi: `onInit` içindeki yükleme
/// atlanıyor, değer testin verdiği gibi kalıyor.
class _FakePublicSettings extends PublicSettingsController {
  _FakePublicSettings(bool retail, bool company) {
    settings.value = PublicSettingsModel(
      retailRegistrationEnabled: retail,
      companyRegistrationEnabled: company,
      paymentMode: 'transfer_only',
    );
    loaded.value = true;
  }

  @override
  void onInit() {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> ensureLoaded() async {}
}

Widget _wrap(Widget child) => GetMaterialApp(theme: TAppTheme.lightTheme, home: child);

Future<void> _mount(WidgetTester tester, {required bool retail, required bool company}) async {
  Get.reset();
  Get.put<PublicSettingsController>(_FakePublicSettings(retail, company), permanent: true);
  Get.put(SignupController());
  await tester.pumpWidget(_wrap(const SignupScreen()));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
  });

  testWidgets('kapi 1/4 — ikisi de acik: secici ve form cizilir', (tester) async {
    await _mount(tester, retail: true, company: true);
    expect(find.text('Individual'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('registrationClosedTitle'), findsNothing);
    expect(SignupController.instance.effectiveAccountType, 'retail');
  });

  testWidgets('kapi 2/4 — perakende kapali: bireysel cizilmez, sirket onsecili', (tester) async {
    await _mount(tester, retail: false, company: true);
    expect(find.text('Individual'), findsNothing);
    expect(find.text('Company'), findsNothing); // secici tumden gizli
    expect(SignupController.instance.effectiveAccountType, 'company');
    expect(find.text('IIN / BIN'), findsOneWidget); // sirket alani cizildi
  });

  testWidgets('kapi 3/4 — bayi kapali: sirket cizilmez, bireysel onsecili', (tester) async {
    await _mount(tester, retail: true, company: false);
    expect(find.text('Company'), findsNothing);
    expect(SignupController.instance.effectiveAccountType, 'retail');
    expect(find.text('IIN / BIN'), findsNothing);
  });

  testWidgets('kapi 4/4 — ikisi de kapali: form yok, kapali blogu var', (tester) async {
    await _mount(tester, retail: false, company: false);
    expect(find.text('registrationClosedTitle'), findsOneWidget);
    expect(find.text('createAccount'), findsNothing); // kayit dugmesi yok
    expect(find.text('signIn'), findsWidgets); // girise donus acik
  });

  testWidgets('kayit kapaliyken giris formu acik kalir', (tester) async {
    Get.reset();
    Get.put<PublicSettingsController>(_FakePublicSettings(false, false), permanent: true);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(2)); // e-posta + sifre
    expect(find.text('signIn'), findsWidgets);
  });

  testWidgets('OTP alani: otomatik ilerleme, geri silme, yapistirma', (tester) async {
    String current = '';
    String completed = '';
    await tester.pumpWidget(_wrap(Scaffold(
      body: TOtpCodeField(
        length: 6,
        onChanged: (v) => current = v,
        onCompleted: (v) => completed = v,
      ),
    )));
    await tester.pump();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);

    // Tek tek yazma — imlec kendiliginden ilerliyor.
    await tester.enterText(field, '12');
    await tester.pump();
    expect(current, '12');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Geri silme.
    await tester.enterText(field, '1');
    await tester.pump();
    expect(current, '1');
    expect(find.text('2'), findsNothing);

    // Yapistirma — 6 hane tek seferde.
    await tester.enterText(field, '987654');
    await tester.pump();
    expect(completed, '987654');
    expect(find.text('9'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Uzunluk siniri: fazlasi kirpilir.
    await tester.enterText(field, '9876543210');
    await tester.pump();
    expect(current.length, 6);

    // Harf girilemez.
    await tester.enterText(field, 'abcdef');
    await tester.pump();
    expect(current, '');
  });
}
