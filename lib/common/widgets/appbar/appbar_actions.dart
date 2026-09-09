/// Başlığın sağındaki ortak eylem: bildirimler.
///
/// 🔴 Şerit ikiye, oradan tek düğmeye indi. Önce destek · bildirim · profil
/// taşıyordu; destek ve profil alt gezinmeye indi, sepet bir süre burada
/// durdu ve o da **alt gezinmeye** geçti (alışverişin her adımında bakılan
/// yer, başparmağın altında olmalı). Başlıkta yalnız bildirim kaldı: sayfa
/// başlıklarının sağı boş kaldıkça başlık kendi işini — nerede olduğunu
/// söylemeyi — daha iyi yapıyor.
///
/// Tek widget olarak kullanılır: `actions: const [TAppBarActions()]`.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';

class TAppBarActions extends StatelessWidget {
  const TAppBarActions({super.key, this.showNotifications = true});

  /// Bildirim düğmesi. Bildirim ekranının kendisinde kapatılır.
  final bool showNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNotifications)
          IconButton(
            icon: const Icon(Iconsax.notification, color: TColors.iconPrimaryLight),
            tooltip: TTexts.notifications.tr,
            onPressed: () => Get.toNamed(TRoutes.notification),
          ),
        const SizedBox(width: TSizes.xs),
      ],
    );
  }
}
