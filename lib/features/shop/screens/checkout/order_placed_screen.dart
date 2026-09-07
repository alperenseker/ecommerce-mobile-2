/// Sipariş oluştuktan hemen sonra gösterilen onay ekranı.
///
/// 🔴 **Bir ödeme = bir GRUP + şirket başına bir sipariş.** Sepette iki
/// şirketin ürünü varsa sunucu siparişi böler; ekran o zaman "kaç sipariş
/// doğdu"yu ve **şirket başına** satırları gösterir, altında da tek çekimde
/// ödenecek toplamı. Tek şirketli alışverişte tek numaralı kutu kalır.
///
/// [verifyPayment] doğruyken (ePay akışı) web'deki `trackPaymentStatus()`
/// gibi davranır: backend'in `postLink` çağrısı ödeme ekranından dönüşten
/// birkaç saniye sonra gelebiliyor, bu yüzden WebView'in istemci tarafı
/// yönlendirmesine güvenilmez; `GET /order/{id}` yoklanır. Postlink grubun
/// TÜM siparişlerini tek işlemde ödendi yapıyor, o yüzden tek siparişi
/// yoklamak yeterlidir.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_utils/utils/constants/enums.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../controllers/product/order_controller.dart';
import '../../models/order_group_model.dart';
import '../../models/order_model.dart';

class OrderPlacedScreen extends StatefulWidget {
  const OrderPlacedScreen({
    super.key,
    required this.purchaseNumber,
    required this.orders,
    required this.totalAmount,
    required this.pollOrderId,
    this.initialPaymentStatus = PaymentStatus.unpaid,
    this.verifyPayment = false,
  });

  /// Yeni oluşturulan alışverişten kurar (ödeme akışı).
  factory OrderPlacedScreen.fromResult(
    CreateOrderResultModel result, {
    bool verifyPayment = false,
  }) =>
      OrderPlacedScreen(
        purchaseNumber: result.purchaseNumber,
        orders: result.orders,
        totalAmount: result.totalAmount,
        pollOrderId: result.pollOrderId,
        verifyPayment: verifyPayment,
      );

  /// Var olan bir alışverişten kurar ("ödemeyi tamamla" akışı).
  factory OrderPlacedScreen.fromGroup(
    OrderGroupModel group, {
    bool verifyPayment = false,
  }) =>
      OrderPlacedScreen(
        purchaseNumber: group.displayNumber,
        orders: group.orders,
        totalAmount: group.totalAmount,
        pollOrderId: group.orders.isNotEmpty ? group.orders.first.id : '',
        initialPaymentStatus: group.paymentStatus,
        verifyPayment: verifyPayment,
      );

  /// Müşterinin gördüğü alışveriş numarası (grup numarası).
  final String purchaseNumber;

  /// Bu alışverişte doğan siparişler. Boş olabilir (eski API yanıtı) — o zaman
  /// ekran yalnız numarayı gösterir.
  final List<OrderModel> orders;

  /// Alışverişin toplamı = tek çekimde ödenen tutar.
  final double totalAmount;

  /// Ödeme doğrulaması için yoklanacak sipariş kimliği.
  final String pollOrderId;

  final PaymentStatus initialPaymentStatus;
  final bool verifyPayment;

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  static const int _maxAttempts = 8; // ~24 sn, web'deki yoklama ritmiyle aynı
  static const Duration _interval = Duration(seconds: 3);

  late PaymentStatus _paymentStatus;
  int _attempts = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _paymentStatus = widget.initialPaymentStatus;
    if (widget.verifyPayment && _paymentStatus != PaymentStatus.paid && widget.pollOrderId.isNotEmpty) {
      _poll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _poll() async {
    try {
      final refreshed = await OrderController.instance.fetchSingleOrder(widget.pollOrderId);
      if (!mounted) return;
      setState(() => _paymentStatus = refreshed.paymentStatus);
    } catch (_) {
      // Geçici hata — mevcut durum korunur ve yeniden denenir.
    }

    if (!mounted) return;
    if (_paymentStatus == PaymentStatus.paid || _paymentStatus == PaymentStatus.failed) return;

    _attempts++;
    if (_attempts < _maxAttempts) {
      _timer = Timer(_interval, _poll);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alışveriş birden çok siparişe bölündüyse hepsi tek tek listelenir;
    // aksi hâlde tek numaralı kutu çizilir.
    final isSplit = widget.orders.length > 1;

    return PopScope(
      // Geri tuşuyla bu ekrandan çıkılmaz: sipariş oluştu, sepet temizlendi;
      // arkadaki ödeme ekranına dönmek anlamsız olurdu.
      canPop: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: TSpacingStyle.paddingWithAppBarHeight * 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: TSizes.spaceBtwSections),

                /// TASARIM.md §6: daire ikon + başlık + açıklama. Referanstaki
                /// Lottie animasyonu bu tasarım diline uymuyor; web'deki onay
                /// paneli de yeşil daire içinde onay imi kullanıyor.
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: TColors.successSoft, shape: BoxShape.circle),
                  child: const Icon(Iconsax.tick_circle, size: 48, color: TColors.success),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Başlık ve alt başlık
                Text(TTexts.orderPlaced.tr,
                    style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(TTexts.orderPlacedSubTitle.tr,
                    style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: TSizes.spaceBtwSections),

                if (widget.verifyPayment) ...[
                  _PaymentStatusBanner(status: _paymentStatus),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],

                if (isSplit)
                  _SplitPurchaseSummary(
                    purchaseNumber: widget.purchaseNumber,
                    orders: widget.orders,
                    totalAmount: widget.totalAmount,
                  )
                else
                  _SingleOrderNumber(
                    number: widget.orders.isNotEmpty ? widget.orders.first.displayId : widget.purchaseNumber,
                    company: widget.orders.isNotEmpty ? widget.orders.first.companyLabel : '',
                    totalAmount: widget.totalAmount,
                  ),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Sipariş takibine git — grup varsa grubu, yoksa tek siparişi
                /// açar (yönlendirmeyi [OrderController] çözüyor).
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => OrderController.instance.openPurchase(
                      orders: widget.orders,
                      purchaseNumber: widget.purchaseNumber,
                      pollOrderId: widget.pollOrderId,
                    ),
                    child: Text(TTexts.viewOrder.tr),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.offAllNamed(TRoutes.homeMenu),
                    child: Text(TTexts.continueShopping.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek siparişlik alışveriş: numara + (varsa) şirket adı + ödenecek tutar.
class _SingleOrderNumber extends StatelessWidget {
  const _SingleOrderNumber({required this.number, required this.company, required this.totalAmount});

  final String number;
  final String company;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.borderRadiusMd,
      padding: const EdgeInsets.all(TSizes.md),
      width: double.infinity,
      child: Column(
        children: [
          Text(TTexts.orderNo.tr, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: TSizes.xs),
          Text(
            number,
            style: Theme.of(context).textTheme.titleLarge!.apply(color: TColors.primary),
            textAlign: TextAlign.center,
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: TSizes.xs),
            Text(company, style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center),
          ],
          if (totalAmount > 0) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TTexts.totalPayment.tr, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  TFormatter.formatCurrency(totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: TColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bölünmüş alışveriş: alışveriş numarası, "N sipariş oluşturuldu" ve şirket
/// başına sipariş satırı + toplam ödeme.
class _SplitPurchaseSummary extends StatelessWidget {
  const _SplitPurchaseSummary({
    required this.purchaseNumber,
    required this.orders,
    required this.totalAmount,
  });

  final String purchaseNumber;
  final List<OrderModel> orders;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.borderRadiusMd,
      padding: const EdgeInsets.all(TSizes.md),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Alışveriş numarası
          Center(
            child: Column(
              children: [
                Text(TTexts.purchaseNumber.tr, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: TSizes.xs),
                Text(
                  purchaseNumber,
                  style: Theme.of(context).textTheme.titleLarge!.apply(color: TColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  TTexts.ordersCreated.trParams({'count': '${orders.length}'}),
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          const Divider(),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          /// Şirket başına sipariş
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.hasCompany)
                          Text(order.companyLabel, style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          order.displayId,
                          style: Theme.of(context).textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems / 2),
                  Text(TFormatter.formatCurrency(order.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),

          const SizedBox(height: TSizes.spaceBtwItems / 2),
          const Divider(),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          /// Toplam ödeme — **tek çekim**. Sipariş başına tutarla
          /// karıştırılmasın diye ayrı satır.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(TTexts.totalPayment.tr, style: Theme.of(context).textTheme.titleMedium),
              Text(
                TFormatter.formatCurrency(totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: TColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ödeme durumu şeridi (bekliyor/doğrulanıyor → ödendi → başarısız); web'deki
/// sipariş sayfasının şeridiyle aynı üç hâl.
class _PaymentStatusBanner extends StatelessWidget {
  const _PaymentStatusBanner({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    late Color background;
    late Color foreground;
    late IconData icon;
    late String message;

    switch (status) {
      case PaymentStatus.paid:
        background = TColors.successSoft;
        foreground = TColors.success;
        icon = Iconsax.tick_circle;
        message = TTexts.paymentConfirmed.tr;
        break;
      case PaymentStatus.failed:
        background = TColors.errorSoft;
        foreground = TColors.error;
        icon = Iconsax.close_circle;
        message = TTexts.paymentNotConfirmed.tr;
        break;
      default:
        background = TColors.warningSoft;
        foreground = TColors.warning;
        icon = Iconsax.timer_1;
        message = TTexts.paymentVerifying.tr;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: TSizes.sm),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
