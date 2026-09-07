/// Sipariş ve ödeme durumu rozetleri + tek durum sözlüğü.
///
/// 🔴 Anahtar **HAM durumdur** (`OrderModel.statusKey`), enum değil:
/// `t_utils`'in `OrderStatus` enum'unda `confirmed` YOK ve backend ödeme
/// sonrası siparişi o duruma geçiriyor. Enum'a çevrilirse `pending`e düşer ve
/// ödenmiş sipariş ekranda "beklemede" görünürdü.
///
/// Renk/etiket eşlemesi web (`services/order.service.js` → `Order.STATUS`)
/// ile aynıdır; renkler TASARIM.md'nin durum paletinden alınır (dolu renk +
/// yumuşak zemin, hap rozet).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_utils/utils/constants/enums.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

/// Bir durumun rengi ve yumuşak zemini.
class TStatusTone {
  const TStatusTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Siparişin ilerleme sırası — durum çubuğu bu sırayı kullanır.
/// (web `Order.FLOW` ile birebir)
const List<String> kOrderFlow = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

/// Sipariş durumunun rengi. Bilinmeyen durum nötr gridir.
TStatusTone orderStatusTone(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const TStatusTone(TColors.warning, TColors.warningSoft);
    case 'confirmed':
    case 'processing':
      return const TStatusTone(TColors.info, TColors.infoSoft);
    case 'shipped':
      return const TStatusTone(TColors.primary, TColors.accent);
    case 'delivered':
      return const TStatusTone(TColors.success, TColors.successSoft);
    case 'canceled':
    case 'cancelled':
      return const TStatusTone(TColors.error, TColors.errorSoft);
    default:
      // `returned`, `refunded`, `on_hold` ve bilinmeyenler.
      return const TStatusTone(TColors.darkerGrey, TColors.softGrey);
  }
}

/// Sipariş durumunun ekrandaki adı. Sözlükte olmayan bir durum **ham hâliyle**
/// gösterilir; uydurma bir etiket yazılmaz.
String orderStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return TTexts.statusPending.tr;
    case 'confirmed':
      return TTexts.statusConfirmed.tr;
    case 'processing':
      return TTexts.statusProcessing.tr;
    case 'shipped':
      return TTexts.statusShipped.tr;
    case 'delivered':
      return TTexts.statusDelivered.tr;
    case 'canceled':
    case 'cancelled':
      return TTexts.statusCancelled.tr;
    case 'returned':
      return TTexts.statusReturned.tr;
    case 'refunded':
      return TTexts.statusRefunded.tr;
    default:
      return status.isEmpty ? TTexts.statusPending.tr : status;
  }
}

/// Ödeme durumunun rengi.
TStatusTone paymentStatusTone(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return const TStatusTone(TColors.success, TColors.successSoft);
    case PaymentStatus.failed:
      return const TStatusTone(TColors.error, TColors.errorSoft);
    case PaymentStatus.refunded:
    case PaymentStatus.pendingRefund:
      return const TStatusTone(TColors.darkerGrey, TColors.softGrey);
    case PaymentStatus.unpaid:
      return const TStatusTone(TColors.warning, TColors.warningSoft);
  }
}

/// Ödeme durumunun ekrandaki adı.
String paymentStatusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return TTexts.paymentPaid.tr;
    case PaymentStatus.failed:
      return TTexts.paymentFailedShort.tr;
    case PaymentStatus.refunded:
    case PaymentStatus.pendingRefund:
      return TTexts.paymentRefunded.tr;
    case PaymentStatus.unpaid:
      return TTexts.paymentUnpaid.tr;
  }
}

/// Ödeme yönteminin ekrandaki adı (web `Order.PAYMENT_METHOD`).
/// Boş/bilinmeyen değerde ham metin döner.
String paymentMethodLabel(String method) {
  switch (method.toLowerCase()) {
    case 'card':
    case 'credit_card':
      return TTexts.creditCard.tr;
    case 'bank_transfer':
      return TTexts.bankTransfer.tr;
    case 'cash_on_delivery':
      return TTexts.cashOnDelivery.tr;
    case 'pending_approval':
      return TTexts.paymentPendingApproval.tr;
    default:
      return method.isEmpty ? '—' : method;
  }
}

/// TASARIM.md §6'daki **hap rozet**: yumuşak zemin + dolu renk metin.
class TStatusBadge extends StatelessWidget {
  const TStatusBadge({super.key, required this.label, required this.tone});

  /// Sipariş durumundan rozet kurar (anahtar HAM durumdur).
  TStatusBadge.order({super.key, required String status})
      : label = orderStatusLabel(status),
        tone = orderStatusTone(status);

  /// Ödeme durumundan rozet kurar.
  TStatusBadge.payment({super.key, required PaymentStatus status})
      : label = paymentStatusLabel(status),
        tone = paymentStatusTone(status);

  final String label;
  final TStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
