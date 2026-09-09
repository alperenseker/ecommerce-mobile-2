// FAZ 07 — ödeme ekranının iş kuralları (ağa çıkmaz).
//
// Canlı uç doğrulaması `live_checkout_test.dart` içinde; burada istem
// dosyasının 🔴 işaretli maddeleri sınanıyor:
//   · `transfer_only` modunda kart seçeneği HİÇ çizilmiyor
//   · `gateway` modunda üç yöntem de çiziliyor
//   · mod `transfer_only`'ye dönünce seçili kart kendiliğinden havaleye çekiliyor
//   · kredili müşteri her modda `pending_approval`
//   · 🔴 `CanBypassPayment` true + kredi YOK + `transfer_only` iken minimum
//     sipariş tutarı kontrolü KOŞUYOR (sunucu o bayrağı herkese true dönüyor)
//   · kredili müşteride minimum değil KREDİ LİMİTİ kontrolü koşuyor
//   · sepet iki şirkete bölününce iki rekvizit bloğu + "ayrı ödeme" uyarısı
//   · şirketi çözülemeyen kalem için blok çizilmiyor
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_bank_details_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_settings_repository.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/public_settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/user_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/user_settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/public_settings_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_settings_model.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/coupon_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/checkout_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/models/bank_detail_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/cart_item_model.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/checkout/widgets/bank_transfer_details.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/checkout/widgets/billing_payment_section.dart';
import 'package:tstore_ecommerce_app/utils/constants/text_strings.dart';
import 'package:tstore_ecommerce_app/utils/helpers/erp_source_helper.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';

// ── Ağa çıkmayan yardımcılar ───────────────────────────────────────────────

class _OfflineAuthRepository extends AuthenticationRepository {
  @override
  String get getUserID => 'test-user';

  @override
  void onReady() {}
}

class _OfflineSettingsController extends SettingsController {
  @override
  Future<void> onInit() async {}
}

class _OfflineUserController extends UserController {
  @override
  void onInit() {}
}

/// Ödeme modunu ELDE tutan genel ayar controller'ı: `settings/public` ucuna
/// gitmeden `transfer_only` / `gateway` arasında geçiş yapılabilsin diye.
class _FakePublicSettingsController extends PublicSettingsController {
  _FakePublicSettingsController({required bool transferOnly}) {
    _apply(transferOnly);
  }

  void _apply(bool transferOnly) {
    settings.value = PublicSettingsModel.fromJson({
      'paymentMode': transferOnly ? 'transfer_only' : 'gateway',
    });
    loaded.value = true;
  }

  /// Ekran açıkken anahtarın çevrilmesini benzetir.
  void switchTo({required bool transferOnly}) => _apply(transferOnly);

  @override
  void onInit() {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> ensureLoaded() async {}
}

/// Kullanıcı yetkilerini elde tutan controller (sunucuya gitmez).
class _FakeUserSettingsController extends UserSettingsController {
  _FakeUserSettingsController({
    bool hasCreditLine = false,
    bool canBypassPayment = false,
    bool canOrderWithoutStock = false,
    double creditLimit = 0,
    double usedCredit = 0,
    double minimumOrderAmount = 0,
  }) {
    settings.value = UserSettingsModel.fromJson({
      'HasCreditLine': hasCreditLine,
      'CanBypassPayment': canBypassPayment,
      'CanOrderWithoutStock': canOrderWithoutStock,
      'CreditLimit': creditLimit,
      'UsedCredit': usedCredit,
      'MinimumOrderAmount': minimumOrderAmount,
    });
  }

  @override
  void onInit() {}
}

/// Rekvizit ucuna gitmeyen depo: blokların çizimi sınanırken ağ beklenmesin.
class _FakeBankDetailsRepository extends ApiBankDetailsRepository {
  @override
  Future<Map<String, List<BankDetailModel>>?> fetchByCompany({String? erpSource}) async => {
        'fores': [_bank('fores', 'KZT')],
        'foral': [_bank('foral', 'KZT')],
      };
}

BankDetailModel _bank(String code, String currency) => BankDetailModel.fromJson({
      'Id': '$code-$currency',
      'BankName': 'Halyk Bank ($currency)',
      'Iban': 'KZ0000000000$code',
      'BeneficiaryName': code.toUpperCase(),
      'Bin': '123456789012',
      'Bik': 'HSBKKZKX',
      'Kbe': '17',
      'Currency': currency,
      'ErpSourceCode': code,
      'IsActive': true,
    });

CartItemModel _item({required String erpSource, double price = 1000, int quantity = 1}) => CartItemModel(
      productId: 'p-$erpSource-$price',
      title: 'Ürün $erpSource',
      price: price,
      quantity: quantity,
      erpSource: erpSource,
      image: '',
    );

Widget _wrap(Widget child) => GetMaterialApp(
      theme: TAppTheme.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// Ödeme controller'ının ihtiyaç duyduğu bağımlılıkları kurar.
CheckoutController _boot({
  required bool transferOnly,
  bool hasCreditLine = false,
  bool canBypassPayment = false,
  bool canOrderWithoutStock = false,
  double creditLimit = 0,
  double usedCredit = 0,
  double minimumOrderAmount = 0,
}) {
  Get.reset();
  Get.put<AuthenticationRepository>(_OfflineAuthRepository());
  Get.put(ApiSettingsRepository());
  Get.put(ApiUserRepository());
  Get.put(ApiUserSettingsRepository());
  Get.put<ApiBankDetailsRepository>(_FakeBankDetailsRepository());
  Get.put<SettingsController>(_OfflineSettingsController());
  Get.put<UserController>(_OfflineUserController());
  Get.put<PublicSettingsController>(_FakePublicSettingsController(transferOnly: transferOnly));
  Get.put<UserSettingsController>(_FakeUserSettingsController(
    hasCreditLine: hasCreditLine,
    canBypassPayment: canBypassPayment,
    canOrderWithoutStock: canOrderWithoutStock,
    creditLimit: creditLimit,
    usedCredit: usedCredit,
    minimumOrderAmount: minimumOrderAmount,
  ));
  Get.put(CouponController());
  return Get.put(CheckoutController());
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

  // ── 1. Ödeme modu ────────────────────────────────────────────────────────

  test('transfer_only: kart kapalı, havale açık, sunucuya bank_transfer gider', () async {
    final c = _boot(transferOnly: true);
    await c.capturePaymentMode(force: true);

    expect(c.isTransferOnly.value, isTrue);
    expect(c.canPayByCard, isFalse, reason: 'kart seçeneği HİÇ çizilmemeli');
    expect(c.showBankTransfer, isTrue);
    expect(c.willPayByCard, isFalse, reason: 'ePay WebView açılmamalı');
    expect(c.resolvePaymentMethod(), TPaymentMethodCodes.bankTransfer);
  });

  test('gateway: üç yöntem de açık, varsayılan kart', () async {
    final c = _boot(transferOnly: false);
    await c.capturePaymentMode(force: true);

    expect(c.canPayByCard, isTrue);
    expect(c.showBankTransfer, isFalse);
    expect(c.resolvePaymentMethod(), TPaymentMethodCodes.card);
    expect(c.willPayByCard, isTrue);
  });

  test('mod transfer_only\'ye dönünce seçili kart havaleye çekilir', () async {
    final c = _boot(transferOnly: false);
    await c.capturePaymentMode(force: true);
    expect(c.selectedMethodCode.value, TPaymentMethodCodes.card);

    // Yönetici anahtarı çevirdi; ekran siparişten hemen önce tazeliyor.
    (PublicSettingsController.instance as _FakePublicSettingsController).switchTo(transferOnly: true);
    await c.capturePaymentMode(force: true);

    expect(c.selectedMethodCode.value, TPaymentMethodCodes.bankTransfer,
        reason: 'kapalı bir seçenek seçili kalmamalı');
    expect(c.resolvePaymentMethod(), TPaymentMethodCodes.bankTransfer);
  });

  test('kredili müşteri her modda pending_approval', () async {
    for (final transferOnly in [true, false]) {
      final c = _boot(transferOnly: transferOnly, hasCreditLine: true);
      await c.capturePaymentMode(force: true);
      expect(c.hasCreditLine, isTrue);
      expect(c.canPayByCard, isFalse, reason: 'kredili müşteriye kart çizilmez');
      expect(c.showBankTransfer, isTrue);
      expect(c.resolvePaymentMethod(), TPaymentMethodCodes.pendingApproval);
    }
  });

  // ── 2. "Özel kullanıcı" ayrımı ve limitler ───────────────────────────────

  test('🔴 CanBypassPayment true + kredi YOK + transfer_only → minimum tutar KOŞAR', () async {
    // Sunucu bu üçlüyü canlıda gerçekten döndürüyor (bkz. live_checkout_test).
    final c = _boot(
      transferOnly: true,
      hasCreditLine: false,
      canBypassPayment: true,
      minimumOrderAmount: 5000,
    );
    await c.capturePaymentMode(force: true);

    expect(c.isBypassUser, isTrue, reason: 'sunucu bayrağı gerçekten true');

    final blocked = c.evaluateLimits(1200);
    expect(blocked.canProceed, isFalse, reason: 'minimum tutar kontrolü düşmemeli');
    expect(blocked.isSpecialUser, isFalse);
    // Mesaj SAYI içermeli: sepet toplamı ve kalan tutar yazılı olmalı.
    expect(blocked.message.contains('1'), isTrue);
    expect(blocked.message.contains('5'), isTrue);

    expect(c.evaluateLimits(9000).canProceed, isTrue);
  });

  test('kredili müşteride minimum değil KREDİ LİMİTİ kontrolü koşar', () async {
    final c = _boot(
      transferOnly: true,
      hasCreditLine: true,
      creditLimit: 10000,
      usedCredit: 8000,
      // Minimum 50.000 olsa bile kredili müşteride bu kontrol koşmaz.
      minimumOrderAmount: 50000,
    );
    await c.capturePaymentMode(force: true);

    // Kalan kredi 2.000 → 1.000'lik sepet geçer.
    final ok = c.evaluateLimits(1000);
    expect(ok.canProceed, isTrue);
    expect(ok.isSpecialUser, isTrue);

    // 5.000'lik sepet kalan krediyi aşar.
    final blocked = c.evaluateLimits(5000);
    expect(blocked.canProceed, isFalse);
    expect(blocked.isSpecialUser, isTrue);
  });

  test('kredi limiti 0 ya da minimum 0 iken kontrol yok', () async {
    final credit = _boot(transferOnly: true, hasCreditLine: true, creditLimit: 0);
    await credit.capturePaymentMode(force: true);
    expect(credit.evaluateLimits(999999).canProceed, isTrue);

    final retail = _boot(transferOnly: true, minimumOrderAmount: 0);
    await retail.capturePaymentMode(force: true);
    expect(retail.evaluateLimits(1).canProceed, isTrue);
  });

  // ── 3. Ödeme yöntemi seçici (yalnız gateway) ─────────────────────────────

  testWidgets('gateway seçicisinde kart · havale · kapıda çizilir', (tester) async {
    final c = _boot(transferOnly: false);
    await c.capturePaymentMode(force: true);

    await tester.pumpWidget(_wrap(const TBillingPaymentSection()));
    await tester.pump();

    expect(find.text(TTexts.creditCard), findsOneWidget);
    expect(find.text(TTexts.bankTransfer), findsOneWidget);
    expect(find.text(TTexts.cashOnDelivery), findsOneWidget);

    // Seçim değişince controller'a yazılıyor.
    await tester.tap(find.text(TTexts.bankTransfer));
    await tester.pump();
    expect(c.selectedMethodCode.value, TPaymentMethodCodes.bankTransfer);
    expect(c.willPayByCard, isFalse);
  });

  // ── 4. Havale rekvizitleri — ŞİRKET BAŞINA ──────────────────────────────

  testWidgets('iki şirket → iki blok + "her şirkete ayrı ödeme" uyarısı', (tester) async {
    _boot(transferOnly: true);

    final groups = TErpSource.groupCartItems([
      _item(erpSource: 'fores', price: 1250),
      _item(erpSource: 'foral', price: 1000),
    ]);
    expect(groups.length, 2);

    await tester.pumpWidget(_wrap(TBankTransferDetails(
      blocks: groups.map((g) => TBankTransferBlock(code: g.code, name: g.name, amount: g.subtotal)).toList(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Fores'), findsOneWidget);
    expect(find.text('Foral'), findsOneWidget);
    // Tek havale iki şirketi kapatmaz; müşteri bunu ödemeden ÖNCE görmeli.
    expect(find.textContaining(TTexts.bankPerCompanyNote), findsOneWidget);
    // IBAN kopyalama düğmesi her blokta.
    expect(find.text(TTexts.bankCopy), findsNWidgets(2));
  });

  testWidgets('tek şirkette "ayrı ödeme" uyarısı YOK', (tester) async {
    _boot(transferOnly: true);

    await tester.pumpWidget(_wrap(const TBankTransferDetails(
      blocks: [TBankTransferBlock(code: 'fores', name: 'Fores', amount: 1140)],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Fores'), findsOneWidget);
    expect(find.textContaining(TTexts.bankPerCompanyNote), findsNothing);
  });

  testWidgets('şirketi çözülemeyen kalem için blok çizilmez', (tester) async {
    _boot(transferOnly: true);

    await tester.pumpWidget(_wrap(const TBankTransferDetails(
      blocks: [TBankTransferBlock(code: '', name: '', amount: 500)],
    )));
    await tester.pumpAndSettle();

    // Hangi hesaba yatırılacağı belirsiz; ad uydurmaktansa hiç çizilmiyor.
    expect(find.text(TTexts.bankCopy), findsNothing);
  });

  testWidgets('rekvizitleri olmayan şirkette "tanımlı değil" notu çizilir', (tester) async {
    _boot(transferOnly: true);

    await tester.pumpWidget(_wrap(const TBankTransferDetails(
      blocks: [TBankTransferBlock(code: 'stark', name: 'Stark Alpha', amount: 300)],
    )));
    await tester.pumpAndSettle();

    // Sahte depo yalnız fores/foral döndürüyor → stark için hesap yok.
    expect(find.text(TTexts.bankMissing), findsOneWidget);
    expect(find.text(TTexts.bankCopy), findsNothing);
  });
}
