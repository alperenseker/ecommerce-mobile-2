/// Ana sekmelerin sağ üstündeki profil avatarı; dokununca hesap ekranını açar.
///
/// Profil fotoğrafı varsa onu, yoksa indigo daire içinde beyaz kişi ikonunu
/// gösterir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../images/t_circular_image.dart';

class TProfileActionIcon extends StatelessWidget {
  const TProfileActionIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = UserController.instance.user.value.profilePicture;
      return GestureDetector(
        // FAZ 09 — hesap ekranı gelene kadar bu rota kayıtlı değil.
        onTap: () => Get.toNamed(TRoutes.settings),
        child: Padding(
          padding: const EdgeInsets.only(right: TSizes.xs),
          child: TCircularImage(
            image: image,
            isNetworkImage: image.isNotEmpty,
            placeholderIcon: Icons.person,
            placeholderIconColor: TColors.white,
            width: 38,
            height: 38,
            padding: 0,
            backgroundColor: image.isNotEmpty ? TColors.white : TColors.primary,
          ),
        ),
      );
    });
  }
}
