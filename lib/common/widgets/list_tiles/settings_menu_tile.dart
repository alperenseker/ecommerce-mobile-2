/// Ayarlar ekranındaki tek satır: ikon + başlık + açıklama (+ isteğe bağlı
/// sağ öge).
///
/// TASARIM.md §6: ikon indigo, ayrım gölge değil satır aralığı. Misafir
/// kullanıcı [guestMode] açık satırlara dokununca "önce giriş yapın"
/// balonuna düşer — dil satırı gibi girişe ihtiyaç duymayan satırlar
/// `guestMode: false` verir.
library;

import 'package:flutter/material.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

class TSettingsMenuTile extends StatelessWidget {
  TSettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.onTap,
    this.guestMode = true,
  });

  final IconData icon;
  final String title, subTitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool guestMode;
  final authRepo = AuthenticationRepository.instance;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TColors.accent,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
        child: Icon(icon, size: TSizes.iconMd, color: TColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subTitle.isEmpty
          ? null
          : Text(
              subTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: trailing,
      onTap: guestMode ? (authRepo.isGuestUser ? authRepo.showSignInRequiredPopup : onTap) : onTap,
    );
  }
}
