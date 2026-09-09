/// Alışveriş listesi — "Siparişlerim" ekranının gövdesi.
///
/// 🔴 **Liste GRUP başına sayfalanır.** Bir ödeme = bir alışveriş (grup) +
/// şirket başına bir sipariş; müşteri hem alışverişin bütününü (numara,
/// tarih, toplam, ödeme durumu) hem de her şirket siparişini **kendi
/// durumuyla** görür. Grup mantığı düz listeye indirgenmez.
///
/// 🔴 **Kalemler talep üzerine açılır.** 40 siparişlik bir listede kalemleri
/// önden çekmek 40 ek istek demekti; satır açıldığında `GET /order/{id}` bir
/// kez çağrılır ve `OrderController.orderItems` önbelleğinde kalır (web
/// `pages/account-orders.js` ile aynı davranış).
///
/// 🔴 **"Ödemeyi tamamla" düğmesi `transfer_only` modunda HİÇ ÇİZİLMEZ:**
/// sunucu o modda `payments/epay-token` ucuna 409 (`payment_disabled`)
/// dönüyor ve müşteri o hata ekranını görmemeli.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/public_settings_controller.dart';
import '../../../controllers/product/order_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/order_group_model.dart';
import '../../../models/order_model.dart';
import 'order_badges.dart';
import 'order_payment_gate.dart';
import '../../../../../common/widgets/loaders/delayed_loader.dart';

/// Bir sayfada kaç **alışveriş** gösterilir (web `PER_PAGE` ile aynı).
const int _kGroupsPerPage = 10;

class TOrderListItems extends StatefulWidget {
  const TOrderListItems({super.key});

  @override
  State<TOrderListItems> createState() => _TOrderListItemsState();
}

class _TOrderListItemsState extends State<TOrderListItems> {
  late final OrderController controller;
  late Future<List<OrderGroupModel>> _future;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OrderController());
    _future = controller.fetchUserOrderGroups();

    // Ödeme modu tazelenir: "ödemeyi tamamla" düğmesinin çizilip
    // çizilmeyeceğini bu belirliyor ve anahtar sunucudan çevrilmiş olabilir.
    PublicSettingsController.instance.reload();
  }

  /// Listeyi baştan çeker (aşağı çekme ve ödeme dönüşü için).
  Future<void> _refresh() async {
    final future = controller.fetchUserOrderGroups();
    setState(() {
      _future = future;
      _page = 1;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderGroupModel>>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TDelayedLoader();
        }

        final groups = snapshot.data ?? const <OrderGroupModel>[];
        if (groups.isEmpty) {
          return TEmptyState(
            icon: Iconsax.box,
            title: TTexts.whoopsNoOrder.tr,
            message: TTexts.ordersSubTitle.tr,
            actionText: TTexts.letsFillIt.tr,
            onAction: () => Get.offAllNamed(TRoutes.homeMenu),
          );
        }

        // Sayfalama istemcide: grup ucu bütün grupları tek seferde döndürüyor.
        final int totalPages = (groups.length + _kGroupsPerPage - 1) ~/ _kGroupsPerPage;
        final int page = _page > totalPages ? totalPages : _page;
        final int start = (page - 1) * _kGroupsPerPage;
        final int end = start + _kGroupsPerPage > groups.length ? groups.length : start + _kGroupsPerPage;
        final slice = groups.sublist(start, end);

        return RefreshIndicator(
          color: TColors.primary,
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: slice.length + (totalPages > 1 ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (_, index) {
              if (index >= slice.length) {
                return _Pager(
                  page: page,
                  totalPages: totalPages,
                  onSelect: (value) => setState(() => _page = value),
                );
              }
              return _PurchaseCard(group: slice[index], controller: controller);
            },
          ),
        );
      },
    );
  }
}

/// Bir alışveriş: grup başlığı + (açılınca) şirket başına sipariş satırı.
///
/// 🔴 Şirket siparişleri ilk açılışta **KAPALI**. Eskiden her alışverişin
/// bütün satırları açıktı: iki-üç şirkete bölünmüş birkaç alışveriş listeyi
/// metrelerce uzatıyor, kullanıcı kendi sipariş geçmişini kaydırarak
/// tarayamıyordu. Kart artık özetini gösteriyor (numara · tarih · tutar ·
/// ödeme durumu), ayrıntı isteyen aşağı açıyor.
class _PurchaseCard extends StatefulWidget {
  const _PurchaseCard({required this.group, required this.controller});

  final OrderGroupModel group;
  final OrderController controller;

  @override
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final group = widget.group;

    return TRoundedContainer(
      showBorder: true,
      padding: EdgeInsets.zero,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PurchaseHeader(group: group, controller: widget.controller),

          /// -- Aç/kapa şeridi
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      TTexts.ordersInPurchase.trParams({'count': '${group.orders.length}'}),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    size: TSizes.iconSm,
                    color: TColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            for (var i = 0; i < group.orders.length; i++)
              _OrderRow(
                order: group.orders[i],
                siblings: group.orders.length,
                controller: widget.controller,
              ),
        ],
      ),
    );
  }
}

/// Alışveriş başlığı: numara · tarih · sipariş sayısı · ödeme durumu · tutar ·
/// "görüntüle" ve (koşulluysa) "ödemeyi tamamla".
class _PurchaseHeader extends StatelessWidget {
  const _PurchaseHeader({required this.group, required this.controller});

  final OrderGroupModel group;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.lightContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusMd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.receipt_2, size: TSizes.iconSm, color: TColors.primary),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  '${TTexts.purchaseNumber.tr}: ${group.displayNumber}',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TStatusBadge.payment(status: group.paymentStatus),
            ],
          ),
          const SizedBox(height: TSizes.xs),

          /// Tarih + (bölünmüşse) sipariş sayısı
          Row(
            children: [
              const Icon(Iconsax.calendar_1, size: TSizes.iconXs, color: TColors.darkGrey),
              const SizedBox(width: TSizes.xs),
              Flexible(
                child: Text(
                  TFormatter.formatDate(group.createdAt),
                  style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),

          /// Tutar + eylemler
          Row(
            children: [
              Expanded(
                child: Text(
                  TFormatter.formatCurrency(group.totalAmount),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Get.toNamed(TRoutes.orderDetail, arguments: group),
                child: Text(TTexts.view.tr),
              ),

              /// 🔴 `transfer_only` modunda düğme HİÇ çizilmez (uç 409 döner).
              /// `Obx` genel anahtarı izliyor: sunucu modu değiştirirse düğme
              /// kendiliğinden kaybolur.
              Obx(() {
                if (!canPayGroup(group)) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: TSizes.sm),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => controller.completePaymentForGroup(group),
                    icon: const Icon(Iconsax.card, size: TSizes.iconXs),
                    label: Text(TTexts.completePayment.tr),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tek bir şirket siparişi: şirket rozeti · numara · durum · tutar · kalemler.
class _OrderRow extends StatefulWidget {
  const _OrderRow({required this.order, required this.siblings, required this.controller});

  final OrderModel order;
  final int siblings;
  final OrderController controller;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    // Kalemler yalnız ilk açılışta çekilir; önbellekte varsa istek atılmaz.
    // Grup ucu kalemleri zaten gönderdiyse ağa hiç çıkılmaz.
    if (_expanded) {
      widget.controller.loadOrderItems(widget.order.id, known: widget.order.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return Container(
      decoration: const BoxDecoration(
        // Açılan her satır üstündekinden çizgiyle ayrılır; kapalı kartta
        // hiç çizilmediği için alt çizgi yerine ÜST çizgi kullanılıyor.
        border: Border(
          top: BorderSide(color: TColors.borderSecondary, width: TSizes.dividerHeight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Get.toNamed(TRoutes.orderDetail, arguments: order),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      /// Şirket rozeti — yalnız alışveriş bölünmüşse. Tek
                      /// siparişte şirket adı gürültüdür.
                      if (widget.siblings > 1 && order.hasCompany) ...[
                        TStatusBadge(
                          label: order.companyLabel,
                          tone: const TStatusTone(TColors.primary, TColors.accent),
                        ),
                        const SizedBox(width: TSizes.sm),
                      ],
                      Expanded(
                        child: Text(
                          order.displayId,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: TSizes.sm),
                      TStatusBadge.order(status: order.statusKey),
                    ],
                  ),
                  const SizedBox(height: TSizes.sm),
                  Row(
                    children: [
                      const Icon(Iconsax.calendar_1, size: TSizes.iconXs, color: TColors.darkGrey),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        order.formattedOrderDate,
                        style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        TFormatter.formatCurrency(order.totalAmount),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// Kalemler açma/kapama
          Padding(
            padding: const EdgeInsets.only(left: TSizes.sm, right: TSizes.sm, bottom: TSizes.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _toggle,
                icon: Icon(_expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1, size: TSizes.iconXs),
                label: Text(TTexts.orderItems.tr),
              ),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.md, 0, TSizes.md, TSizes.md),
              child: Obx(() {
                if (widget.controller.loadingOrderItems.contains(order.id)) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: TSizes.md),
                    child: Center(child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2)),
                  );
                }

                final items = widget.controller.orderItems[order.id];
                if (items == null) {
                  // Önbellekte yok ve yükleme bitti → istek başarısız oldu.
                  return Text(
                    TTexts.orderItemsLoadError.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: TColors.error),
                  );
                }
                if (items.isEmpty) {
                  return Text(
                    TTexts.orderNoItems.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                  );
                }
                return Column(children: items.map((item) => _ItemLine(item: item)).toList());
              }),
            ),
        ],
      ),
    );
  }
}

/// Accordion içindeki tek kalem satırı: görsel · ad · adet × birim · satır tutarı.
class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = item.image ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TColors.lightContainer,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
            ),
            clipBehavior: Clip.antiAlias,
            child: image.isEmpty
                ? const Icon(Iconsax.image, size: TSizes.iconSm, color: TColors.darkGrey)
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Iconsax.image, size: TSizes.iconSm, color: TColors.darkGrey),
                  ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                Text(
                  '${item.quantity} × ${TFormatter.formatCurrency(item.unitPrice)}',
                  style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Text(
            TFormatter.formatCurrency(item.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Sayfa numaraları (web `pagerHtml` karşılığı).
class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.totalPages, required this.onSelect});

  final int page;
  final int totalPages;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // 🔴 Alt pay: sayfa numaraları ekranın dibine yapışıyordu, son sayfaya
    // basmak için parmağı kenara dayamak gerekiyordu.
    return Padding(
      padding: const EdgeInsets.only(top: TSizes.md, bottom: TSizes.spaceBtwSections),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: TSizes.sm,
        runSpacing: TSizes.sm,
        children: List.generate(totalPages, (i) {
          final number = i + 1;
          final active = number == page;
          return SizedBox(
            width: 40,
            height: 36,
            child: active
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    // Seçili sayfaya basmak bir şey yapmaz; düğme yine de
                    // ETKİN kalır — devre dışı hâli "seçili"yi değil
                    // "kullanılamaz"ı anlatırdı.
                    onPressed: () {},
                    child: Text('$number'),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => onSelect(number),
                    child: Text('$number'),
                  ),
          );
        }),
      ),
    );
  }
}
