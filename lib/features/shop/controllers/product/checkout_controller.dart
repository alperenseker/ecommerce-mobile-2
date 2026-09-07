/// Ödeme ekranının durumu: genel ödeme modu, seçili yöntem, sipariş notu,
/// tutar hesabı (kargo/vergi/indirim) ve limit kontrolü.
///
/// 🔴 Bu dosyadaki iş kuralları **paranın kendisiyle** ilgili; hiçbiri
/// "sadeleştirme" adına atlanamaz. İkisi özellikle kritik:
///
///   1. **Ödeme modu sayfa ömrü boyunca sabittir.** `settings/public` →
///      `paymentMode` ekran açılırken bir kez okunur ve [paymentMode]'a
///      yazılır. Ekran açıkken superAdmin anahtarı çevirirse kullanıcının
///      altından ekran değişmez; tazeleme yalnız sipariş oluşturmadan hemen
///      önce (OrderController) yapılır ki 409'a çarpılmasın.
///
///   2. **"Özel kullanıcı" ayrımı `HasCreditLine` iledir, `CanBypassPayment`
///      ile DEĞİL.** `transfer_only` modunda sunucu `CanBypassPayment`'ı
///      HERKESE true döndürüyor (K29.7 uyum katmanı); ona bakan kod minimum
///      sipariş tutarı kontrolünü tümden düşürür. Web tarafı aynı düzeltmeyi
///      Faz 32'de yaptı (`pages/checkout.js` → `checkLimits`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../personalization/controllers/public_settings_controller.dart';
import '../../../personalization/controllers/settings_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/controllers/user_settings_controller.dart';
import '../../models/payment_method_model.dart';
import '../../screens/checkout/widgets/payment_tile.dart';
import '../coupon_controller.dart';

/// Sunucuya `PaymentMethod` alanında giden değerler. Adlar **değiştirilemez**:
/// sunucu ve web (`App.const.PAY_*`) bunlarla anlaşıyor.
class TPaymentMethodCodes {
  TPaymentMethodCodes._();

  static const String card = 'card';
  static const String bankTransfer = 'bank_transfer';
  static const String cashOnDelivery = 'cash_on_delivery';

  /// Kredili müşteri: sipariş yönetici onayına düşer, ödeme alınmaz.
  static const String pendingApproval = 'pending_approval';
}

/// Limit kontrolünün sonucu: sipariş verilebilir mi, verilemiyorsa neden.
///
/// [message] doğrudan ekrana basılır ve **sayı içerir** (sepet toplamı /
/// kalan tutar); "limit aşıldı" demek tek başına müşteriye ne yapacağını
/// söylemiyor.
class TCheckoutLimitState {
  const TCheckoutLimitState({
    required this.canProceed,
    required this.isSpecialUser,
    this.message = '',
  });

  const TCheckoutLimitState.allowed({bool special = false})
      : canProceed = true,
        isSpecialUser = special,
        message = '';

  final bool canProceed;

  /// Kredili (`HasCreditLine`) ya da stoksuz sipariş yetkisi olan müşteri.
  /// Bu müşteride **kredi limiti**, diğerlerinde **minimum sipariş tutarı**
  /// kontrolü koşar.
  final bool isSpecialUser;

  final String message;
}

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  RxBool isUsingPoints = false.obs;
  RxBool isCouponToggled = false.obs;

  //final couponController = CouponController.instance;
  final couponController = Get.put(CouponController());
  final settingsController = SettingsController.instance;
  final userController = Get.put(UserController());

  RxDouble couponDiscountAmount = 0.0.obs;
  RxDouble pointsDiscountAmount = 0.0.obs;
  final Rx<PaymentMethodModel> selectedPaymentMethod =
      PaymentMethodModel(name: TTexts.cashOnDelivery.tr, image: TImages.cod, paymentMethod: PaymentMethods.cash).obs;

  // ─── Genel ödeme modu ─────────────────────────────────────────────────────

  /// Ekran açılırken **bir kez** okunan genel mod. Sayfa ömrü boyunca sabittir
  /// (bkz. dosya başlığı). Varsayılan `gateway`: anahtar okunamazsa bugünkü
  /// davranışa düşülür, bir ağ hatası müşteriyi havale dalına atmaz.
  final RxBool isTransferOnly = false.obs;

  /// Ödeme modu bir kez okundu mu — ekran her açılışta yeniden okur.
  bool _paymentModeCaptured = false;

  // ─── Seçili ödeme yöntemi ────────────────────────────────────────────────

  /// Sunucuya gidecek yöntem kodu. Yalnız `gateway` modundaki **kredisiz**
  /// müşteri seçebilir; öteki dallarda değeri [resolvePaymentMethod] belirler.
  final RxString selectedMethodCode = TPaymentMethodCodes.card.obs;

  /// Sipariş notu — sunucuya `CustomerNote` olarak gider (web'deki
  /// `#order-notes` alanının karşılığı).
  final customerNote = TextEditingController();

  // -- Card entry form (shown to normal users; mirrors the web checkout card step)
  final cardHolderName = TextEditingController();
  final cardNumber = TextEditingController();
  final cardExpiry = TextEditingController();
  final cardCvv = TextEditingController();
  final cardFormKey = GlobalKey<FormState>();

  /// Users flagged with `CanBypassPayment` order on account (skip the card step).
  ///
  /// ⚠️ Ödeme dalını ayırmak için **kullanılmaz** — `transfer_only`'de herkese
  /// true dönüyor. Referansta olduğu için duruyor; dal ayrımı [hasCreditLine]
  /// ve [isTransferOnly] ile yapılır.
  bool get isBypassUser =>
      Get.isRegistered<UserSettingsController>() && UserSettingsController.instance.canBypassPayment;

  /// Müşterinin gerçekten kendi kredi satırı var mı (`HasCreditLine`).
  bool get hasCreditLine =>
      Get.isRegistered<UserSettingsController>() && UserSettingsController.instance.hasCreditLine;

  /// Havale rekvizitleri gösterilsin mi. **İki bağımsız sebep** var ve ikisi
  /// de tek başına yeterli (web `showBankTransfer()`):
  ///   • kredili müşteri — sipariş onaya düşer, tutarı havaleyle kapatır,
  ///   • genel `transfer_only` modu — herkes havale yapar.
  bool get showBankTransfer => hasCreditLine || isTransferOnly.value;

  /// Kart (ePay) seçeneği hiç çizilmeli mi. `transfer_only`'de ve kredili
  /// müşteride ÇİZİLMEZ: sunucu o modda `payments/epay-token` ucuna 409
  /// (`payment_disabled`) dönüyor ve müşteri o hata ekranını görmemeli.
  bool get canPayByCard => !isTransferOnly.value && !hasCreditLine;

  /// Genel ödeme modunu **bir kez** okur ve [isTransferOnly]'ye yazar.
  ///
  /// `PublicSettingsController` hata durumunda son bilinen değerde kalır ve
  /// asla fırlatmaz, bu yüzden burada ayrı bir yakalama yok.
  Future<void> capturePaymentMode({bool force = false}) async {
    if (_paymentModeCaptured && !force) return;
    await PublicSettingsController.instance.reload();
    isTransferOnly.value = PublicSettingsController.instance.isTransferOnly;
    _paymentModeCaptured = true;

    // Kart kapalıysa seçili yöntem havaleye çekilir: kapalı bir seçeneğin
    // seçili kalması sipariş anında yanlış yönteme yol açardı.
    if (!canPayByCard && selectedMethodCode.value == TPaymentMethodCodes.card) {
      selectedMethodCode.value = TPaymentMethodCodes.bankTransfer;
    }
  }

  /// Sunucuya gönderilecek `PaymentMethod` değeri.
  ///
  /// Sıra önemli: kredili müşteri her koşulda onay akışında kalır; ondan
  /// sonra genel `transfer_only` gelir; en sonda kullanıcının seçimi.
  ///
  /// ℹ️ Sunucu `transfer_only`'de bu alanı zaten `bank_transfer`'a çeviriyor
  /// (FAZ 29); burada doğru değeri göndermek onun düzeltmesine bel
  /// bağlamamak içindir.
  String resolvePaymentMethod() {
    if (hasCreditLine) return TPaymentMethodCodes.pendingApproval;
    if (isTransferOnly.value) return TPaymentMethodCodes.bankTransfer;
    return selectedMethodCode.value;
  }

  /// Kart (ePay) ekranına gidilecek mi. Sipariş oluştuktan sonra WebView
  /// yalnız bu doğruysa açılır.
  bool get willPayByCard => canPayByCard && selectedMethodCode.value == TPaymentMethodCodes.card;

  // ─── Limit kontrolü ──────────────────────────────────────────────────────

  /// Kredi limiti / minimum sipariş tutarı kontrolü (web `checkLimits`).
  ///
  /// 🔴 Ayrım `HasCreditLine` iledir. `CanBypassPayment`'a bakan bir kod
  /// `transfer_only` modunda HERKESİ "özel kullanıcı" sayar ve minimum
  /// sipariş tutarı kontrolü tümden düşer — ödemenin havaleye alınmış olması
  /// sepetin minimumu tutmasını gereksiz kılmaz.
  ///
  /// Ayarlar okunamadıysa **en az kısıtlayıcı** yola gidilir: bir ağ hatası
  /// müşterinin sipariş vermesini engellememeli (kapı zaten sunucuda).
  TCheckoutLimitState evaluateLimits(double subTotal) {
    if (!Get.isRegistered<UserSettingsController>()) {
      return const TCheckoutLimitState.allowed();
    }
    final userSettings = UserSettingsController.instance;

    final isSpecialUser = userSettings.hasCreditLine || userSettings.canOrderWithoutStock;
    if (isSpecialUser) {
      // Kredi limiti 0 = limit tanımlı değil → kontrol yok (web `creditCheck`).
      if (!userSettings.hasCreditLimit) {
        return const TCheckoutLimitState.allowed(special: true);
      }
      final grandTotal = calculateGrandTotal(subTotal);
      if (grandTotal > userSettings.availableCredit) {
        return TCheckoutLimitState(
          canProceed: false,
          isSpecialUser: true,
          message: '${TTexts.creditLimitExceededMessage.tr} '
              '(${TTexts.cartTotal.tr}: ${TFormatter.formatCurrency(grandTotal)}, '
              '${TTexts.availableCredit.tr}: ${TFormatter.formatCurrency(userSettings.availableCredit)})',
        );
      }
      return const TCheckoutLimitState.allowed(special: true);
    }

    // Kredisiz müşteri: minimum sipariş tutarı. 0 = kapalı (yönetici bir
    // değer girene kadar, web ile aynı varsayılan).
    final minimumOrderAmount = userSettings.minimumOrderAmount;
    if (minimumOrderAmount > 0 && subTotal < minimumOrderAmount) {
      final remaining = minimumOrderAmount - subTotal;
      return TCheckoutLimitState(
        canProceed: false,
        isSpecialUser: false,
        message: '${TTexts.minimumOrderNotMetMessage.tr} '
            '(${TTexts.minimumOrderRequired.tr}: ${TFormatter.formatCurrency(minimumOrderAmount)}, '
            '${TTexts.cartTotal.tr}: ${TFormatter.formatCurrency(subTotal)}, '
            '${TTexts.minimumOrderRemaining.tr}: ${TFormatter.formatCurrency(remaining)})',
      );
    }
    return const TCheckoutLimitState.allowed();
  }

  /// Luhn checksum validation — same algorithm as the web checkout.
  bool luhnCheck(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    int sum = 0;
    bool isEven = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      if (isEven) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isEven = !isEven;
    }
    return sum % 10 == 0;
  }

  /// Validates the card form for normal users: cardholder name, a 16-digit
  /// Luhn-valid number, a non-expired MM/YY date and a 3-4 digit CVV.
  ///
  /// ⚠️ Kart bilgisi uygulamada **toplanmıyor**: ödeme Halyk ePay'in güvenli
  /// sayfasında yapılıyor ve [TCardPaymentForm] hiçbir yerden çizilmiyor.
  /// Metot referansta olduğu için duruyor (KURALLAR §4).
  bool validateCard() {
    final name = cardHolderName.text.trim();
    final number = cardNumber.text.replaceAll(RegExp(r'\s'), '');
    final expiry = cardExpiry.text.trim();
    final cvv = cardCvv.text.trim();

    if (name.length < 3) return false;
    if (number.length != 16 || !luhnCheck(number)) return false;
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;

    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = 2000 + (int.tryParse(parts[1]) ?? 0);
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) return false;
    if (cvv.length < 3) return false;
    return true;
  }

  @override
  void onClose() {
    cardHolderName.dispose();
    cardNumber.dispose();
    cardExpiry.dispose();
    cardCvv.dispose();
    customerNote.dispose();
    super.onClose();
  }

  Future<dynamic> selectPaymentMethod(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder:
          (_) => SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(TSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TSectionHeading(title: TTexts.selectPaymentMethod.tr, showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  ...PaymentMethods.values.map((paymentMethod) {
                    switch (paymentMethod) {
                      case PaymentMethods.cash:
                        return TPaymentTile(
                          paymentMethodModel: PaymentMethodModel(
                            image: TImages.cod,
                            name: TTexts.cashOnDelivery.tr,
                            paymentMethod: PaymentMethods.cash,
                          ),
                        );
                      case PaymentMethods.card:
                        return TPaymentTile(
                          paymentMethodModel: PaymentMethodModel(
                            image: TImages.masterCard,
                            name: TTexts.visaMasterCard.tr,
                            paymentMethod: PaymentMethods.card,
                          ),
                        );
                      case PaymentMethods.paypal:
                        return TPaymentTile(
                          paymentMethodModel: PaymentMethodModel(
                            name: TTexts.paypal.tr,
                            image: TImages.paypal,
                            paymentMethod: PaymentMethods.paypal,
                          ),
                        );
                    }
                  }),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              ),
            ),
          ),
    );
  }

  bool isShippingFree(double subTotal) {
    // Check if a free shipping threshold is set and if the subtotal exceeds it
    final freeShippingThreshold = settingsController.settings.value.freeShippingThreshold;
    return freeShippingThreshold != null && freeShippingThreshold > 0.0 && subTotal >= freeShippingThreshold;
  }

  double getShippingCost(double subTotal) {
    // Return 0 if shipping is free, otherwise use the specified shipping cost
    return isShippingFree(subTotal) ? 0.0 : settingsController.settings.value.shippingCost;
  }

  double getTaxAmount(double subTotal) {
    // Calculate total discount
    double totalDiscount = calculateTotalDiscount(subTotal);

    // Adjust the subtotal by subtracting the discount, ensuring it doesn't go below zero
    double discountAdjustedSubTotal = (subTotal - totalDiscount).clamp(0.0, double.infinity);

    final taxAmount = discountAdjustedSubTotal * settingsController.settings.value.taxRate;

    // Return the tax amount based on the adjusted subtotal and tax rate
    return taxAmount;
  }

  double calculateTotalDiscount(double subTotal) {
    // Calculate the discount based on points if they are being used
    final pointsDiscount =
        isUsingPoints.value
            ? userController.user.value.points.toDouble() / settingsController.settings.value.pointsToDollarConversion
            : 0.0;

    if (pointsDiscount > subTotal) {
      pointsDiscountAmount.value = subTotal;
    } else {
      pointsDiscountAmount.value = pointsDiscount;
    }

    // Calculate the discount based on the coupon if it's being used
    final couponDiscountAmount =
        isCouponToggled.value
            ? (couponController.coupon.value.discountType.name == DiscountType.percentage.name
                ? ((couponController.coupon.value.discountValue * subTotal) / 100)
                : couponController.coupon.value.discountValue)
            : 0.0;
    // couponDiscountAmount.value = isCouponToggled.value ? couponController.coupon.value.discountValue : 0.0;

    // Sum up the coupon discount and points discount
    return couponDiscountAmount + pointsDiscount;
  }

  double calculateGrandTotal(double subTotal) {
    // Step 1: Calculate total discount
    double totalDiscount = calculateTotalDiscount(subTotal);

    // Step 2: Adjust subtotal by subtracting the discount, clamping to avoid negative values
    double discountAdjustedSubTotal = (subTotal - totalDiscount).clamp(0.0, double.infinity);

    // Step 3: Check if tax and shipping are enabled
    double taxAmount = 0.0;
    double shippingCost = 0.0;

    if (settingsController.settings.value.isTaxShippingEnabled) {
      // Step 3a: Calculate tax based on the subtotal
      taxAmount = getTaxAmount(subTotal);

      // Step 3b: Get the shipping cost based on the adjusted subtotal
      shippingCost = getShippingCost(discountAdjustedSubTotal);
    }

    // Step 4: Calculate the grand total by summing the adjusted subtotal, tax, and shipping
    return discountAdjustedSubTotal + taxAmount + shippingCost;
  }
}
