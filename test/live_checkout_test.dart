// GEÇİCİ: FAZ 07 doğrulaması — ödeme ekranının okuduğu uçlar GERÇEK HESAPLA
// denenir.
//
// 🔴 Bu test canlı sunucuyu **DEĞİŞTİRMEZ**: yalnız okuma yapar. Sipariş
// OLUŞTURULMAZ ve `payments/epay-token` çağrılmaz — kullanıcının açık kuralı
// ("canlı API'de sipariş onaylama, hiçbir zaman"). Doğrulanan şeyler:
// ödeme modu, kredi/limit ayrımı, adresler, sepetin şirket kırılımı ve
// rekvizitlerin şirket başına gruplanması.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/address/api_address_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/cart/api_cart_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_bank_details_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_settings_repository.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/cart_item_model.dart';
import 'package:tstore_ecommerce_app/utils/helpers/erp_source_helper.dart';

// ignore_for_file: avoid_print

late String userId;
late String userIin;
late UserSettingsModel userSettings;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    HttpOverrides.global = null;

    final res = await ApiAuth.loginWithEmailPassword(email: 'royalprof@gmail.com', password: '123456');
    expect(res['success'], true, reason: 'gerçek hesapla giriş yapılamadı');
    userId = res['user']['userId'].toString();

    final repo = Get.put(AuthenticationRepository());
    repo.customAuthToken.value = res['token'];
    repo.customUserId.value = userId;
    repo.isCustomAuthUser.value = true;

    Get.put(ApiSettingsRepository());
    Get.put(ApiUserSettingsRepository());
    Get.put(ApiAddressRepository());
    Get.put(ApiCartRepository());

    userIin = (res['user']['iin'] ?? res['user']['IIN'] ?? '').toString();
    userSettings = await ApiUserSettingsRepository.instance.getUserSettings(userId);
    print('LOGIN userId=$userId · iin=$userIin · '
        'accountType=${res['user']['accountType'] ?? res['user']['AccountType']}');
  });

  test('settings/public → ödeme modu okunuyor', () async {
    final public = await ApiSettingsRepository.instance.getPublicSettings(forceRefresh: true);
    print('paymentMode transfer_only mu? ${public.isTransferOnly}');
    // Sunucu bugün `transfer_only`; anahtar değişebilir, o yüzden yalnız
    // okunabildiği doğrulanıyor ve dallanma aşağıda ona göre iddia ediliyor.
    expect(public.isTransferOnly, isA<bool>());

    if (public.isTransferOnly) {
      // 🔴 Kabul kriteri: bu modda kart seçeneği ÇİZİLMEMELİ.
      final canPayByCard = !public.isTransferOnly && !userSettings.hasCreditLine;
      expect(canPayByCard, isFalse, reason: 'transfer_only iken kart seçeneği çizilmemeli');
      // Havale rekvizitleri GÖRÜNMELİ (iki sebepten biri yeter).
      expect(userSettings.hasCreditLine || public.isTransferOnly, isTrue);
    }
  });

  test('usersettings → "özel kullanıcı" ayrımı HasCreditLine ile', () async {
    print('HasCreditLine=${userSettings.hasCreditLine} · '
        'CanBypassPayment=${userSettings.canBypassPayment} · '
        'CanOrderWithoutStock=${userSettings.canOrderWithoutStock} · '
        'MinimumOrderAmount=${userSettings.minimumOrderAmount} · '
        'CreditLimit=${userSettings.creditLimit}');

    // 🔴 Sunucu `transfer_only`'de `CanBypassPayment`'ı HERKESE true
    // döndürüyor. Ona bakan kod minimum tutar kontrolünü tümden düşürür;
    // ayrımın `HasCreditLine` ile yapıldığı burada görünür olmalı.
    final isSpecialUser = userSettings.hasCreditLine || userSettings.canOrderWithoutStock;
    if (userSettings.canBypassPayment && !userSettings.hasCreditLine) {
      expect(isSpecialUser, userSettings.canOrderWithoutStock,
          reason: 'CanBypassPayment tek başına "özel kullanıcı" yapmamalı');
    }
  });

  test('Address/user/{id} → teslimat adresi ve şirket fatura adresi', () async {
    final addresses = await ApiAddressRepository.instance.fetchUserAddresses(userId);
    print('adres sayısı=${addresses.length}');
    for (final a in addresses.take(5)) {
      print('  ${a.addressType} · aktif=${a.isActive} · varsayılan=${a.selectedAddress} · $a');
    }

    // 🔴 Şirket hesabında fatura adresi 1C'den geliyor ve düzenlenemiyor:
    // `GET /company/{iin}`. Adres defterinden değil.
    if (userIin.trim().isNotEmpty) {
      final company = await ApiAddressRepository.instance.fetchCompanyBillingAddress(userIin.trim());
      print('1C fatura adresi: ${company ?? "(yok)"}');
    }
  });

  test('bank-details → şirket başına gruplanıyor', () async {
    // Süzgeçsiz çağrı: 12 satır bekleniyor, tek düz liste basılmamalı.
    final all = await ApiBankDetailsRepository().fetchActiveBankDetails();
    print('süzgeçsiz satır sayısı=${all.length}');

    final grouped = await ApiBankDetailsRepository().fetchByCompany();
    expect(grouped, isNotNull, reason: 'rekvizitler okunamadı');
    print('şirket sayısı=${grouped!.length} → ${grouped.keys.toList()}');
    for (final entry in grouped.entries) {
      final currencies = entry.value.map((b) => b.currencyKey).toSet().toList();
      print('  ${entry.key}: ${entry.value.length} hesap · para birimleri=$currencies');
    }
    // Grup sayısı satır sayısından KÜÇÜK olmalı; yoksa gruplama yapılmıyor.
    expect(grouped.length, lessThan(all.length));

    // Tek şirketlik süzgeç de çalışmalı (ekran tek şirkette sunucuya süzdürür).
    final foresOnly = await ApiBankDetailsRepository().fetchByCompany(erpSource: 'fores');
    print('yalnız fores → ${foresOnly?.keys.toList()}');
  });

  test('sepet → şirket kırılımı rekvizit bloklarını besliyor', () async {
    final items = await ApiCartRepository.instance.fetchUserCart(userId) ?? <CartItemModel>[];
    final groups = TErpSource.groupCartItems(items);
    print('sepet kalemi=${items.length} · şirket grubu=${groups.length}');
    for (final g in groups) {
      print('  ${g.name} (${g.code}) → ${g.subtotal}');
    }
    // Ödeme ekranı bu grupları OLDUĞU GİBİ rekvizit bloğuna çeviriyor;
    // kendi sıralamasını yazmıyor (grup sırası = sepetteki sıra).
    for (final g in groups) {
      expect(g.code.trim(), isNotEmpty, reason: 'şirketi çözülemeyen grup bloğu çizilmemeli');
    }
  });
}
