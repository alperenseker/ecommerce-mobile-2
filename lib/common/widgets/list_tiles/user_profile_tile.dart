/// Ayarlar ekranının tepesindeki kullanıcı kartı.
///
/// Misafirde ad/e-posta yerine "giriş yapın" daveti ve giriş düğmesi çıkar —
/// girişsiz kullanıcıya boş bir profil göstermek yanıltıcı.
///
/// TASARIM.md: referanstaki koyu turuncu başlık kalktığı için metinler artık
/// beyaz değil, normal metin renginde.
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
      final isGuest = authRepo.isGuestUser;
      final picture = controller.user.value.profilePicture;
      final isNetworkImage = !isGuest && picture.isNotEmpty;

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: TCircularImage(
          padding: 0,
          image: isNetworkImage ? picture : '',
          width: 52,
          height: 52,
          isNetworkImage: isNetworkImage,
          placeholderIcon: Icons.person,
          placeholderIconColor: TColors.white,
          backgroundColor: isNetworkImage ? null : TColors.primary,
        ),
        title: Text(
          isGuest ? TTexts.guestUser.tr : controller.user.value.fullName,
          style: Theme.of(context).textTheme.headlineSmall,
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
