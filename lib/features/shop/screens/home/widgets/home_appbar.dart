/// Ana sayfanın başlığı.
///
/// TASARIM.md §7: referanstaki koyu kavisli turuncu başlık kalktı; artık
/// **beyaz sade** başlık var. Solda kategori menüsünü (drawer) açan düğme ve
/// marka logosu, sağda bildirim ile profil avatarı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/appbar/profile_action_icon.dart';
import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../personalization/controllers/settings_controller.dart';
import '../../../../personalization/controllers/user_controller.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu iki controller'a başka ekranlar da bağlı; ana sayfa açılırken
    // kurulmaları yeterli (referanstaki davranış).
    Get.put(SettingsController());
    Get.put(UserController());

    return TAppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // TAppBar'ın yatay dolgusunu geri alır; menü düğmesi ekran kenarına
          // yaslansın.
          Transform.translate(
            offset: const Offset(-TSizes.defaultSpace, 0),
            child: IconButton(
              icon: const Icon(Icons.menu, color: TColors.iconPrimaryLight),
              tooltip: TTexts.categories.tr,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Flexible(
            child: Image.asset(
              TImages.foresLogo,
              height: 26,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
      actions: [
        // FAZ 10 — destek sohbetinin ANA MENÜ girişi. Web'de her sayfanın sağ
        // altında duran destek düğmesinin karşılığı; mobilde yüzen düğme
        // ürün ızgarasını ve alt gezinmeyi örttüğü için başlığa alındı.
        // Girişsiz kullanıcı da açabilir: ekran içinde giriş bağlantısı var.
        IconButton(
          icon: const Icon(Iconsax.headphone, color: TColors.iconPrimaryLight),
          tooltip: TTexts.liveSupport.tr,
          onPressed: () => Get.toNamed(TRoutes.chat),
        ),
        IconButton(
          icon: const Icon(Iconsax.notification, color: TColors.iconPrimaryLight),
          onPressed: () => Get.toNamed(TRoutes.notification),
        ),
        const TProfileActionIcon(),
      ],
      showActions: true,
      showSkipButton: false,
    );
  }
}
