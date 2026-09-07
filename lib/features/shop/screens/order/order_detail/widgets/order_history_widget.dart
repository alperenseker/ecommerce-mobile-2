/// Sipariş geçmişi / etkinlik listesi (`GET /order/{id}/history-detailed`).
///
/// Uç hata verirse ya da kayıt yoksa bölüm **hiç çizilmez**: boş bir "geçmiş"
/// başlığı kullanıcıya bir şey anlatmıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../../data/repositories/order/api_order_repository.dart';
import '../../../../../../data/repositories/order/order_repository.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/formatters/formatter.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../widgets/order_badges.dart';
import 'heading_with_icon.dart';

class OrderHistoryWidget extends StatelessWidget {
  const OrderHistoryWidget({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return FutureBuilder<List<OrderStatusHistoryDetailed>>(
      future: _fetch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final history = snapshot.data!;
        return TRoundedContainer(
          showBorder: true,
          radius: TSizes.cardRadiusMd,
          backgroundColor: dark ? TColors.darkContainer : TColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THeadingWithIcon(title: TTexts.orderHistory.tr, icon: Iconsax.activity),
              const SizedBox(height: TSizes.spaceBtwItems),
              ...List.generate(history.length, (i) {
                final item = history[i];
                final isLast = i == history.length - 1;
                return _HistoryTile(item: item, isLast: isLast);
              }),
            ],
          ),
        );
      },
    );
  }

  /// Geçmiş **isteğe bağlıdır**: uç yoksa/hata verirse boş liste döner ve
  /// sipariş detayı bu yüzden patlamaz.
  Future<List<OrderStatusHistoryDetailed>> _fetch() async {
    try {
      return await ApiOrderRepository.instance.fetchOrderHistoryDetailed(orderId: orderId);
    } catch (_) {
      return [];
    }
  }
}

/// Zaman çizgisi satırı: nokta + bağlantı çizgisi + durum + tarih.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.isLast});

  final OrderStatusHistoryDetailed item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // Sunucu geçmişi ESKİDEN YENİYE gönderiyor; son satır güncel durumdur.
    final tone = orderStatusTone(item.newStatus);
    final color = isLast ? tone.foreground : TColors.borderPrimary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(child: Center(child: Container(width: 2, color: TColors.borderSecondary))),
              ],
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          orderStatusLabel(item.newStatus),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isLast ? tone.foreground : null,
                              ),
                        ),
                      ),
                      const SizedBox(width: TSizes.sm),
                      Text(
                        TFormatter.formatDateAndTime(item.createdAt),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                      ),
                    ],
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.note!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (item.changedByUser != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${TTexts.historyChangedBy.tr} ${item.changedByUser!.fullName}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
