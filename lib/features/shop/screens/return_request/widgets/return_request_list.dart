/// Kullanıcının iade taleplerinin listesi.
///
/// ⚠️ Sunucuda iade ucu YOK: `ApiReturnRepository` boş liste döndürüyor, bu
/// yüzden bugün ekran daima "iade başlat" boş durumunu gösteriyor. Liste
/// çizimi uç açıldığında çalışsın diye referansla birebir duruyor.
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
import '../../../controllers/return_controller.dart';
import '../../../models/return_request_model.dart';
import '../return_request_detail_screen.dart';
import 'return_status_badge.dart';
import '../../../../../common/widgets/loaders/delayed_loader.dart';

class TReturnRequestListItems extends StatefulWidget {
  const TReturnRequestListItems({super.key});

  @override
  State<TReturnRequestListItems> createState() => _TReturnRequestListItemsState();
}

class _TReturnRequestListItemsState extends State<TReturnRequestListItems> {
  late final ReturnController controller;
  late Future<List<ReturnRequest>> _future;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReturnController());
    _future = controller.getUserReturnsRequest();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReturnRequest>>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TDelayedLoader();
        }

        final requests = snapshot.data ?? const <ReturnRequest>[];
        if (requests.isEmpty) {
          // İade talebi sipariş geçmişinden başlar: müşteri hangi siparişi
          // iade edeceğini seçmeden talep açamaz.
          return TEmptyState(
            icon: Iconsax.box_remove,
            title: TTexts.startReturnTitle.tr,
            message: TTexts.startReturnText.tr,
            actionText: TTexts.selectOrderFromHistory.tr,
            onAction: () => Get.toNamed(TRoutes.order),
          );
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems),
          itemBuilder: (_, index) => _RequestCard(request: requests[index]),
        );
      },
    );
  }
}

/// Tek talep kartı: durum rozeti · tarih · tür · talep numarası.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ReturnRequest request;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        onTap: () => Get.to(() => ReturnRequestDetailScreen(returnRequest: request)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.ship, size: TSizes.iconSm, color: TColors.primary),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Text(
                    returnRequestShortId(request.id),
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TReturnStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            const Divider(height: TSizes.dividerHeight),
            const SizedBox(height: TSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                    icon: Iconsax.refresh_circle,
                    label: TTexts.requestType.tr,
                    value: returnTypeLabel(request.returnType),
                  ),
                ),
                Expanded(
                  child: _Meta(
                    icon: Iconsax.calendar,
                    label: TTexts.requestedDate.tr,
                    value: TFormatter.formatDate(request.requestDate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: TSizes.iconSm, color: TColors.darkGrey),
        const SizedBox(width: TSizes.sm),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
