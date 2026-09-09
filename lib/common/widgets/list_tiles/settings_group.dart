/// Hesap yüzeyinin ortak yapı taşları: **gruplanmış satır kartı**.
///
/// 🔴 Eskiden hesap ve profil ekranları tek tek duran `ListTile`'lardan
/// oluşuyordu: her satır kendi başına yüzüyor, aralarındaki ilişkiyi yalnız
/// boşluk anlatıyordu ve ekran uzun bir liste lapasına dönüşüyordu. Artık
/// aynı işe bakan satırlar **tek bir kartın içinde** toplanıyor, aralarını
/// içeriden başlayan ince çizgiler ayırıyor; grubun ne olduğunu üstündeki
/// küçük etiket söylüyor. Bölümler böylece bir bakışta sayılabiliyor.
///
/// TASARIM.md §5: kartta gölge yok, ayrım 1px `borderSecondary` çizgi.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

/// Başlıklı satır grubu. Boş çocuk listesi verilirse hiç çizilmez.
class TSettingsGroup extends StatelessWidget {
  const TSettingsGroup({super.key, this.title, required this.children});

  /// Grubun üstündeki küçük etiket. Boşsa yalnız kart çizilir.
  final String? title;

  /// Satırlar. `SizedBox.shrink()` dönen (koşullu) satırlar arada çizgi
  /// bırakmasın diye ayıklanır.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final dark = THelperFunctions.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwSections / 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: TSizes.xs, bottom: TSizes.sm),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.labelMedium!
                    .apply(color: TColors.darkGrey, fontWeightDelta: 1)
                    .copyWith(letterSpacing: 0.4),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: dark ? TColors.darkSurface : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      // Çizgi ikonun altından değil YAZININ hizasından
                      // başlıyor: satırlar tek blok gibi okunuyor.
                      indent: TSizes.md + 36 + TSizes.md,
                      color: dark ? TColors.darkBorder : TColors.borderSecondary,
                    ),
                  visible[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grup içindeki tek satır: yumuşak kare ikon · başlık (+ açıklama) · sağ öge.
///
/// Misafir kullanıcı [guestMode] açık satırlara dokununca "önce giriş yapın"
/// balonuna düşer — dil gibi girişe ihtiyaç duymayan satırlar
/// `guestMode: false` verir.
class TSettingsRow extends StatelessWidget {
  const TSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.guestMode = true,
    this.danger = false,
    this.locked = false,
  });

  final IconData icon;
  final String title;

  /// Başlığın altındaki açıklama.
  final String? subtitle;

  /// Sağda, okun solunda duran değer (profil satırlarında kullanılıyor).
  final String? value;

  /// [value] yerine geçen özel öge (sayaç hapı gibi).
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool guestMode;

  /// Kırmızı satır (çıkış, hesabı sil).
  final bool danger;

  /// Salt okunur satır: ok yerine kilit çizilir, dokunma etkisi verilmez.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final authRepo = AuthenticationRepository.instance;
    final accent = danger ? TColors.error : TColors.primary;

    final effectiveOnTap = locked
        ? null
        : guestMode && authRepo.isGuestUser
        ? authRepo.showSignInRequiredPopup
        : onTap;

    return InkWell(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger
                    ? (dark ? TColors.darkSurface : TColors.errorSoft)
                    : (dark ? TColors.darkAccent : TColors.accent),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge!.apply(
                      color: danger ? TColors.error : null,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: TSizes.sm),
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: TSizes.sm), trailing!],
            if (!danger) ...[
              const SizedBox(width: TSizes.xs),
              Icon(
                locked ? Iconsax.lock : Iconsax.arrow_right_3,
                size: locked ? 14 : 16,
                color: TColors.darkGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satırın sağındaki sayaç hapı; sıfırsa hiç çizilmez.
class TCountPill extends StatelessWidget {
  const TCountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? TColors.darkAccent : TColors.accent,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.primary),
      ),
    );
  }
}
