/// Ana sekmelerin sağ üstündeki profil avatarı; dokununca hesap ekranını açar.
///
/// Profil fotoğrafı varsa onu, yoksa nötr daire içinde koyu gri kişi ikonunu
/// gösterir.
///
/// 🔴 Daire eskiden **dolu indigo**ydu: beyaz sade başlıkta (TASARIM.md §7)
/// tek renkli leke gibi duruyor, yanındaki destek/bildirim ikonlarıyla aynı
/// dili konuşmuyordu. Artık zemin nötr (`softGrey`), çerçeve 1px
/// `borderSecondary`, ikon komşularıyla aynı `iconPrimaryLight` — marka rengi
/// başlıkta değil, gerçekten eylem çağıran yerlerde (arama düğmesi, birincil
/// düğmeler) kullanılıyor. Fotoğraf varsa aynı çerçeve halka olarak kalır,
/// böylece iki durumda da avatarın ölçüsü ve ağırlığı değişmez.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../images/t_circular_image.dart';

class TProfileActionIcon extends StatelessWidget {
  const TProfileActionIcon({super.key});

  /// Çerçeve dahil dış ölçü; başlıktaki ikon düğmeleriyle aynı ağırlıkta.
  static const double _size = 38.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final image = UserController.instance.user.value.profilePicture;
      final hasPhoto = image.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.only(right: TSizes.xs),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.toNamed(TRoutes.settings),
            customBorder: const CircleBorder(),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
              ),
              child: TCircularImage(
                image: image,
                isNetworkImage: hasPhoto,
                placeholderIcon: Iconsax.user,
                placeholderIconColor: dark ? TColors.iconPrimaryDark : TColors.iconPrimaryLight,
                width: _size - 2,
                height: _size - 2,
                padding: 0,
                backgroundColor: hasPhoto
                    ? (dark ? TColors.darkSurface : TColors.white)
                    : (dark ? TColors.darkSurface : TColors.softGrey),
              ),
            ),
          ),
        ),
      );
    });
  }
}
