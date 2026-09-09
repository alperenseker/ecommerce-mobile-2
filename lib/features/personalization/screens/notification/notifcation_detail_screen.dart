/// Bildirim detayı: tür rozeti, başlık, mesaj ve (varsa) hedefe gitme düğmesi.
///
/// ⚠️ Sunucu `Type` alanını `"Order Update 363b434d-e771-…"` diye gönderiyor;
/// ham GUID rozeti taşırıyor ve kullanıcıya bir şey anlatmıyor (kimlik zaten
/// "göster" düğmesiyle taşınıyor), bu yüzden rozette kırpılıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../data/services/notifications/notification_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notifcation_controller.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

/// Tür etiketinden GUID'i kırpar. **Saf** fonksiyon — testle sabitlenir.
String notificationTypeLabel(String rawType) {
  final guid = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
  return rawType.replaceAll(guid, '').trim();
}

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(NotificationController());
    controller.selectedNotification.value = Get.arguments is NotificationModel
        ? Get.arguments as NotificationModel
        : NotificationModel.empty();
    controller.selectedNotificationId.value = Get.parameters['id'] ?? '';

    // Denetleyicinin açılış işi çizim dışında yapılır; `build` içinde ağ
    // çağrısı başlatmak ilk kareyi geciktiriyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init());

    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.notification.tr, style: Theme.of(context).textTheme.headlineSmall),
        showSkipButton: false,
        showActions: false,
        showBackArrow: false,
        leadingIcon: Iconsax.arrow_left_24,
        leadingOnPressed: () => Get.offNamed(TRoutes.notification),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const TDelayedLoader();
          }

          final notification = controller.selectedNotification.value;
          final typeLabel = notificationTypeLabel(notification.type);

          return TRoundedContainer(
            width: double.infinity,
            showBorder: true,
            radius: TSizes.cardRadiusLg,
            backgroundColor: dark ? TColors.darkSurface : TColors.white,
            borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
            child: Column(
              // Kutu içeriği kadar yüksek olsun; `Column` varsayılanı tüm
              // ekranı kaplayıp altta boş beyaz alan bırakıyordu.
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (typeLabel.isNotEmpty)
                  TRoundedContainer(
                    radius: TSizes.borderRadiusSm,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
                    backgroundColor: TColors.accent,
                    child: Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.primary),
                    ),
                  ),
                const SizedBox(height: TSizes.spaceBtwItems),

                Text(
                  TTexts.notificationTitleLabel.tr,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                ),
                const SizedBox(height: TSizes.xs),
                Text(notification.title.tr, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: TSizes.spaceBtwItems),

                Text(
                  TTexts.notificationMessageLabel.tr,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                ),
                const SizedBox(height: TSizes.xs),
                Text(notification.body, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: TSizes.sm),
                Text(
                  notification.formattedDate,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// -- Hedefe git
                //
                // Rota kendine dönüyorsa ya da bu sürümde henüz açılmadıysa
                // düğme çizilmez; GetX'in "bilinmeyen rota" ekranı çıkmasın.
                if (notification.route.isNotEmpty &&
                    notification.route != TRoutes.notification &&
                    notification.route != TRoutes.notificationDetails &&
                    AppRoutes.isRegistered(notification.route))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed(
                        notification.route,
                        parameters: {'id': notification.routeId},
                      ),
                      label: Text(TTexts.notificationRedirect.tr),
                      icon: const Icon(Iconsax.arrow_right),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
