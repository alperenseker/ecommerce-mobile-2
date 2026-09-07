/// Ödeme özeti: ara toplam, kargo, vergi, indirim, toplam + yöntem ve durum.
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

class PaymentDetail extends StatelessWidget {
  const PaymentDetail({super.key, required this.order});

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
          THeadingWithIcon(title: TTexts.paymentDetails.tr, icon: Iconsax.bank),
          const SizedBox(height: TSizes.spaceBtwItems),

          _row(context, '${TTexts.subTotal.tr} (${order.itemCount} ${TTexts.items.tr})',
              TFormatter.formatCurrency(order.subTotal)),

          // Kargo bedeli 0 ise "ücretsiz" yazılır (web `summaryHtml`).
          _row(context, TTexts.deliveryFee.tr,
              order.shippingAmount > 0 ? TFormatter.formatCurrency(order.shippingAmount) : TTexts.free.tr),

          // Vergi satırı yalnız sunucu bir değer gönderdiyse çizilir; 0 KZT'lik
          // bir vergi satırı fişi kalabalıklaştırıyordu.
          if (order.taxAmount > 0)
            _row(context, TTexts.taxAmount.tr, TFormatter.formatCurrency(order.taxAmount)),

          if (order.totalDiscountAmount > 0)
            _row(context, TTexts.discount.tr, '−${TFormatter.formatCurrency(order.totalDiscountAmount)}',
                valueColor: TColors.deal),

          const Divider(height: TSizes.spaceBtwItems * 2),

          _row(context, TTexts.total.tr, TFormatter.formatCurrency(order.totalAmount), emphasize: true),
          const SizedBox(height: TSizes.sm),

          _row(context, TTexts.paymentMethod.tr, paymentMethodLabel(order.paymentMethod)),

          /// Ödeme durumu rozet olarak: metin rengi tek başına yeterince
          /// okunaklı değildi (TASARIM.md §6 hap rozet).
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TTexts.paymentStatus.tr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                ),
                TStatusBadge.payment(status: order.paymentStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false, Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: emphasize
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Text(
            value,
            textAlign: TextAlign.right,
            style: emphasize
                ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
                : theme.textTheme.titleMedium?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
