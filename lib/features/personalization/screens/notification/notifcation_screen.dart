/// Bildirim listesi.
///
/// 🔴 Liste **alıcıya göre süzülmüş** gelir (`NotificationController.onlyMine`);
/// `GET /notifications` süzgeç kabul etmiyor ve bütün kullanıcıların
/// kayıtlarını döndürüyor. Süzgeç orada, ekranda değil — tek yerde dursun.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
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
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(TTexts.notifications.tr, style: Theme.of(context).textTheme.headlineSmall),
        showSkipButton: false,
        showActions: false,
        showBackArrow: true,
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return TEmptyState(
            icon: Iconsax.notification,
            title: TTexts.noNotifications.tr,
            message: TTexts.noNotificationsHint.tr,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              TSizes.defaultSpace,
              TSizes.md,
              TSizes.defaultSpace,
              MediaQuery.paddingOf(context).bottom + TSizes.spaceBtwSections,
            ),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: TSizes.sm),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              final seen = controller.isSeen(notification, currentUserId);

              /// 🔴 Kart düzeni değişti: okunmamışı zemini boyayarak DEĞİL,
              /// **solundaki indigo şerit** ve kalın başlıkla ayırıyoruz.
              /// Renkli zemin listedeki her okunmamış satırı ayrı bir uyarı
              /// gibi gösteriyor, göz nereye bakacağını bilemiyordu.
              return Material(
                color: dark ? TColors.darkSurface : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.toNamed(TRoutes.notificationDetails, arguments: notification),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: dark ? TColors.darkBorder : TColors.borderSecondary,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Okunmamışın sol şeridi.
                          Container(width: 4, color: seen ? Colors.transparent : TColors.primary),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(TSizes.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: seen
                                          ? (dark ? TColors.darkBorder : TColors.softGrey)
                                          : (dark ? TColors.darkAccent : TColors.accent),
                                      borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                                    ),
                                    child: Icon(
                                      Iconsax.notification_bing,
                                      size: 18,
                                      color: seen ? TColors.darkGrey : TColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: TSizes.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          // Başlık sunucuda ÇEVİRİ ANAHTARI olarak
                                          // tutuluyor (`orderShippedOnItsWay` gibi);
                                          // ekranda çevriliyor.
                                          notification.title.tr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyLarge!.apply(
                                            fontWeightDelta: seen ? 0 : 1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          notification.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: TSizes.sm),
                                        Row(
                                          children: [
                                            const Icon(
                                              Iconsax.clock,
                                              size: 12,
                                              color: TColors.darkGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              notification.formattedDate,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            const Spacer(),
                                            if (seen)
                                              const Icon(
                                                Icons.check,
                                                color: TColors.success,
                                                size: TSizes.iconSm,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
