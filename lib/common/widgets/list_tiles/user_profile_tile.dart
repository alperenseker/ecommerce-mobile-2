/// Ayarlar ekranının tepesindeki kullanıcı kartı.
///
/// ⚠️ Renkler referanstan farklı: orada başlık koyu turuncu olduğu için metin
/// **beyaz** yazılıydı; TASARIM.md §6 ile başlık beyaza döndü, bu yüzden
/// metin tema renklerini kullanıyor.
///
/// Misafirde ad yerine "misafir kullanıcı" ve sağda giriş ikonu çizilir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_strings.dart';
import '../images/t_circular_image.dart';

class TUserProfileTile extends StatelessWidget {
  TUserProfileTile({super.key, required this.onPressed});

  final VoidCallback onPressed;
  final controller = UserController.instance;
  final authRepo = AuthenticationRepository.instance;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isNetworkImage = controller.user.value.profilePicture.isNotEmpty;
      final image = isNetworkImage ? controller.user.value.profilePicture : '';
      final isGuest = authRepo.isGuestUser;

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: TCircularImage(
          padding: 0,
          image: image,
          width: 52,
          height: 52,
          isNetworkImage: isNetworkImage,
          placeholderIcon: Icons.person,
          placeholderIconColor: TColors.white,
          backgroundColor: isNetworkImage ? null : TColors.primary,
        ),
        title: Text(
          isGuest ? TTexts.guestUser.tr : controller.user.value.fullName,
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isGuest ? TTexts.guestSignInPrompt.tr : controller.user.value.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: isGuest ? () => Get.toNamed(TRoutes.welcome) : onPressed,
          icon: Icon(isGuest ? Iconsax.login : Iconsax.edit, color: TColors.primary),
        ),
      );
    });
  }
}
