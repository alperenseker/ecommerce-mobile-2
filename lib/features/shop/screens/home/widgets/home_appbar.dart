/// Ana sayfanın başlığı.
///
/// TASARIM.md §7: referanstaki koyu kavisli turuncu başlık kalktı; artık
/// **beyaz sade** başlık var. Solda kategori menüsünü (drawer) açan düğme ve
/// marka logosu, sağda destek · bildirim · profil üçlüsü (`TAppBarActions`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../home_menu.dart';
import '../../../../../common/widgets/appbar/appbar_actions.dart';
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
              onPressed: AppScreenController.instance.openMenu,
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
      // Destek · bildirim · profil üçlüsü bütün sekmelerde ortak.
      actions: const [TAppBarActions()],
      showActions: true,
      showSkipButton: false,
    );
  }
}
