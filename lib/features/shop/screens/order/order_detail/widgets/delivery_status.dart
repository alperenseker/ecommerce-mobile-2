/// Teslimat durumu: ilerleme çubuğu + kargo bilgisi.
///
/// 🔴 **İlerleme çubuğu web ile aynı beş adımdır** (`Order.FLOW`):
/// `pending → confirmed → processing → shipped → delivered`. `confirmed`
/// adımı `t_utils`'in `OrderStatus` enum'unda YOK; backend ödeme sonrası
/// siparişi o duruma geçiriyor, bu yüzden çubuk **ham durum** üzerinden
/// çalışır. İptal/iade durumunda çubuk **hiç çizilmez** — o siparişin akışı
/// bitmiştir, yarı dolu bir çubuk yanıltıcı olurdu; yerine tek bir durum
/// satırı gösterilir.
///
/// 🔴 **Kargo bilgisi yalnız sunucu doldurduysa çizilir** (firma, takip no,
/// gönderim/teslim tarihi). Referans mobil burada `ShippingInfo` nesnesini
/// okuyordu ve sunucu onu doldurmadığı için ekranda boş bir kutu ve
/// `UniqueKey` ile üretilmiş sahte bir takip numarası duruyordu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/formatters/formatter.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../models/order_model.dart';
import '../../widgets/order_badges.dart';
import 'heading_with_icon.dart';

class DeliveryStatus extends StatelessWidget {
  const DeliveryStatus({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          THeadingWithIcon(title: TTexts.deliveryStatus.tr, icon: Iconsax.truck),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// İlerleme çubuğu ya da (akış bittiyse) tek durum satırı.
          TOrderFlowBar(status: order.statusKey),

          /// Kargo bilgisi — sunucu hiçbir alanı doldurmadıysa bölüm yok.
          if (order.hasShippingInfo) ...[
            const SizedBox(height: TSizes.spaceBtwItems),
            const Divider(height: TSizes.dividerHeight),
            const SizedBox(height: TSizes.spaceBtwItems),
            if (order.shippingCompany.isNotEmpty)
              _InfoRow(label: TTexts.shippingCompany.tr, value: order.shippingCompany),
            if (order.trackingNumber.isNotEmpty)
              _InfoRow(label: TTexts.trackingNumber.tr, value: order.trackingNumber, monospace: true),
            if (order.shippingDate != null)
              _InfoRow(label: TTexts.shippedAt.tr, value: TFormatter.formatDateAndTime(order.shippingDate)),
            if (order.deliveredAt != null)
              _InfoRow(label: TTexts.deliveredAt.tr, value: TFormatter.formatDateAndTime(order.deliveredAt)),
          ],
        ],
      ),
    );
  }
}

/// Sipariş ilerleme çubuğu.
///
/// İptal/iade durumunda çizilmez; onun yerine [OrderStatusTile] ile tek bir
/// satır gösterilir.
class TOrderFlowBar extends StatelessWidget {
  const TOrderFlowBar({super.key, required this.status});

  /// HAM sipariş durumu (`OrderModel.statusKey`).
  final String status;

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();

    // Akışın dışındaki durumlar: iptal, iade, para iadesi. Çubuk çizilmez.
    if (!kOrderFlow.contains(key)) {
      return OrderStatusTile(
        icon: _terminalIcon(key),
        title: orderStatusLabel(key),
        status: TTexts.completed.tr,
        isActive: true,
        isCompleted: true,
        tone: orderStatusTone(key),
      );
    }

    final currentIndex = kOrderFlow.indexOf(key);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(kOrderFlow.length, (i) {
        final step = kOrderFlow[i];
        final done = i < currentIndex;
        final current = i == currentIndex;
        final color = done || current ? TColors.primary : TColors.borderPrimary;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  // Sol bağlantı çizgisi (ilk adımda yok)
                  Expanded(
                    child: i == 0
                        ? const SizedBox.shrink()
                        : Container(height: 2, color: i <= currentIndex ? TColors.primary : TColors.borderPrimary),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || current ? TColors.primary : TColors.softGrey,
                    ),
                    child: done
                        ? const Icon(Iconsax.tick_circle, size: 14, color: TColors.white)
                        : Text(
                            '${i + 1}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: current ? TColors.white : TColors.darkGrey,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  // Sağ bağlantı çizgisi (son adımda yok)
                  Expanded(
                    child: i == kOrderFlow.length - 1
                        ? const SizedBox.shrink()
                        : Container(height: 2, color: i < currentIndex ? TColors.primary : TColors.borderPrimary),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.xs),
              Text(
                orderStatusLabel(step),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: done || current ? color : TColors.textSecondary,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }

  IconData _terminalIcon(String key) {
    switch (key) {
      case 'canceled':
      case 'cancelled':
        return Iconsax.close_circle;
      case 'returned':
        return Iconsax.undo;
      case 'refunded':
        return Iconsax.money_send;
      default:
        return Iconsax.info_circle;
    }
  }
}

/// Tek durum satırı — akışın dışındaki (iptal/iade) siparişlerde kullanılır.
class OrderStatusTile extends StatelessWidget {
  const OrderStatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.isActive,
    required this.isCompleted,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool isActive;
  final bool isCompleted;
  final TStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = tone ?? const TStatusTone(TColors.primary, TColors.accent);
    final muted = !isActive && !isCompleted;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.background),
          child: Icon(icon, size: TSizes.iconSm, color: muted ? TColors.darkGrey : colors.foreground),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                status,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Etiket–değer satırı (kargo bilgisi).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.monospace = false});

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs / 2),
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
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontFamily: monospace ? 'monospace' : null),
            ),
          ),
        ],
      ),
    );
  }
}
