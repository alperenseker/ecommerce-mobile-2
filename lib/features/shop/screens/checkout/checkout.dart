/// Ödeme ekranı.
///
/// Ekranın iki kritik kuralı (ikisi de paranın kendisiyle ilgili):
///
/// 🔴 **1. Ödeme modu ekran açılırken bir kez okunur ve sayfa ömrü boyunca
/// sabit kalır** ([CheckoutController.capturePaymentMode]). `transfer_only`
/// modunda "kartla öde" HİÇ çizilmez: sunucu o modda `payments/epay-token`
/// ucuna 409 dönüyor ve müşteri o hata ekranını görmemeli. Anahtar sipariş
/// oluşturmadan hemen önce bir kez daha tazelenir (OrderController).
///
/// 🔴 **2. "Özel kullanıcı" ayrımı `HasCreditLine` iledir.**
/// `CanBypassPayment` `transfer_only` modunda HERKESE true dönüyor; ona bakan
/// kod hem kredisiz müşteriye "kredi limitiniz" yazar hem de minimum sipariş
/// tutarı kontrolünü tümden düşürürdü.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/products/cart/billing_amount_section.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/erp_source_helper.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/checkout_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../cart/widgets/cart_items.dart';
import 'widgets/bank_transfer_details.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_payment_section.dart';
// Elle kart girişi formu BİLEREK bağlı değil: kart bilgisi uygulamada
// toplanmıyor, ödeme Halyk ePay'in güvenli sayfasında yapılıyor.
// import 'widgets/card_payment_form.dart';
import 'widgets/epay_secure_note.dart';
import 'widgets/order_account_panel.dart';
import 'widgets/payment_mode_note.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutController checkoutController;
  late final AddressController addressController;
  late final OrderController orderController;
  final cartController = CartController.instance;

  @override
  void initState() {
    super.initState();
    // Adres controller'ı sipariş controller'ından ÖNCE kurulmalı:
    // `OrderController` kurulurken `AddressController.instance` okuyor.
    addressController = Get.isRegistered<AddressController>()
        ? AddressController.instance
        : Get.put(AddressController());
    checkoutController = Get.put(CheckoutController());
    orderController = Get.put(OrderController());

    // Ödeme modu ve adresler ekran açılırken bir kez okunur.
    checkoutController.capturePaymentMode(force: true);
    addressController.loadDefaultAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      // FAZ 09 — referansta başlıkta bildirim zili var; `TRoutes.notification`
      // o fazda açılacak, o zamana kadar çizilmiyor (boş rotaya götürürdü):
      //   showActions: true, actionIcon: Iconsax.notification,
      //   actionOnPressed: () => Get.toNamed(TRoutes.notification),
      appBar: TAppBar(
        showActions: false,
        showBackArrow: true,
        showSkipButton: false,
        title: Text(TTexts.checkOut.tr),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -- Sepetteki kalemler (salt okunur). Sepette birden çok
              /// şirket varsa "N ayrı siparişe bölünecek" notu da burada.
              const TCartItems(showAddRemoveButtons: false),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Tutar özeti
              TRoundedContainer(
                showBorder: true,
                radius: TSizes.borderRadiusMd,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: dark ? TColors.dark : TColors.white,
                child: Obx(
                  // Sepet web ile paylaşılıyor ve bu ekran açıkken yeniden
                  // eşitlenebilir; rakamlar onu izlemek zorunda.
                  () => TBillingAmountSection(subTotal: cartController.totalCartPrice.value),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Ödeme bölümü (mod + kredi durumuna göre üç ayrı dal)
              TRoundedContainer(
                showBorder: true,
                radius: TSizes.borderRadiusMd,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: dark ? TColors.dark : TColors.white,
                child: Obx(() => _paymentSection(context)),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Adresler
              TRoundedContainer(
                showBorder: true,
                radius: TSizes.borderRadiusMd,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: dark ? TColors.dark : TColors.white,
                child: _addressSection(context),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Sipariş notu (sunucuya `CustomerNote` olarak gider)
              TSectionHeading(title: TTexts.orderNotes.tr, showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),
              TextField(
                controller: checkoutController.customerNote,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(hintText: TTexts.orderNotesPlaceholder.tr),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),

      /// -- Sipariş düğmesi
      bottomNavigationBar: _bottomBar(context, dark),
    );
  }

  /// Ödeme bölümü. **Üç dal, bu sırayla:**
  ///   1. kredili müşteri (`HasCreditLine`) → hesap paneli + rekvizitler,
  ///   2. genel `transfer_only` → havale notu + rekvizitler (kredi metni YOK),
  ///   3. diğer herkes → yöntem seçici; kart seçiliyse ePay güvenli notu.
  Widget _paymentSection(BuildContext context) {
    final hasCreditLine = checkoutController.hasCreditLine;
    final transferOnly = checkoutController.isTransferOnly.value;

    // Rekvizitler sepetin şirket kırılımıyla çiziliyor — her şirketin kendi
    // hesabı ve o şirkete düşen tutar. Süzgeçsiz çağrı 12 satır döndürüyor;
    // tek düz liste müşteriye hangi hesaba yatıracağını söylemezdi.
    // Açıklama metni dala göre değişir; bu yüzden widget bir kez değil,
    // çağrıldığı yerde kuruluyor.
    TBankTransferDetails bankDetailsWith(String noteKey) => TBankTransferDetails(
          blocks: TErpSource.groupCartItems(cartController.cartItems)
              .map((g) => TBankTransferBlock(code: g.code, name: g.name, amount: g.subtotal))
              .toList(),
          noteKey: noteKey,
        );

    if (hasCreditLine) {
      // Kredili müşteri: kredi paneli + rekvizitler. Sipariş yönetici onayına
      // düşer (`pending_approval`), ödeme burada alınmaz.
      return Column(
        children: [
          TOrderAccountPanel(
            grandTotal: checkoutController.calculateGrandTotal(cartController.totalCartPrice.value),
          ),
          bankDetailsWith(TTexts.bankTransferNote),
        ],
      );
    }

    if (transferOnly) {
      // 🔴 Ödeme genel olarak havalede: kart seçeneği HİÇ çizilmez ve
      // kredi/limit ifadesi geçmez (müşterinin kredisi yok).
      return Column(
        children: [
          const TPaymentModeNote(),
          // 🔴 Açıklama BOŞ: hemen üstteki TPaymentModeNote aynı cümleyi
          // yazıyor, ikisi birden çizilince aynı paragraf ekranda iki kez
          // arka arkaya görünüyordu.
          bankDetailsWith(''),
        ],
      );
    }

    // `gateway` modundaki kredisiz müşteri: kart / havale / kapıda.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TBillingPaymentSection(),
        // Kart seçiliyse: kart bilgisinin nerede girileceğini söyleyen not.
        if (checkoutController.selectedMethodCode.value == TPaymentMethodCodes.card) ...[
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          const TEpaySecureNote(),
        ],
        // Havale seçiliyse rekvizitler burada da gösterilir; müşteri parayı
        // nereye yollayacağını sipariş vermeden görmeli.
        // Bu dalda TPaymentModeNote çizilmiyor; açıklama burada kalmalı.
        if (checkoutController.selectedMethodCode.value == TPaymentMethodCodes.bankTransfer)
          bankDetailsWith(TTexts.bankTransferOnlyNote),
      ],
    );
  }

  /// Adres bölümü.
  ///
  /// 🔴 **Şirket hesabında fatura adresi 1C'den gelir ve düzenlenemez**:
  /// "teslimatla aynı" onay kutusu çizilmez, fatura adresi kilitli gösterilir
  /// ve sunucuya teslimat adresinin kimliği gönderilir.
  Widget _addressSection(BuildContext context) {
    return Obx(() {
      final isCompany = addressController.isCorporate;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Teslimat adresi — her hesapta zorunlu.
          const TAddressSection(isBillingAddress: false),
          const SizedBox(height: TSizes.spaceBtwItems),
          const Divider(),

          if (isCompany) ...[
            /// Şirket: 1C'den gelen resmî fatura adresi, kilitli.
            const SizedBox(height: TSizes.spaceBtwItems),
            const TAddressSection(isBillingAddress: true, isLocked: true),
          ] else ...[
            /// Bireysel: "fatura adresi teslimatla aynı" seçeneği.
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(TTexts.billingAddressSubTitle.tr, style: Theme.of(context).textTheme.bodyMedium),
              value: addressController.billingSameAsShipping.value,
              onChanged: (value) => addressController.billingSameAsShipping.value = value ?? true,
            ),
            if (!addressController.billingSameAsShipping.value) ...[
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),
              const TAddressSection(isBillingAddress: true),
            ],
          ],
        ],
      );
    });
  }

  /// Alt çubuk: limit uyarısı + sipariş düğmesi.
  ///
  /// 🔴 Limit aşıldığında düğme **kapalı** ve üstünde sepet toplamı / kalan
  /// tutar yazan net bir mesaj var. Kapalı düğmeye basıp hata görmek yerine
  /// müşteri neyi düzeltmesi gerektiğini okumalı.
  Widget _bottomBar(BuildContext context, bool dark) {
    return Obx(() {
      final subTotal = cartController.totalCartPrice.value;
      final limits = checkoutController.evaluateLimits(subTotal);
      final isEmpty = subTotal <= 0;
      final blocked = isEmpty || !limits.canProceed;

      return Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.white,
          // TASARIM.md §5: gölge yok, ayrım 1px çizgi.
          border: const Border(top: BorderSide(color: TColors.borderSecondary)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!limits.canProceed) ...[
              TRoundedContainer(
                radius: TSizes.borderRadiusMd,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: TColors.errorSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.warning_2, color: TColors.error, size: TSizes.iconMd),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                    Expanded(
                      child: Text(
                        limits.message,
                        style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.darkerGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: blocked
                    ? (isEmpty
                        // Boş sepet ayrı bir mesaj hak ediyor: limit sorunu
                        // değil, ekranın burada işi kalmamış demek.
                        ? () => TLoaders.warningSnackBar(
                            title: TTexts.emptyCart.tr, message: TTexts.cartMessage.tr)
                        : null)
                    : () => orderController.processOrder(subTotal),
                child: Text(
                  '${TTexts.checkOut.tr}  '
                  '${TFormatter.formatCurrency(checkoutController.calculateGrandTotal(subTotal))}',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
