/// Sipariş detayı — **iki görünüm, tek ekran**.
///
///   • **Alışveriş (grup) görünümü:** argüman bir [OrderGroupModel] ise ya da
///     `groupId` verildiyse. Bir ödeme = bir alışveriş; müşteri bütünü görür.
///   • **Tek sipariş görünümü:** argüman bir [OrderModel] ise ya da `id`
///     parametresi verildiyse (bildirim/derin bağlantı bu yolu kullanır).
///
/// 🔴 **`transfer_only` modunda "Ödemeyi tamamla" HİÇ ÇİZİLMEZ:** sunucu o
/// modda `payments/epay-token` ucuna 409 (`payment_disabled`) dönüyor.
/// Bağlantı eski bir bildirimden gelmiş olabilir; müşteri hata ekranı
/// görmemeli. O modda bunun yerine **şirket başına rekvizitler** gösterilir.
///
/// 🔴 **ePay dönüşünde ödeme durumu YOKLANIR.** Halyk'in `postLink` çağrısı
/// backend'e sunucu-sunucu geliyor ve birkaç saniye gecikebiliyor; WebView'in
/// istemci tarafı yönlendirmesine güvenilmez. Durum `paid`/`failed` olana
/// kadar **8 kez × 3 sn** sorulur (web `trackPayment()` ile aynı ritim).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_utils/utils/constants/enums.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/popups/dialogs.dart';
import '../../../../personalization/controllers/public_settings_controller.dart';
import '../../../controllers/product/order_controller.dart';
import '../../../controllers/review_controller.dart';
import '../../../models/order_group_model.dart';
import '../../../models/order_model.dart';
import '../../checkout/widgets/bank_transfer_details.dart';
import '../../return_request/create_return_request_screen.dart';
import 'widgets/addresses.dart';
import 'widgets/delivery_status.dart';
import 'widgets/order_history_widget.dart';
import 'widgets/order_status.dart';
import 'widgets/payment_details.dart';
import '../widgets/order_payment_gate.dart';
import 'widgets/purchase_group_view.dart';

class OrderDetail extends StatefulWidget {
  const OrderDetail({super.key});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  /// Yoklama ritmi — web `trackPayment()` ile aynı (~24 sn).
  static const int _maxAttempts = 8;
  static const Duration _interval = Duration(seconds: 3);

  late final OrderController controller;

  OrderModel? _order;
  OrderGroupModel? _group;
  bool _loading = true;
  bool _notFound = false;

  /// ePay dönüşünde ödeme durumu şeridi + yoklama.
  bool _verifyPayment = false;
  int _attempts = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OrderController());
    // Değerlendirme düğmeleri kalem satırlarında; controller ekranla birlikte
    // kurulur ki `OrderStatusWidget` onu bulabilsin.
    Get.put(ReviewController());

    // FAZ 34 — ödeme modu tazelenir: "Ödemeyi tamamla" düğmesinin ve havale
    // rekvizitlerinin çizilip çizilmeyeceğini bu belirliyor.
    PublicSettingsController.instance.reload();

    _resolveArguments();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Argümanları çözer ve gerekiyorsa kaydı sunucudan çeker.
  ///
  /// Desteklenen argümanlar:
  ///   • `OrderModel` / `OrderGroupModel` (liste ekranından)
  ///   • `Map`: `order`, `group`, `orderId`, `groupId`, `verifyPayment`
  ///   • `Get.parameters['id']` (bildirim / derin bağlantı)
  Future<void> _resolveArguments() async {
    final args = Get.arguments;

    String orderId = Get.parameters['id'] ?? '';
    String groupId = '';

    if (args is OrderModel) {
      _order = args;
      orderId = args.id;
    } else if (args is OrderGroupModel) {
      _group = args;
      groupId = args.groupId;
    } else if (args is Map) {
      final order = args['order'];
      final group = args['group'];
      if (order is OrderModel) _order = order;
      if (group is OrderGroupModel) _group = group;
      orderId = (args['orderId'] ?? _order?.id ?? orderId).toString();
      groupId = (args['groupId'] ?? _group?.groupId ?? '').toString();
      _verifyPayment = args['verifyPayment'] == true;
    }

    // Grup görünümü: elde grup yoksa kimliğiyle çekilir.
    if (_group == null && groupId.isNotEmpty) {
      _group = await controller.fetchGroup(groupId);
      if (_group == null) {
        _setNotFound();
        return;
      }
    }

    // Tek sipariş görünümü: elde sipariş yoksa (ya da kalemleri boşsa)
    // sunucudan çekilir. Liste ucundan gelen sipariş kalemleri taşımıyor.
    if (_group == null) {
      if (orderId.isEmpty) {
        _setNotFound();
        return;
      }
      if (_order == null || _order!.products.isEmpty) {
        try {
          final fetched = await controller.fetchSingleOrder(orderId);
          if (fetched.id.isNotEmpty) _order = fetched;
        } catch (_) {
          // Ağ hatası: elde bir sipariş varsa onunla devam edilir.
        }
      }
      if (_order == null || _order!.id.isEmpty) {
        _setNotFound();
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (_verifyPayment && _currentPaymentStatus != PaymentStatus.paid) _poll();
  }

  void _setNotFound() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notFound = true;
    });
  }

  PaymentStatus get _currentPaymentStatus =>
      _group?.paymentStatus ?? _order?.paymentStatus ?? PaymentStatus.unpaid;

  /// Ödeme durumunu yoklar (postLink gecikmesi için).
  Future<void> _poll() async {
    try {
      if (_group != null) {
        final refreshed = await controller.fetchGroup(_group!.groupId);
        if (refreshed != null && mounted) setState(() => _group = refreshed);
      } else if (_order != null) {
        final refreshed = await controller.fetchSingleOrder(_order!.id);
        if (mounted) setState(() => _order = refreshed);
      }
    } catch (_) {
      // Geçici hata — mevcut durum korunur ve yeniden denenir.
    }

    if (!mounted) return;
    final status = _currentPaymentStatus;
    if (status == PaymentStatus.paid || status == PaymentStatus.failed) return;

    _attempts++;
    if (_attempts < _maxAttempts) _timer = Timer(_interval, _poll);
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _group != null;

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(isGroup ? TTexts.purchaseDetails.tr : TTexts.orderDetails.tr),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TColors.primary))
          : _notFound
              ? TEmptyState(
                  icon: Iconsax.receipt_search,
                  title: isGroup ? TTexts.purchaseNotFound.tr : TTexts.orderNotFound.tr,
                  actionText: TTexts.backToOrders.tr,
                  onAction: () => Get.offNamed(TRoutes.order),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: isGroup ? _buildGroup(context, _group!) : _buildOrder(context, _order!),
                ),
    );
  }

  // ─── Alışveriş (grup) görünümü ───────────────────────────────────────────

  Widget _buildGroup(BuildContext context, OrderGroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_verifyPayment) ...[
          _PaymentStatusBanner(status: group.paymentStatus),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],

        PurchaseGroupView(group: group),

        /// 🔴 Ödeme alışverişin TAMAMINI kapatır (tek çekim).
        Obx(() => _payAction(
              context,
              visible: canPayGroup(group),
              amount: group.totalAmount,
              onPressed: () => controller.completePaymentForGroup(group),
              orderCount: group.orderCount,
            )),

        /// Havale rekvizitleri — **şirket başına bir blok** (FAZ 07'nin
        /// bileşeni). Grup birden çok şirkete bölündüyse müşteri her şirkete
        /// ayrı ödeme yapacak; tek blok hangi hesaba ne kadar yatıracağını
        /// gizlerdi.
        Obx(() {
          if (!bankDetailsVisibleForGroup(group)) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
            child: TBankTransferDetails(
              blocks: group.orders
                  .map((o) => TBankTransferBlock(
                        code: o.erpSourceCode,
                        name: o.erpSourceName,
                        amount: o.totalAmount,
                      ))
                  .toList(),
              noteKey: TTexts.bankTransferOrderNote,
            ),
          );
        }),

        const SizedBox(height: TSizes.spaceBtwSections),
        _backActions(context),
      ],
    );
  }

  // ─── Tek sipariş görünümü ────────────────────────────────────────────────

  Widget _buildOrder(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_verifyPayment) ...[
          _PaymentStatusBanner(status: order.paymentStatus),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],

        OrderStatusWidget(order: order),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Bu sipariş bölünmüş bir alışverişin parçasıysa bütününe gidiş.
        if (order.groupId.isNotEmpty) ...[
          _wholePurchaseLink(context, order),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],

        PaymentDetail(order: order),
        const SizedBox(height: TSizes.spaceBtwItems),

        DeliveryStatus(order: order),
        const SizedBox(height: TSizes.spaceBtwItems),

        OrderAddresses(order: order),
        const SizedBox(height: TSizes.spaceBtwItems),

        if (order.id.isNotEmpty) OrderHistoryWidget(orderId: order.id),

        /// Ödenmemiş kart siparişinde ePay'i yeniden aç.
        Obx(() => _payAction(
              context,
              visible: canPayOrder(order),
              amount: order.totalAmount,
              onPressed: () => controller.completePayment(order),
              orderCount: order.groupOrderCount ?? 1,
            )),

        /// Ödenmemiş havale siparişinde o **şirketin** rekvizitleri. Sipariş
        /// şirket başına bölündüğü için tek blok.
        Obx(() {
          if (!bankDetailsVisibleForOrder(order)) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
            child: TBankTransferDetails(
              blocks: [
                TBankTransferBlock(
                  code: order.erpSourceCode,
                  name: order.erpSourceName,
                  amount: order.totalAmount,
                ),
              ],
              noteKey: TTexts.bankTransferOrderNote,
            ),
          );
        }),

        const SizedBox(height: TSizes.spaceBtwItems),

        /// Yalnız beklemedeki sipariş iptal edilebilir.
        if (order.statusKey == 'pending')
          Padding(
            padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
            child: OutlinedButton(
              onPressed: () => _confirmCancel(order),
              child: Text(TTexts.cancelOrder.tr),
            ),
          ),

        /// İade yalnız TESLİM EDİLMİŞ siparişten açılır.
        if (order.orderStatus == OrderStatus.delivered)
          Padding(
            padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
            child: OutlinedButton(
              onPressed: () => Get.to(() => CreateReturnRequestScreen(order: order)),
              child: Text(TTexts.returnOrder.tr),
            ),
          ),

        const SizedBox(height: TSizes.spaceBtwItems),
        _backActions(context),
      ],
    );
  }

  // ─── Ortak parçalar ──────────────────────────────────────────────────────

  Widget _wholePurchaseLink(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: TColors.infoSoft,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Iconsax.info_circle, size: TSizes.iconSm, color: TColors.info),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              order.isPartOfSplitPurchase
                  ? TTexts.partOfPurchase.trParams({'count': '${order.groupOrderCount}'})
                  : TTexts.purchaseNumber.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.info),
            ),
          ),
          TextButton(
            // Aynı rota, bu kez grup argümanıyla.
            onPressed: () => Get.toNamed(TRoutes.orderDetail, arguments: {'groupId': order.groupId}),
            child: Text(TTexts.viewWholePurchase.tr),
          ),
        ],
      ),
    );
  }

  Widget _payAction(
    BuildContext context, {
    required bool visible,
    required double amount,
    required VoidCallback onPressed,
    required int orderCount,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Bölünmüş alışverişte müşteri tek siparişin tutarını ödediğini
          /// sanmasın diye düğmenin üstüne bilgi satırı konuyor.
          if (orderCount > 1) ...[
            Text(
              TTexts.paymentCoversOrders.trParams({'count': '$orderCount'}),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.sm),
          ],
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Iconsax.card, size: TSizes.iconSm),
            label: Text(TTexts.completePayment.tr),
          ),
        ],
      ),
    );
  }

  Widget _backActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => Get.offNamed(TRoutes.order),
          child: Text(TTexts.backToOrders.tr),
        ),
        const SizedBox(height: TSizes.sm),
        TextButton(
          onPressed: () => Get.offAllNamed(TRoutes.homeMenu),
          child: Text(TTexts.continueShopping.tr),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(OrderModel order) async {
    await TDialogs.confirm(
      title: TTexts.cancelOrder.tr,
      message: TTexts.cancelOrderConfirm.tr,
      icon: Iconsax.close_circle,
      isDestructive: true,
      onConfirm: () async {
        await controller.cancelOrder(order);
        // İptalden sonra sunucudaki güncel hâl okunur; ekran eski durumu
        // göstermeye devam etmesin.
        try {
          final refreshed = await controller.fetchSingleOrder(order.id);
          if (mounted) setState(() => _order = refreshed);
        } catch (_) {}
      },
    );
  }
}

/// Ödeme durumu şeridi (doğrulanıyor → ödendi → başarısız); onay ekranındaki
/// şeritle aynı üç hâl.
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
