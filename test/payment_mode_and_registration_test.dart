// FAZ 12 — üç genel anahtar (kayıt aç/kapa, ödeme modu), kredi satırı ayrımı
// ve şirketleşmiş havale rekvizitlerinin istemci tarafında ayrıştırılması.
//
// Referans projedeki `test/payment_mode_and_registration_test.dart` dosyasının
// hedefe taşınmış hâlidir (FAZ 03 + 07'den devreden borç, DURUM.md).
//
// Buradaki JSON parçaları **canlı API'den** (2026-08-28, `ecom.aycom.kz:5006`)
// birebir alınmıştır; alan adları ve büyük/küçük harf düzeni uydurma değildir.
// Testlerin ikinci amacı savunmacı ayrıştırmayı korumak: **yeni sürüm eski API
// yanıtına karşı da açılmalı** (faz/API.md → "Yanıt zarfı").
import 'package:flutter_test/flutter_test.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/public_settings_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/bank_detail_model.dart';

void main() {
  group('PublicSettingsModel — GET /api/settings/public', () {
    test('canlı yanıt birebir çözülüyor', () {
      // 2026-08-28 canlı ölçüm; sunucu bugün hâlâ aynı yanıtı veriyor.
      final model = PublicSettingsModel.fromJson({
        'retailRegistrationEnabled': true,
        'companyRegistrationEnabled': true,
        'paymentMode': 'transfer_only',
      });

      expect(model.retailRegistrationEnabled, isTrue);
      expect(model.companyRegistrationEnabled, isTrue);
      expect(model.isTransferOnly, isTrue);
      expect(model.isRegistrationClosed, isFalse);
    });

    test('alan yoksa BUGÜNKÜ DAVRANIŞ: kayıt açık, mod gateway', () {
      // Bir ağ hatası siteyi "kayıt kapalı"ya düşürmemeli (faz/API.md).
      final model = PublicSettingsModel.fromJson(const {});

      expect(model.retailRegistrationEnabled, isTrue);
      expect(model.companyRegistrationEnabled, isTrue);
      expect(model.isTransferOnly, isFalse);
      expect(model.paymentMode, PublicSettingsModel.paymentModeGateway);
    });

    test('tanınmayan mod gateway sayılır — kart akışı KESİLMEZ', () {
      // İleride üçüncü bir değer eklenirse bu sürüm ödemeyi kapatmamalı.
      final model = PublicSettingsModel.fromJson({'paymentMode': 'customer_choice'});
      expect(model.isTransferOnly, isFalse);
      expect(model.paymentMode, PublicSettingsModel.paymentModeGateway);
    });

    test('PascalCase ve metin "false" da anlaşılır', () {
      final model = PublicSettingsModel.fromJson({
        'RetailRegistrationEnabled': false,
        'CompanyRegistrationEnabled': 'false',
        'PaymentMode': 'TRANSFER_ONLY',
      });

      expect(model.retailRegistrationEnabled, isFalse);
      expect(model.companyRegistrationEnabled, isFalse);
      expect(model.isRegistrationClosed, isTrue);
      expect(model.isTransferOnly, isTrue);
    });

    test('tek kayıt tipi açıkken seçici gizlenir', () {
      final onlyCompany = PublicSettingsModel.fromJson({'retailRegistrationEnabled': false});
      expect(onlyCompany.hasSingleAccountType, isTrue);
      expect(onlyCompany.isRegistrationClosed, isFalse);

      final both = PublicSettingsModel.fromJson(const {});
      expect(both.hasSingleAccountType, isFalse);
    });
  });

  group('UserSettingsModel — HasCreditLine ayrımı', () {
    test('canlı transfer_only yanıtı: bypass true ama kredi satırı YOK', () {
      // Sunucu `transfer_only` modunda `CanBypassPayment`ı HERKESE true
      // döndürüyor; kredili müşteriyi ayıran alan `HasCreditLine`.
      final model = UserSettingsModel.fromJson({
        'UserSettingsId': 'bdbb5219-1c8c-4826-8472-cc6415bfb001',
        'UserId': 'user_00e05f87d7c3',
        'PriceCategory': 'A',
        'CanBypassPayment': true,
        'HasCreditLine': false,
        'CanOrderWithoutStock': true,
        'CreditLimit': 0,
        'UsedCredit': 0,
        'CustomDiscountRate': 0.0,
        'IsActive': true,
      });

      expect(model.canBypassPayment, isTrue);
      // 🔴 Ayrımın kendisi: kredisiz müşteriye kredi metni gösterilmemeli ve
      // minimum sipariş tutarı kontrolü koşmaya devam etmeli.
      expect(model.hasCreditLine, isFalse);
    });

    test('alan yoksa (eski API) bypass bayrağına düşer', () {
      final bypass = UserSettingsModel.fromJson({'CanBypassPayment': true});
      expect(bypass.hasCreditLine, isTrue, reason: 'eski API: bypass == kredili');

      final normal = UserSettingsModel.fromJson({'CanBypassPayment': false});
      expect(normal.hasCreditLine, isFalse);
    });

    test('gateway modunda iki bayrak aynı → bugünkü ekran değişmez', () {
      final model = UserSettingsModel.fromJson({
        'CanBypassPayment': true,
        'HasCreditLine': true,
        'CreditLimit': 500000,
        'UsedCredit': 100000,
      });

      expect(model.hasCreditLine, model.canBypassPayment);
      expect(model.hasCreditLimit, isTrue);
      expect(model.availableCredit, 400000);
    });
  });

  group('BankDetailModel — şirketleşmiş rekvizitler', () {
    // 2026-08-28 canlı yanıttan bir satır.
    final live = {
      'bankDetailId': 'e8176eba-e01e-42ae-9d81-b2086eeb1639',
      'bankName': 'АО «Народный Банк Казахстана» (KZT)',
      'iban': 'KZ356010311000189621',
      'beneficiaryName': 'ТОО «FORES» (ФОРЭС)',
      'bin': '141140014985',
      'bik': 'HSBKKZKX',
      'kbe': '17',
      'isActive': true,
      'sortOrder': 1,
      'erpSourceId': '59e99963-1a50-47b8-95df-133491d58a28',
      'erpSourceCode': 'fores',
      'erpSourceName': 'Fores',
    };

    test('canlı satır: şirket alanları ve kimlik okunuyor', () {
      final bank = BankDetailModel.fromJson(live);

      expect(bank.id, 'e8176eba-e01e-42ae-9d81-b2086eeb1639');
      expect(bank.erpSourceCode, 'fores');
      expect(bank.erpSourceName, 'Fores');
      expect(bank.sortOrder, 1);
      expect(bank.currencyKey, 'KZT');
      expect(bank.nameAndCurrency.name, 'АО «Народный Банк Казахстана»');
    });

    test('şirket alanı olmayan eski satır yine çözülür', () {
      final bank = BankDetailModel.fromJson({
        'bankDetailId': 'x',
        'bankName': 'JSC Halyk Bank',
        'iban': 'KZ00',
        'beneficiaryName': 'TOO',
        'bin': '1',
        'bik': '2',
        'kbe': '17',
        'isActive': true,
      });

      expect(bank.erpSourceCode, isEmpty);
      expect(bank.sortOrder, 0);
      // Para birimi eki yoksa "OTHER" kovasına düşer.
      expect(bank.currencyKey, 'OTHER');
      expect(bank.nameAndCurrency.currency, isNull);
    });
  });
}
