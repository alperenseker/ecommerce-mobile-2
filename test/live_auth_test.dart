// GEÇİCİ: canlı API doğrulaması. Faz sonunda silinecek.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_settings_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // GetStorage path_provider'a bağlı; testte geçici bir klasör veriyoruz.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    // Test binding'i tüm HTTP isteklerine 400 döndüren bir override kuruyor;
    // gerçek sunucuya gidebilmek için kaldırıyoruz.
    HttpOverrides.global = null;
  });

  test('settings/public (anonim)', () async {
    final s = await ApiSettingsRepository().getPublicSettings(forceRefresh: true);
    // ignore: avoid_print
    print('PUBLIC retail=${s.retailRegistrationEnabled} company=${s.companyRegistrationEnabled} mode=${s.paymentMode} closed=${s.isRegistrationClosed}');
  });

  test('Auth/login - hatali sifre', () async {
    final res = await ApiAuth.loginWithEmailPassword(email: 'royalprof@gmail.com', password: 'kesinlikleyanlis');
    // ignore: avoid_print
    print('WRONGPASS success=${res['success']} message=${res['message']}');
  });

  test('Auth/login - gercek hesap + usersettings', () async {
    final res = await ApiAuth.loginWithEmailPassword(email: 'royalprof@gmail.com', password: '123456');
    // ignore: avoid_print
    print('LOGIN success=${res['success']} hasToken=${res['token'] != null} userId=${res['user']?['userId']} accountType=${res['user']?['accountType']} name=${res['user']?['name']}');
    if (res['success'] == true) {
      final userId = res['user']['userId'].toString();
      // Dio interceptor jetonu GetStorage'dan değil repository'den okuyor.
      final repo = Get.put(AuthenticationRepository());
      repo.customAuthToken.value = res['token'];
      repo.customUserId.value = userId;
      repo.isCustomAuthUser.value = true;
      final us = await ApiUserSettingsRepository().getUserSettings(userId);
      // ignore: avoid_print
      print('USERSETTINGS bypassPayment=${us.canBypassPayment} withoutStock=${us.canOrderWithoutStock} priceCategory=${us.priceCategory} creditLine=${us.hasCreditLine} minOrder=${us.minimumOrderAmount}');
    }
  });

  test('company/{iin} - jetonsuz', () async {
    final res = await ApiAuth.getCompanyByIin('123456789012');
    // ignore: avoid_print
    print('COMPANY_NO_TOKEN success=${res['success']} message=${res['message']}');
  });
}
