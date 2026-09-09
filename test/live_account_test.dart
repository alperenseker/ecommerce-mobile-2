// GEÇİCİ: FAZ 09 doğrulaması — hesap yüzeyinin okuduğu/yazdığı uçlar GERÇEK
// HESAPLA denenir (royalprof@gmail.com).
//
// 🔴 **SİPARİŞ OLUŞTURULMAZ** (kullanıcının açık kuralı). Bu test yalnız iki
// yerde yazma yapar ve ikisini de geri alır:
//   1. Adres defterine geçici bir adres ekler → günceller → **siler**
//      (fazın kabul kriteri: "gerçek hesapta adres ekleme/güncelleme
//      çalışıyor"). Adres `isDefault:false` eklenir, varsayılan adres
//      DEĞİŞTİRİLMEZ.
//   2. Şifre değiştirme ucunu **yanlış mevcut şifreyle** çağırır: uç
//      gerçekten çalışıyor mu, hata mesajı geliyor mu görülür ama hesabın
//      şifresi değişmez.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/common/widgets/credit/credit_limit_section.dart';
import 'package:tstore_ecommerce_app/data/repositories/address/api_address_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/notifications/api_notification_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_settings_repository.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/notifcation_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/address_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';

// ignore_for_file: avoid_print

late String userId;
late String userIin;
late String accountType;
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
    userIin = (res['user']['iin'] ?? res['user']['IIN'] ?? '').toString();
    accountType = (res['user']['accountType'] ?? res['user']['AccountType'] ?? 'retail').toString();

    final repo = Get.put(AuthenticationRepository());
    repo.customAuthToken.value = res['token'];
    repo.customUserId.value = userId;
    repo.isCustomAuthUser.value = true;

    Get.put(ApiUserSettingsRepository());
    Get.put(ApiAddressRepository());
    Get.put(ApiNotificationRepository());

    userSettings = await ApiUserSettingsRepository.instance.getUserSettings(userId);
    print('LOGIN userId=$userId · iin=$userIin · accountType=$accountType');
  });

  test('usersettings/{id} → yetkiler canlıdan geliyor', () async {
    print('PriceCategory=${userSettings.priceCategory} · '
        'CanBypassPayment=${userSettings.canBypassPayment} · '
        'HasCreditLine=${userSettings.hasCreditLine} · '
        'CanOrderWithoutStock=${userSettings.canOrderWithoutStock} · '
        'CreditLimit=${userSettings.creditLimit}');
    expect(userSettings.priceCategory, isNotEmpty);
  });

  test('🔴 kredi limiti bölümü yetkisi olmayan kullanıcıda GÖRÜNMÜYOR', () async {
    final visible = shouldShowCreditSection(
      hasCreditLine: userSettings.hasCreditLine,
      canOrderWithoutStock: userSettings.canOrderWithoutStock,
    );
    print('kredi bölümü görünür mü? $visible');

    if (!userSettings.hasCreditLine && !userSettings.canOrderWithoutStock) {
      expect(visible, isFalse, reason: 'yetkisiz kullanıcıda bölüm çizilmemeli');
      // Bu hesapta sunucu CanBypassPayment'ı true veriyor; kapı ona bakmıyor.
      print('CanBypassPayment=${userSettings.canBypassPayment} olmasına rağmen bölüm kapalı ✓');
    } else {
      expect(visible, isTrue);
    }
  });

  test('company/{iin} → şirket fatura adresi 1C\'den geliyor', () async {
    if (userIin.isEmpty) {
      print('ATLANDI: hesabın BİN\'i yok (bireysel hesap)');
      return;
    }
    final billing = await ApiAddressRepository.instance.fetchCompanyBillingAddress(userIin);
    expect(billing, isNotNull, reason: '1C fatura adresi gelmedi');
    print('1C fatura: ${billing!.company} · ${billing.name} · ${billing.street}');
    expect(billing.company, isNotEmpty);
    expect(billing.street, isNotEmpty);
  });

  test('adres defteri: ekle → güncelle → sil (tam tur, hesap eski hâline döner)', () async {
    final repo = ApiAddressRepository.instance;

    final before = await repo.fetchUserAddresses(userId);
    final defaultBefore = before.where((a) => a.selectedAddress).map((a) => a.id).toList();
    print('başlangıç: ${before.length} adres · varsayılan=$defaultBefore');

    // -- EKLE. `selectedAddress: false` → varsayılan adres DEĞİŞMEZ.
    final created = await repo.createAddress(AddressModel(
      id: '',
      name: 'FAZ09 TEST',
      phoneNumber: '+77770000000',
      street: 'Test street 1',
      city: 'Almaty',
      state: '',
      postalCode: '050000',
      country: 'Kazakhstan',
      selectedAddress: false,
    ));
    // 🔴 Kimlik BOŞ dönerse "ekle" akışı kırıktır: `AddressController`
    // dönen kimliği hemen `set-default` çağrısına veriyor.
    expect(created.id, isNotEmpty, reason: 'sunucu AddressId döndürüyor, model boş kimlik okumamalı');
    print('eklendi: ${created.id}');

    // -- GÜNCELLE
    final updated = await repo.updateAddress(AddressModel(
      id: created.id,
      name: 'FAZ09 GUNCEL',
      phoneNumber: '+77770000001',
      street: 'Test street 2',
      city: 'Astana',
      state: '',
      postalCode: '010000',
      country: 'Kazakhstan',
      addressType: created.addressType,
      selectedAddress: false,
    ));
    expect(updated.id, created.id);
    expect(updated.city, 'Astana');
    // Tek "ad soyad" alanı sunucuda ayrık tutuluyor; çeviri tek yerde.
    expect(updated.name.trim(), 'FAZ09 GUNCEL');
    print('güncellendi: ${updated.name} · ${updated.city} · ${updated.postalCode}');

    // -- ÖDEME EKRANINDA GÖRÜNÜYOR MU (defterde listeleniyor mu)
    final mid = await repo.fetchUserAddresses(userId);
    expect(mid.where((a) => a.id == created.id && a.isActive), isNotEmpty,
        reason: 'yeni adres listede/ödeme ekranında görünmeli');

    // -- SİL (sunucuda soft delete)
    final deleted = await repo.deleteAddress(created.id);
    expect(deleted, isTrue);

    final after = await repo.fetchUserAddresses(userId);
    expect(after.where((a) => a.id == created.id && a.isActive), isEmpty,
        reason: 'silinen adres defterde kalmamalı');
    final defaultAfter = after.where((a) => a.selectedAddress).map((a) => a.id).toList();
    expect(defaultAfter, defaultBefore, reason: 'varsayılan adres değişmemeliydi');
    print('silindi; varsayılan aynı kaldı ✓');
  });

  test('notifications → liste çekiliyor ve ALICIYA GÖRE süzülüyor', () async {
    final all = await ApiNotificationRepository.instance.fetchAllItems();
    expect(all, isNotEmpty, reason: 'uç boş liste döndürdü');
    // 🔴 Kimlik boş gelirse detay ve okundu işaretleme kırılır.
    expect(all.every((n) => n.id.isNotEmpty), isTrue, reason: 'sunucu kimliği `Id` yazıyor');
    // 🔴 ISO tarih çökertmemeli (referanstaki `.toDate()` tuzağı).
    expect(all.first.createdAt, isA<DateTime>());

    final mine = NotificationController.onlyMine(all, userId);
    print('sunucudan ${all.length} bildirim · bana ait ${mine.length}');
    expect(mine.length, lessThan(all.length), reason: 'süzgeç çalışmıyor; başkasının bildirimi görünüyor');
    expect(mine.every((n) => n.recipientIds.contains(userId)), isTrue);

    // Canlı veride tek alıcılı bildirimlerde bile IsBroadcast true.
    print('IsBroadcast true olan ama tek alıcılı kayıt sayısı: '
        '${all.where((n) => n.isBroadcast && n.recipientIds.length == 1).length}');
  });

  test('notifications/{id} → detay ucu çalışıyor', () async {
    final all = await ApiNotificationRepository.instance.fetchAllItems();
    final one = await ApiNotificationRepository.instance.fetchSingleItem(all.first.id);
    expect(one.id, all.first.id);
    print('detay: ${one.title} · ${one.route} · ${one.routeId}');
  });

  test('auth/change-password ucu gerçekten çalışıyor (YANLIŞ şifreyle denenir)', () async {
    // 🔴 Hesabın şifresi DEĞİŞTİRİLMEZ: bilerek yanlış "mevcut şifre"
    // gönderiliyor; sunucunun ucu tanıdığı ve doğrulama yaptığı görülüyor.
    final res = await ApiAuth.changePassword(
      userId: userId,
      oldPassword: 'kesinlikle-yanlis-sifre',
      newPassword: 'Faz09!test',
      token: AuthenticationRepository.instance.authToken,
    );
    print('change-password (yanlış şifre) → success=${res['success']} · message=${res['message']}');
    expect(res['success'], isFalse, reason: 'yanlış mevcut şifre kabul edilmemeli');
    expect((res['message'] ?? '').toString(), isNotEmpty, reason: 'sunucu bir hata mesajı vermeli');

    // Hesap hâlâ eski şifreyle giriyor mu — yan etki bırakmadığımızın kanıtı.
    final again = await ApiAuth.loginWithEmailPassword(email: 'royalprof@gmail.com', password: '123456');
    expect(again['success'], true, reason: 'şifre yanlışlıkla değişmiş olabilir!');
  });
}
