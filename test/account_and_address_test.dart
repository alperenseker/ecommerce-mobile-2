// FAZ 09 — hesap yüzeyinin **saf** kuralları.
//
// Ağ yok: burada yalnız iş kurallarının kendisi sabitleniyor. Canlı uç
// doğrulaması `test/live_account_test.dart` içinde.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/common/widgets/credit/credit_limit_section.dart';
import 'package:tstore_ecommerce_app/data/services/notifications/notification_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/language_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/notifcation_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/address_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/screens/notification/notifcation_detail_screen.dart';
import 'package:tstore_ecommerce_app/localization/languages.dart';

NotificationModel _n({
  String id = 'n1',
  List<String> recipients = const [],
  bool broadcast = false,
  String type = '',
}) =>
    NotificationModel(
      id: id,
      title: 't',
      body: 'b',
      senderId: 's',
      recipientIds: recipients,
      type: type,
      createdAt: DateTime(2026, 1, 1),
      seenBy: {},
      route: '',
      routeId: '',
      isBroadcast: broadcast,
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('faz09').path,
    );
    await GetStorage.init();
  });

  group('kredi limiti kapısı', () {
    test('yetkisi olmayan kullanıcıda bölüm ÇİZİLMEZ', () {
      expect(shouldShowCreditSection(hasCreditLine: false, canOrderWithoutStock: false), isFalse);
    });

    test('kredi satırı açıksa çizilir', () {
      expect(shouldShowCreditSection(hasCreditLine: true, canOrderWithoutStock: false), isTrue);
    });

    test('stoksuz sipariş yetkisi varsa çizilir', () {
      expect(shouldShowCreditSection(hasCreditLine: false, canOrderWithoutStock: true), isTrue);
    });

    test('ikisi de varsa çizilir', () {
      expect(shouldShowCreditSection(hasCreditLine: true, canOrderWithoutStock: true), isTrue);
    });

    test('🔴 transfer_only tuzağı: CanBypassPayment herkese true ama bölüm KAPALI', () {
      // Canlı sunucunun gerçek yanıtı (royalprof@gmail.com, 2026-09-08).
      final s = UserSettingsModel.fromJson(const {
        'UserId': 'user_00e05f87d7c3',
        'PriceCategory': 'A',
        'CanBypassPayment': true,
        'HasCreditLine': false,
        'CanOrderWithoutStock': false,
        'CreditLimit': 0,
        'UsedCredit': 0,
      });
      expect(s.canBypassPayment, isTrue, reason: 'sunucu gerçekten true döndürüyor');
      expect(
        shouldShowCreditSection(hasCreditLine: s.hasCreditLine, canOrderWithoutStock: s.canOrderWithoutStock),
        isFalse,
        reason: 'kapı CanBypassPayment okumamalı',
      );
    });

    test('eski API (HasCreditLine alanı yok) bugünkü davranışa düşer', () {
      final s = UserSettingsModel.fromJson(const {'CanBypassPayment': true});
      expect(s.hasCreditLine, isTrue);
      expect(shouldShowCreditSection(hasCreditLine: s.hasCreditLine, canOrderWithoutStock: false), isTrue);
    });

    test('kalan kredi negatife düşmez', () {
      final s = UserSettingsModel.fromJson(const {'CreditLimit': 1000, 'UsedCredit': 1500});
      expect(s.availableCredit, 0.0);
    });
  });

  group('bildirim süzgeci', () {
    test('yalnız alıcısı ben olan bildirimler gelir', () {
      final list = [
        _n(id: 'a', recipients: ['me']),
        _n(id: 'b', recipients: ['someone-else']),
        _n(id: 'c', recipients: ['x', 'me']),
      ];
      final mine = NotificationController.onlyMine(list, 'me');
      expect(mine.map((n) => n.id), ['a', 'c']);
    });

    test('🔴 IsBroadcast true olsa bile başkasının bildirimi gelmez', () {
      // Canlı veride tek alıcılı bildirimlerin hepsi IsBroadcast:true.
      final list = [_n(id: 'a', recipients: ['baskasi'], broadcast: true)];
      expect(NotificationController.onlyMine(list, 'me'), isEmpty);
    });

    test('misafirde (kimliksiz) liste boştur', () {
      final list = [_n(id: 'a', recipients: ['me'])];
      expect(NotificationController.onlyMine(list, ''), isEmpty);
    });
  });

  group('bildirim modeli', () {
    test('🔴 ISO metin tarih çökertmez (sunucu Firestore Timestamp göndermiyor)', () {
      final model = NotificationModel.fromJson('id-1', const {
        'title': 'orderShippedOnItsWay',
        'body': 'x',
        'createdAt': '2026-07-01T05:31:19.33982Z',
      });
      expect(model.createdAt.year, 2026);
      expect(model.seenAt, isNull);
    });

    test('tanınmayan tarih bugüne düşer, istisna fırlatmaz', () {
      final model = NotificationModel.fromJson('id-2', const {'createdAt': 12345});
      expect(model.createdAt, isA<DateTime>());
    });

    test('tür rozetinden GUID kırpılır', () {
      expect(
        notificationTypeLabel('Order Update 363b434d-e771-4a2c-9dff-d09a54be4017'),
        'Order Update',
      );
      expect(notificationTypeLabel('Promo'), 'Promo');
      expect(notificationTypeLabel(''), '');
    });
  });

  group('adres — tek ad alanı ↔ ayrık FirstName/LastName', () {
    test('tek alandan ad ve soyad ayrılır', () {
      final json = AddressModel(
        id: '',
        name: 'Депухан Ахжол',
        phoneNumber: '+77770000000',
        street: 'x',
        city: 'y',
        state: '',
        postalCode: '1',
        country: 'KZ',
      ).toJson();
      expect(json['firstName'], 'Депухан');
      expect(json['lastName'], 'Ахжол');
    });

    test('iki kelimeden uzun ad: ilki ad, gerisi soyad', () {
      final json = AddressModel(
        id: '',
        name: 'Ali Veli Han',
        phoneNumber: '',
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
      ).toJson();
      expect(json['firstName'], 'Ali');
      expect(json['lastName'], 'Veli Han');
    });

    test('ayrık alanlar verilmişse bölme yapılmaz', () {
      final json = AddressModel(
        id: '',
        name: 'yok sayılır',
        firstName: 'FAZ09',
        lastName: 'TEST',
        phoneNumber: '',
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
      ).toJson();
      expect(json['firstName'], 'FAZ09');
      expect(json['lastName'], 'TEST');
    });

    test('sunucunun PascalCase yanıtı okunur', () {
      final a = AddressModel.fromJson('addr-1', const {
        'AddressType': 'shipping',
        'FirstName': 'Депухан',
        'LastName': 'Ахжол',
        'Phone': '+7(777)766-00-00',
        'City': 'Алматы',
        'AddressLine1': 'Немировича-Данченко 18а',
        'PostalCode': '050061',
        'IsDefault': true,
        'IsActive': true,
      });
      expect(a.id, 'addr-1');
      expect(a.name.trim(), 'Депухан Ахжол');
      expect(a.city, 'Алматы');
      expect(a.selectedAddress, isTrue);
    });
  });

  group('dil', () {
    // FAZ 11 sözlükleri doldurdu; iskelet dönemindeki "harita boş" beklentisi
    // burada tersine çevrildi. Tembel yüklemenin kendi testleri
    // `test/localization_test.dart` içinde.
    test('on dilin sözlüğü kayıtlı, açılışta yalnız yedek dil yüklenir', () {
      expect(Languages.hasTranslation('en'), isTrue);
      expect(Languages.hasTranslation('kk'), isTrue);
      expect(Languages.hasTranslation('zz'), isFalse);
      // Kayıtlı dil yokken bellekte yalnız yedek İngilizce durur.
      expect(Languages().keys.keys, ['en_US']);
      // Sözlüğü olmayan dil için çağrı sessizce geçer.
      Languages.ensureLoaded('zz');
    });

    test('sözlüğü olmayan dil İngilizceye düşer', () {
      final c = LanguageController();
      expect(c.localeFor('tr').languageCode, 'tr');
      expect(c.localeFor('zz'), const Locale('en', 'US'));
    });

    test('on dil listelenir ve arama süzer', () {
      final c = LanguageController();
      c.filterLanguages('');
      expect(c.allLanguages.length, 10);
      c.filteredLanguages.value = List.from(c.allLanguages);
      c.filterLanguages('turk');
      expect(c.filteredLanguages.single['code'], 'tr');
      c.filterLanguages('');
      expect(c.filteredLanguages.length, 10);
    });
  });
}
