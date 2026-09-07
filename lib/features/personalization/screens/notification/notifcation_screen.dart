/// Bildirim listesi.
///
/// Okunmamış bildirim indigo yumuşak zeminde ve dolu nokta ile, okunmuş olan
/// beyaz zeminde ve onay işaretiyle çizilir.
///
/// ⚠️ Dosya adındaki yazım hatası ("notifcation") referansla aynı bırakıldı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notifcation_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(NotificationController());
    final currentUserId = AuthenticationRepository.instance.getUserID;

    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.notifications.tr, style: Theme.of(context).textTheme.headlineSmall),
        showSkipButton: false,
        showActions: false,
        showBackArrow: true,
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return TEmptyState(icon: Iconsax.notification, title: TTexts.noNotifications.tr);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final isSeen = notification.seenBy[currentUserId] == true;

            return TRoundedContainer(
              showBorder: true,
              radius: TSizes.cardRadiusMd,
              padding: const EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
              // Okunmamış olan indigo yumuşak zeminde durur (TASARIM.md §2).
              backgroundColor: isSeen
                  ? (dark ? TColors.darkSurface : TColors.white)
                  : (dark ? TColors.darkAccent : TColors.accent),
              borderColor: isSeen ? TColors.borderSecondary : TColors.primary,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Iconsax.notification_bing,
                  color: isSeen ? TColors.darkGrey : TColors.primary,
                ),
                title: Text(
                  // Sunucu başlığı çeviri ANAHTARI olarak gönderiyor
                  // (ör. "orderCanceledSorry"); sözlük FAZ 11'de gelecek.
                  notification.title.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      notification.formattedDate,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
                    ),
                  ],
                ),
                trailing: isSeen
                    ? const Icon(Icons.check, color: TColors.success, size: TSizes.iconSm)
                    : const Icon(Icons.circle, color: TColors.primary, size: 10),
                onTap: () => Get.toNamed(TRoutes.notificationDetails, arguments: notification),
              ),
            );
          },
        );
      }),
    );
  }
}
