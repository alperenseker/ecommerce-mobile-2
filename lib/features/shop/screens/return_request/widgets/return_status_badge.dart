/// İade talebi durum/tür/sebep sözlüğü ve durum rozeti.
///
/// Metinler referansta İngilizce GÖMÜLÜYDÜ; FAZ 11 sözlüklere ekleyebilsin
/// diye anahtarlaştırıldı. Renkler TASARIM.md'nin durum paletinden gelir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../order/widgets/order_badges.dart';

/// Talep kimliğinin ekranda gösterilen kısa hâli (ilk 8 karakter).
///
/// 🔴 Referans doğrudan `id.substring(0, 8)` çağırıyordu; kimliği 8
/// karakterden kısa bir talepte (ör. sunucunun kendi numarası) ekran
/// **çöküyordu**. Burada uzunluk kontrol ediliyor.
String returnRequestShortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

/// Talep durumunun rengi.
TStatusTone returnStatusTone(ReturnStatus status) {
  switch (status) {
    case ReturnStatus.requested:
    case ReturnStatus.underReview:
      return const TStatusTone(TColors.warning, TColors.warningSoft);
    case ReturnStatus.approved:
      return const TStatusTone(TColors.info, TColors.infoSoft);
    case ReturnStatus.rejected:
      return const TStatusTone(TColors.error, TColors.errorSoft);
    case ReturnStatus.refundProcessed:
    case ReturnStatus.exchangeProcessed:
    case ReturnStatus.completed:
      return const TStatusTone(TColors.success, TColors.successSoft);
    case ReturnStatus.canceled:
      return const TStatusTone(TColors.darkerGrey, TColors.softGrey);
  }
}

/// Talep durumunun ekrandaki adı.
String returnStatusLabel(ReturnStatus status) {
  switch (status) {
    case ReturnStatus.requested:
      return TTexts.returnStatusRequested.tr;
    case ReturnStatus.underReview:
      return TTexts.returnStatusUnderReview.tr;
    case ReturnStatus.approved:
      return TTexts.returnStatusApproved.tr;
    case ReturnStatus.rejected:
      return TTexts.returnStatusRejected.tr;
    case ReturnStatus.refundProcessed:
      return TTexts.returnStatusRefundProcessed.tr;
    case ReturnStatus.exchangeProcessed:
      return TTexts.returnStatusExchangeProcessed.tr;
    case ReturnStatus.completed:
      return TTexts.returnStatusCompleted.tr;
    case ReturnStatus.canceled:
      return TTexts.returnStatusCanceled.tr;
  }
}

/// Talep türünün ekrandaki adı.
String returnTypeLabel(ReturnType type) {
  switch (type) {
    case ReturnType.returnForRefund:
      return TTexts.returnForRefund.tr;
    case ReturnType.exchange:
      return TTexts.returnExchange.tr;
    case ReturnType.returnAndExchange:
      return TTexts.returnAndExchangeType.tr;
  }
}

/// İade sebebinin ekrandaki adı.
String returnReasonLabel(ReturnReason reason) {
  switch (reason) {
    case ReturnReason.damagedProduct:
      return TTexts.reasonDamagedProduct.tr;
    case ReturnReason.wrongItem:
      return TTexts.reasonWrongItem.tr;
    case ReturnReason.sizeIssue:
      return TTexts.reasonSizeIssue.tr;
    case ReturnReason.qualityIssue:
      return TTexts.reasonQualityIssue.tr;
    case ReturnReason.notAsDescribed:
      return TTexts.reasonNotAsDescribed.tr;
    case ReturnReason.changedMind:
      return TTexts.reasonChangedMind.tr;
    case ReturnReason.other:
      return TTexts.reasonOther.tr;
  }
}

/// İade durumu hap rozeti.
class TReturnStatusBadge extends StatelessWidget {
  const TReturnStatusBadge({super.key, required this.status});

  final ReturnStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = returnStatusTone(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 3),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        returnStatusLabel(status),
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
