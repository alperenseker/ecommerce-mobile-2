/// Bildirim detayı. Ekran açılınca bildirim **okundu** işaretlenir.
///
/// Bildirim iki yoldan gelebilir: listeden (`Get.arguments`) ya da yerel
/// bildirime dokunularak (`Get.parameters['id']`). İkincisinde kayıt uçtan
/// çekilir.
///
/// ⚠️ Dosya adındaki yazım hatası ("notifcation") referansla aynı bırakıldı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../data/services/notifications/notification_model.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notifcation_controller.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  /// Tür rozeti metni.
  ///
  /// Sunucu türü `"Order Update 363b434d-e771-…"` gibi **sipariş kimliğini
  /// yapıştırarak** gönderiyor (canlı veride 14 kaydın hepsi böyle). Rozette
  /// ham GUID göstermek bilgi vermiyor, sadece taşırıyordu; kimlik zaten
  /// "göster" düğmesiyle taşınıyor.
  static String _typeLabel(String type) =>
      type.replaceAll(RegExp(r'\s*[0-9a-fA-F]{8}-[0-9a-fA-F-]{27}\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(NotificationController());
    controller.selectedNotification.value = Get.arguments is NotificationModel
        ? Get.arguments as NotificationModel
        : NotificationModel.empty();
    controller.selectedNotificationId.value = Get.parameters['id'] ?? '';

    // Okundu işaretleme çizim sırasında değil, ilk kareden sonra yapılır.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init());

    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.notification.tr, style: Theme.of(context).textTheme.headlineSmall),
        showSkipButton: false,
        showActions: false,
        showBackArrow: false,
        leadingIcon: Iconsax.arrow_left_24,
        // Derin bağlantıdan gelindiyse geri yığını boş olabiliyor; listeye
        // dönmek her durumda çalışan tek çıkış.
        leadingOnPressed: () => Get.offNamed(TRoutes.notification),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final notification = controller.selectedNotification.value;

          return TRoundedContainer(
            width: double.infinity,
            showBorder: true,
            radius: TSizes.cardRadiusMd,
            backgroundColor: dark ? TColors.darkSurface : TColors.white,
            borderColor: TColors.borderSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- Tür rozeti
                if (_typeLabel(notification.type).isNotEmpty)
                  TRoundedContainer(
                    radius: 100,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: TSizes.sm),
                    backgroundColor: dark ? TColors.darkAccent : TColors.accent,
                    child: Text(
                      _typeLabel(notification.type),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.primary),
                    ),
                  ),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// -- Başlık
                Text(
                  TTexts.notificationTitleLabel.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
                ),
                // Sunucu başlığı çeviri ANAHTARI olarak gönderiyor.
                Text(notification.title.tr, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// -- Mesaj
                Text(
                  TTexts.notificationMessageLabel.tr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
                ),
                Text(notification.body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  notification.formattedDate,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// -- Derin bağlantı düğmesi (bildirimin gösterdiği ekran)
                if (notification.route.isNotEmpty &&
                    notification.route != TRoutes.notification &&
                    notification.route != TRoutes.notificationDetails)
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
