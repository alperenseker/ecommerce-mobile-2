/// Ayarlar ekranındaki tek satır: ikon + başlık + açıklama (+ isteğe bağlı
/// sağ eleman).
///
/// 🔴 [guestMode] true iken satır **misafir kapısına** bağlıdır: girişsiz
/// kullanıcı dokunduğunda ekran açılmaz, "önce giriş yapın" balonu çıkar.
/// Dil gibi girişten bağımsız satırlar `guestMode: false` verir.
///
/// TASARIM.md §5: ayrım gölgeyle değil çizgiyle veriliyor; bu yüzden satırlar
/// kutulanmadı, ayarlar ekranı bölüm başlıklarıyla bölünüyor.
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
      leading: Icon(icon, size: TSizes.iconMd, color: TColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      // Açıklaması olmayan satırda (ör. dil) boş bir satır yer kaplamasın.
      subtitle: subTitle.isEmpty
          ? null
          : Text(subTitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary)),
      trailing: trailing,
      onTap: guestMode ? (authRepo.isGuestUser ? authRepo.showSignInRequiredPopup : onTap) : onTap,
    );
  }
}
