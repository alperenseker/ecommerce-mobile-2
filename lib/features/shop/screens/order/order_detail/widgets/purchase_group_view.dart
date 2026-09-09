/// Alışveriş (grup) görünümü — sipariş detayının `?groupId=` hâli.
///
/// 🔴 **Bir ödeme = bir alışveriş.** Grup başlığı alışverişin bütününü
/// (numara, tarih, toplam, ödeme durumu) gösterir; altında her şirketin
/// siparişi kendi durumu ve kendi ilerleme çubuğuyla ayrı bir kart olur.
/// Toplam GRUBUN toplamıdır — tek çekimde ödenen tutar budur.
///
/// Web `pages/order.js` → `renderGroup()` karşılığıdır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../../routes/routes.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/formatters/formatter.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../models/cart_item_model.dart';
import '../../../../models/order_group_model.dart';
import '../../../../models/order_model.dart';
import '../../widgets/order_badges.dart';
import 'delivery_status.dart';
import 'heading_with_icon.dart';

class PurchaseGroupView extends StatelessWidget {
  const PurchaseGroupView({super.key, required this.group});

  final OrderGroupModel group;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// -- Alışveriş özeti
        TRoundedContainer(
          showBorder: true,
          radius: TSizes.cardRadiusMd,
          backgroundColor: dark ? TColors.darkContainer : TColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THeadingWithIcon(title: TTexts.purchaseDetails.tr, icon: Iconsax.receipt_2),
              const SizedBox(height: TSizes.spaceBtwItems),
              _row(context, TTexts.purchaseNumber.tr, group.displayNumber),
              _row(context, TTexts.placeOn.tr, TFormatter.formatDate(group.createdAt)),
              _row(context, TTexts.orderCount.tr, '${group.orderCount}'),
              _row(context, TTexts.grandTotal.tr, TFormatter.formatCurrency(group.totalAmount)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TTexts.paymentStatus.tr,
                      style: theme.textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                    ),
                    TStatusBadge.payment(status: group.paymentStatus),
                  ],
                ),
              ),

              /// Bölünmüş alışverişte müşteri tek çekimle N sipariş ödediğini
              /// bilmeli — yoksa "neden iki sipariş numarası var?" diye sorar.
              if (group.isSplit) ...[
                const SizedBox(height: TSizes.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: TColors.infoSoft,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.info_circle, size: TSizes.iconSm, color: TColors.info),
                      const SizedBox(width: TSizes.sm),
                      Expanded(
                        child: Text(
                          TTexts.groupSplitNote.trParams({'count': '${group.orderCount}'}),
                          style: theme.textTheme.bodyMedium?.copyWith(color: TColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// -- Alt siparişler (şirket başına)
        if (group.orders.isNotEmpty) ...[
          Text(TTexts.subOrders.tr, style: theme.textTheme.titleLarge),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          for (final order in group.orders) ...[
            _SubOrderCard(order: order),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        ],
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// Gruptaki tek şirket siparişi.
class _SubOrderCard extends StatelessWidget {
  const _SubOrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      padding: EdgeInsets.zero,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Başlık: şirket + durum
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey : TColors.lightContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusMd)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // Şirketi olmayan (eski) siparişte ad uydurulmaz; numara yazılır.
                    order.hasCompany ? order.companyLabel : order.displayId,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                TStatusBadge.order(status: order.statusKey),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${TTexts.orderNumber.tr}: ${order.displayId}',
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Sipariş numarası kırpıldığında tutara yapışıyordu.
                    const SizedBox(width: TSizes.sm),
                    Text(
                      TFormatter.formatCurrency(order.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Bu siparişin kendi ilerleme çubuğu — durumlar bağımsızdır.
                TOrderFlowBar(status: order.statusKey),

                /// Kalemler yalnız grup ucu gönderdiyse çizilir; göndermediyse
                /// müşteri "görüntüle" ile tek sipariş görünümüne geçer.
                if (order.products.isNotEmpty) ...[
                  const SizedBox(height: TSizes.spaceBtwItems),
                  const Divider(height: TSizes.dividerHeight),
                  const SizedBox(height: TSizes.sm),
                  for (final item in order.products) _GroupItemLine(item: item),
                ],

                const SizedBox(height: TSizes.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    // Aynı rota, bu kez tek sipariş argümanıyla açılıyor.
                    // 🔴 `preventDuplicates: false` ŞART: GetX varsayılan olarak
                    // hedef rota AÇIK olan rotayla aynıysa gitmiyor ve sessizce
                    // `null` dönüyor. Grup görünümü de tek sipariş görünümü de
                    // `/orderDetail` olduğu için düğme hiç çalışmıyordu.
                    onPressed: () => Get.toNamed(
                      TRoutes.orderDetail,
                      arguments: order,
                      preventDuplicates: false,
                    ),
                    icon: const Icon(Iconsax.export_3, size: TSizes.iconXs),
                    label: Text(TTexts.view.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grup görünümündeki kalem satırı.
class _GroupItemLine extends StatelessWidget {
  const _GroupItemLine({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        children: [
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
