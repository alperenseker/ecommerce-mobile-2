// FAZ 09 — hesap, adres defteri, kredi limiti kapısı.
//
// Bu dosya fazın iki kritik kuralını kalıcı olarak sabitler:
//   1. Kredi limiti bölümü YETKİSİ OLMAYANA ÇİZİLMEZ (özellikle sunucu
//      `transfer_only` modundayken `CanBypassPayment` herkese true dönerken).
//   2. Sunucu FirstName/LastName'i ayrı tutar; ekranda tek "ad soyad" alanı
//      vardır ve çeviri tek yerde yapılır.
import 'package:flutter_test/flutter_test.dart';

import 'package:tstore_ecommerce_app/common/widgets/credit/credit_limit_section.dart';
import 'package:tstore_ecommerce_app/data/services/notifications/notification_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/notifcation_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/address_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';

void main() {
  group('Kredi limiti kapısı', () {
    test('yetkisi olmayan kullanıcıda bölüm ÇİZİLMEZ', () {
      expect(shouldShowCreditSection(hasCreditLine: false, canOrderWithoutStock: false), isFalse);
    });

    test('kredi satırı olan kullanıcıda çizilir', () {
      expect(shouldShowCreditSection(hasCreditLine: true, canOrderWithoutStock: false), isTrue);
    });

    test('stoksuz sipariş yetkisi tek başına yeter', () {
      expect(shouldShowCreditSection(hasCreditLine: false, canOrderWithoutStock: true), isTrue);
    });

    test('🔴 transfer_only tuzağı: CanBypassPayment herkese true olsa bile çizilmez', () {
      // Sunucu `transfer_only` modunda `CanBypassPayment`'ı HERKESE true
      // döndürüyor. Kapı web'deki gibi doğrudan o alana bakılsaydı, kredisi
      // olmayan sıradan müşteride de kredi limiti bölümü açılırdı.
      final settings = UserSettingsModel.fromJson({
        'CanBypassPayment': true,
        'HasCreditLine': false,
        'CanOrderWithoutStock': false,
        'CreditLimit': 0,
      });

      expect(settings.canBypassPayment, isTrue, reason: 'sunucu gerçekten true diyor');
      expect(
        shouldShowCreditSection(
          hasCreditLine: settings.hasCreditLine,
          canOrderWithoutStock: settings.canOrderWithoutStock,
        ),
        isFalse,
      );
    });

    test('eski API (HasCreditLine alanı yok) bugünkü davranışa düşer', () {
      final settings = UserSettingsModel.fromJson({'CanBypassPayment': true, 'CreditLimit': 500000});

      expect(settings.hasCreditLine, isTrue);
      expect(
        shouldShowCreditSection(
          hasCreditLine: settings.hasCreditLine,
          canOrderWithoutStock: settings.canOrderWithoutStock,
        ),
        isTrue,
      );
    });
  });

  group('Kredi tutarları', () {
    test('kalan kredi = limit - kullanılan', () {
      final settings = UserSettingsModel(creditLimit: 500000, usedCredit: 120000);
      expect(settings.availableCredit, 380000);
    });

    test('kullanılan limiti aşarsa kalan NEGATİF gösterilmez', () {
      final settings = UserSettingsModel(creditLimit: 100000, usedCredit: 150000);
      expect(settings.availableCredit, 0);
    });

    test('camelCase yanıt da okunur', () {
      final settings = UserSettingsModel.fromJson({
        'hasCreditLine': true,
        'creditLimit': '250000,5',
        'usedCredit': 50000,
        'priceCategory': 'B',
      });
      expect(settings.hasCreditLine, isTrue);
      expect(settings.creditLimit, 250000.5);
      expect(settings.priceCategory, 'B');
    });
  });

  group('Adres — tek "ad soyad" alanı ↔ ayrık FirstName/LastName', () {
    test('tek alan sunucuya ad + soyad olarak bölünür', () {
      final address = AddressModel(
        id: '',
        name: 'Айгүл Сериковна Нурланова',
        phoneNumber: '+77011234567',
        street: 'Абая 10',
        city: 'Алматы',
        state: '',
        postalCode: '050000',
        country: 'Казахстан',
      );

      final json = address.toJson();
      expect(json['firstName'], 'Айгүл');
      expect(json['lastName'], 'Сериковна Нурланова');
    });

    test('tek kelimelik adda soyad boş kalır (sunucu kabul ediyor)', () {
      final address = AddressModel(
        id: '',
        name: 'Ержан',
        phoneNumber: '',
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
      );
      expect(address.toJson()['firstName'], 'Ержан');
      expect(address.toJson()['lastName'], '');
    });

    test('sunucudan gelen ayrık alanlar ekranda tek ada birleşir', () {
      final address = AddressModel.fromJson('A1', {
        'AddressId': 'A1',
        'FirstName': 'Ержан',
        'LastName': 'Абдуллаев',
        'AddressLine1': 'Абая 10',
        'City': 'Алматы',
        'Country': 'Казахстан',
        'PostalCode': '050000',
        'Phone': '+77011234567',
        'AddressType': 'shipping',
        'IsDefault': true,
      });

      expect(address.name, 'Ержан Абдуллаев');
      expect(address.selectedAddress, isTrue);
      expect(address.isBilling, isFalse);
    });

    test('ad/soyad zaten ayrık verildiyse tek alan onları EZMEZ', () {
      final address = AddressModel(
        id: 'A1',
        name: 'Ержан Абдуллаев',
        firstName: 'Ержан',
        lastName: 'Абдуллаев',
        phoneNumber: '',
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
      );
      expect(address.toJson()['firstName'], 'Ержан');
      expect(address.toJson()['lastName'], 'Абдуллаев');
    });
  });

  group('Hesap tipi — profil ekranındaki kilitli alanlar', () {
    UserModel user({String accountType = 'retail', String iin = ''}) => UserModel(
      id: 'U1',
      email: 'a@b.kz',
      accountType: accountType,
      iin: iin,
      isEmailVerified: true,
      isProfileActive: true,
    );

    test('bireysel hesapta ad düzenlenebilir (şirket alanları çizilmez)', () {
      expect(user().isCorporate, isFalse);
      expect(user().isCompanyLike, isFalse);
    });

    test('şirket hesabında şirket alanları salt okunur çizilir', () {
      final u = user(accountType: 'company', iin: '123456789012');
      expect(u.isCorporate, isTrue);
      expect(u.isCompanyLike, isTrue);
    });

    test('İP hesabı: bireysel ama BİN taşıyor — şirket alanları çizilir', () {
      final u = user(iin: '123456789012');
      expect(u.isCorporate, isFalse, reason: 'fatura adresi düzenlenebilir kalmalı');
      expect(u.isIpCompany, isTrue);
      expect(u.isCompanyLike, isTrue);
    });
  });

  group('Bildirim süzgeci — başkasının bildirimi gösterilmez', () {
    NotificationModel notif(String id, List<String> recipients, {bool broadcast = true}) => NotificationModel(
      id: id,
      title: 'orderCanceledSorry',
      body: '',
      senderId: 'sys',
      recipientIds: recipients,
      type: 'Order Update',
      createdAt: DateTime(2026, 7, 1),
      seenBy: const {},
      route: '/orderDetail',
      routeId: 'O1',
      isBroadcast: broadcast,
    );

    final all = [
      notif('n1', ['user_me']),
      notif('n2', ['user_other']),
      notif('n3', const []), // gerçek duyuru
    ];

    test('yalnız kullanıcıya ait olan ve alıcısı olmayan duyuru kalır', () {
      final mine = NotificationController.onlyMine(all, 'user_me');
      expect(mine.map((n) => n.id), ['n1', 'n3']);
    });

    test('🔴 IsBroadcast true olsa bile başkasının bildirimi ELENİR', () {
      // Sunucu tek alıcılı bildirimlerde de IsBroadcast=true yazıyor;
      // ölçüt bu yüzden RecipientIds.
      final mine = NotificationController.onlyMine(all, 'user_me');
      expect(mine.any((n) => n.id == 'n2'), isFalse);
    });

    test('misafirde (kimlik yok) liste boş kalır', () {
      expect(NotificationController.onlyMine(all, ''), isEmpty);
    });
  });
}
