/// İade talebi detayı: ilerleme adımları, talep özeti, kanıt görselleri,
/// yönetici yanıtı, kargo takibi ve zaman çizgisi.
///
/// Referanstaki ekran kendi renk sabitlerini (`primaryBlue`, `secondaryTeal`,
/// `accentYellow`) taşıyordu; TASARIM.md gereği hepsi `TColors` üzerinden
/// indigo/durum paletine çevrildi. **Akış, bölümler ve alan adları
/// değişmedi.**
///
/// ⚠️ Sunucuda iade ucu yok; ekran bugün yalnız yerel nesneyle çalışır.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/dialogs.dart';
import '../../controllers/return_controller.dart';
import '../../models/return_request_model.dart';
import 'widgets/return_status_badge.dart';

class ReturnRequestDetailScreen extends StatelessWidget {
  const ReturnRequestDetailScreen({super.key, required this.returnRequest});

  final ReturnRequest returnRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(returnRequestShortId(returnRequest.id)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 1. İlerleme adımları
            _buildProgressStepper(context, returnRequest),
            const SizedBox(height: TSizes.spaceBtwItems),

            /// 2. Talep özeti (ürün, çözüm, sebep, not)
            _buildRequestOverview(context, returnRequest),
            const SizedBox(height: TSizes.spaceBtwItems),

            /// 3. Kanıt görselleri
            if (returnRequest.photoUrls.isNotEmpty) ...[
              _section(
                context,
                title: '${TTexts.photoEvidence.tr} (${returnRequest.photoUrls.length})',
                icon: Iconsax.camera,
                child: _buildPhotosSection(context, returnRequest),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            /// 4. Yönetici yanıtı
            if ((returnRequest.adminNote ?? '').isNotEmpty) ...[
              _buildAdminResponse(context, returnRequest),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            /// 5. Kargo takibi
            if (returnRequest.returnTrackingNumber != null ||
                returnRequest.exchangeTrackingNumber != null ||
                returnRequest.exchangeCarrier != null) ...[
              _buildTrackingInfo(context, returnRequest),
              const SizedBox(height: TSizes.spaceBtwItems),
            ],

            /// 6. Zaman çizgisi
            _section(
              context,
              title: TTexts.requestTimeline.tr,
              icon: Iconsax.scroll,
              child: _buildTimeline(context, returnRequest),
            ),
          ],
        ),
      ),

      /// 7. Sabit eylem çubuğu
      bottomNavigationBar: _buildActionBar(context, returnRequest),
    );
  }

  // ─── Ortak kap ───────────────────────────────────────────────────────────

  Widget _section(BuildContext context, {required String title, required Widget child, IconData? icon, Color? iconColor}) {
    final dark = THelperFunctions.isDarkMode(context);
    final color = iconColor ?? TColors.primary;

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon ?? Iconsax.box, size: TSizes.iconSm, color: color),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          child,
        ],
      ),
    );
  }

  // ─── 1. İlerleme adımları ────────────────────────────────────────────────

  /// Dört adım: talep → inceleme → işlem (onay/ret) → sonuçlandı.
  /// Reddedilen talepte aktif adım kırmızı çizilir.
  Widget _buildProgressStepper(BuildContext context, ReturnRequest request) {
    final currentIndex = _statusStepIndex(request.status);
    final isRejected = request.status == ReturnStatus.rejected;
    final isCanceled = request.status == ReturnStatus.canceled;
    final tone = returnStatusTone(request.status);

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: tone.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${TTexts.requestId.tr}: ${returnRequestShortId(request.id)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            returnStatusLabel(request.status),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: tone.foreground),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              final done = index < currentIndex;
              final active = index == currentIndex;
              final failed = active && (isRejected || isCanceled);

              final Color dot = failed
                  ? TColors.error
                  : done || active
                      ? TColors.primary
                      : TColors.borderPrimary;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: index == 0
                              ? const SizedBox.shrink()
                              : Container(
                                  height: 2,
                                  color: index <= currentIndex ? TColors.primary : TColors.borderPrimary,
                                ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                          child: Icon(
                            failed
                                ? Iconsax.close_circle
                                : done
                                    ? Iconsax.tick_circle
                                    : _stepIcon(index),
                            size: 12,
                            color: TColors.white,
                          ),
                        ),
                        Expanded(
                          child: index == 3
                              ? const SizedBox.shrink()
                              : Container(
                                  height: 2,
                                  color: index < currentIndex ? TColors.primary : TColors.borderPrimary,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      _stepName(index),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: done || active ? TColors.textPrimary : TColors.textSecondary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── 2. Talep özeti ──────────────────────────────────────────────────────

  Widget _buildRequestOverview(BuildContext context, ReturnRequest request) {
    return _section(
      context,
      title: TTexts.requestOverview.tr,
      icon: Iconsax.box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔴 Referans yalnız `returnItems.first`i çiziyordu ve kalem
          /// listesi boşsa **çöküyordu**; talep birden çok kalem taşıyabilir,
          /// hepsi listelenir.
          if (request.returnItems.isEmpty)
            Text(
              TTexts.orderNoItems.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            )
          else
            for (final item in request.returnItems)
              Padding(
                padding: const EdgeInsets.only(bottom: TSizes.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: TColors.lightContainer,
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (item.image ?? '').isEmpty
                          ? const Icon(Iconsax.image, size: TSizes.iconMd, color: TColors.darkGrey)
                          : CachedNetworkImage(
                              imageUrl: item.image!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: TColors.primary),
                              ),
                              errorWidget: (_, _, _) =>
                                  const Icon(Iconsax.image, size: TSizes.iconMd, color: TColors.darkGrey),
                            ),
                    ),
                    const SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: TSizes.xs / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${TTexts.quantity.tr}: ${item.quantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: TColors.textSecondary),
                              ),
                              Text(
                                TFormatter.formatCurrency(item.unitPrice),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

          const Divider(height: TSizes.spaceBtwItems * 2),

          _detailRow(context, TTexts.requestedResolution.tr, returnTypeLabel(request.returnType)),
          _detailRow(context, TTexts.returnReason.tr, returnReasonLabel(request.reason)),

          if (request.description.isNotEmpty) ...[
            const SizedBox(height: TSizes.sm),
            Text(
              TTexts.customerNotes.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            ),
            const SizedBox(height: TSizes.xs),
            TRoundedContainer(
              padding: const EdgeInsets.all(TSizes.sm),
              radius: TSizes.borderRadiusSm,
              backgroundColor: TColors.softGrey,
              child: Text(request.description, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
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
            child: Text(value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }

  // ─── 3. Görseller ────────────────────────────────────────────────────────

  Widget _buildPhotosSection(BuildContext context, ReturnRequest request) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: request.photoUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: TSizes.sm),
        itemBuilder: (_, index) {
          final url = request.photoUrls[index];
          return GestureDetector(
            onTap: () => _showImageDialog(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
              child: SizedBox(
                width: 90,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator(strokeWidth: 2, color: TColors.primary)),
                  errorWidget: (_, _, _) =>
                      const Icon(Iconsax.image, size: TSizes.iconLg, color: TColors.darkGrey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 4. Yönetici yanıtı ──────────────────────────────────────────────────

  Widget _buildAdminResponse(BuildContext context, ReturnRequest request) {
    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      borderColor: TColors.info,
      backgroundColor: TColors.infoSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.info_circle, size: TSizes.iconSm, color: TColors.info),
              const SizedBox(width: TSizes.sm),
              Text(
                TTexts.adminResponse.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: TColors.info),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          Text(request.adminNote!, style: Theme.of(context).textTheme.bodyMedium),
          if (request.approvedAt != null || request.rejectedAt != null) ...[
            const SizedBox(height: TSizes.xs),
            Text(
              '${TTexts.respondedOn.tr} '
              '${TFormatter.formatDateAndTime(request.approvedAt ?? request.rejectedAt)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 5. Kargo takibi ─────────────────────────────────────────────────────

  Widget _buildTrackingInfo(BuildContext context, ReturnRequest request) {
    return _section(
      context,
      title: TTexts.shipmentTracking.tr,
      icon: Iconsax.truck,
      iconColor: TColors.info,
      child: Column(
        children: [
          if (request.returnTrackingNumber != null)
            _detailRow(context, TTexts.returnTrackingNumber.tr, request.returnTrackingNumber!),
          if (request.exchangeTrackingNumber != null)
            _detailRow(context, TTexts.exchangeTrackingNumber.tr, request.exchangeTrackingNumber!),
          if (request.exchangeCarrier != null)
            _detailRow(context, TTexts.exchangeCarrier.tr, request.exchangeCarrier!),
        ],
      ),
    );
  }

  // ─── 6. Zaman çizgisi ────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, ReturnRequest request) {
    final items = <_TimelineEntry>[
      _TimelineEntry(
        icon: Iconsax.calendar,
        title: TTexts.requestSubmitted.tr,
        subtitle: TFormatter.formatDateAndTime(request.requestDate),
        color: TColors.primary,
      ),
      if (request.approvedAt != null)
        _TimelineEntry(
          icon: Iconsax.tick_circle,
          title: TTexts.requestApproved.tr,
          subtitle: TFormatter.formatDateAndTime(request.approvedAt),
          color: TColors.success,
        )
      else if (request.rejectedAt != null)
        _TimelineEntry(
          icon: Iconsax.close_circle,
          title: TTexts.requestRejected.tr,
          subtitle: TFormatter.formatDateAndTime(request.rejectedAt),
          color: TColors.error,
        ),
      if (request.refundProcessedAt != null)
        _TimelineEntry(
          icon: Iconsax.money_send,
          title: TTexts.refundProcessed.tr,
          subtitle: TFormatter.formatDateAndTime(request.refundProcessedAt),
          color: TColors.info,
        ),
      if (request.exchangeTrackingNumber != null)
        _TimelineEntry(
          icon: Iconsax.box,
          title: TTexts.exchangeShipped.tr,
          subtitle: '${TTexts.trackingNumber.tr}: ${request.exchangeTrackingNumber!}',
          color: TColors.primary,
        ),
      if (request.status == ReturnStatus.completed)
        _TimelineEntry(
          icon: Iconsax.tick_square,
          title: TTexts.returnProcessCompleted.tr,
          // 🔴 Referans burada `DateTime.now()` yazıyordu — ekranı her açışta
          // farklı bir "tamamlanma" saati gösteriyordu. Sunucu bir tarih
          // göndermediği sürece tarih hiç yazılmaz.
          subtitle: request.updatedAt != null ? TFormatter.formatDateAndTime(request.updatedAt) : '',
          color: TColors.success,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (i) {
        final entry = items[i];
        final isLast = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: entry.color),
                    child: Icon(entry.icon, size: 14, color: TColors.white),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: TColors.borderSecondary)),
                ],
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : TSizes.spaceBtwItems),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                      if (entry.subtitle.isNotEmpty)
                        Text(
                          entry.subtitle,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── 7. Eylem çubuğu ─────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context, ReturnRequest request) {
    String? buttonText;
    VoidCallback? onPressed;
    String hint;

    switch (request.status) {
      case ReturnStatus.requested:
      case ReturnStatus.underReview:
        // İnceleme sürerken müşteri talebi geri çekebilir.
        buttonText = TTexts.cancelRequest.tr;
        onPressed = () => _showCancelConfirmation(context);
        hint = TTexts.cancelRequestHint.tr;
        break;
      case ReturnStatus.approved:
        hint = TTexts.returnApprovedHint.tr;
        break;
      case ReturnStatus.rejected:
        buttonText = TTexts.contactSupport.tr;
        // FAZ 10 — destek sohbeti gelince buradan açılacak.
        onPressed = null;
        hint = TTexts.returnRejectedHint.tr;
        break;
      case ReturnStatus.refundProcessed:
      case ReturnStatus.exchangeProcessed:
      case ReturnStatus.completed:
        hint = TTexts.returnCompletedHint.tr;
        break;
      case ReturnStatus.canceled:
        hint = TTexts.returnCanceledHint.tr;
        break;
    }

    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        border: const Border(top: BorderSide(color: TColors.borderSecondary, width: TSizes.dividerHeight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eylemi olmayan durumda düğme HİÇ çizilmez; referanstaki boş
          // etiketli ya da devre dışı düğme kullanıcıya bir şey anlatmıyordu.
          if (buttonText != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
            ),
          if (buttonText != null) const SizedBox(height: TSizes.sm),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Yardımcılar ─────────────────────────────────────────────────────────

  int _statusStepIndex(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.requested:
        return 0;
      case ReturnStatus.underReview:
        return 1;
      case ReturnStatus.approved:
      case ReturnStatus.rejected:
      case ReturnStatus.canceled:
        return 2;
      case ReturnStatus.refundProcessed:
      case ReturnStatus.exchangeProcessed:
        return 3;
      case ReturnStatus.completed:
        return 4;
    }
  }

  String _stepName(int index) {
    switch (index) {
      case 0:
        return TTexts.returnStepRequested.tr;
      case 1:
        return TTexts.returnStepReview.tr;
      case 2:
        return TTexts.returnStepAction.tr;
      default:
        return TTexts.returnStepFinalized.tr;
    }
  }

  IconData _stepIcon(int index) {
    switch (index) {
      case 0:
        return Iconsax.document_text;
      case 1:
        return Iconsax.clock;
      case 2:
        return Iconsax.box_search;
      default:
        return Iconsax.tick_square;
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: TColors.white)),
                errorWidget: (_, _, _) => Center(
                  child: Text(TTexts.imageLoadFailed.tr, style: const TextStyle(color: TColors.white)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: TColors.white, size: TSizes.iconLg),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    TDialogs.confirm(
      title: TTexts.cancelRequestConfirmTitle.tr,
      message: TTexts.cancelRequestConfirmMessage.trParams({'id': returnRequestShortId(returnRequest.id)}),
      icon: Iconsax.close_circle,
      isDestructive: true,
      confirmText: TTexts.yesCancelIt.tr,
      cancelText: TTexts.keepRequest.tr,
      onConfirm: () async {
        final controller = Get.isRegistered<ReturnController>()
            ? ReturnController.instance
            : Get.put(ReturnController());
        await controller.cancelReturnRequest(returnRequest.id);
      },
    );
  }
}

/// Zaman çizgisi satırının verisi.
class _TimelineEntry {
  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
