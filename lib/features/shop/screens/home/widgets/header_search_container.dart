/// Ana sayfadaki arama kutusu (dokununca arama ekranını açar).
///
/// TASARIM.md §6 form alanı dili korunuyor (çerçeveli kap, `borderPrimary`),
/// yalnız ana sayfadaki bu kutu **hap biçimli** çiziliyor: tam yuvarlatılmış
/// köşe, solda marka renginde ikon, sağda marka renginde dolu arama düğmesi.
/// Böylece kutu bir "form alanı" gibi değil, dokunulacak bir **eylem** gibi
/// duruyor — hemen üstündeki slider'dan sonra sayfanın ilk işi bu.
///
/// 🔴 Gölge yok: TASARIM.md §5 sayfa akışında gölgeyi yasaklıyor, ayrım
/// çizgiyle veriliyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../search/search.dart';

class TSearchContainer extends StatelessWidget {
  const TSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
  });

  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showBackground, showBorder;
  final EdgeInsetsGeometry padding;

  /// Hap biçim: yükseklik form alanından biraz yüksek, köşe tam yuvarlak.
  static const double _height = 52.0;

  /// Sağdaki dolu düğmenin ölçüsü; kabın içinde 6px boşlukla oturur.
  static const double _actionSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final tap = onTap ?? () => Get.to(() => SearchScreen());

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_height / 2),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(_height / 2),
          child: Ink(
            height: _height,
            padding: const EdgeInsets.fromLTRB(TSizes.md, 6, 6, 6),
            decoration: BoxDecoration(
              color: showBackground
                  ? (dark ? TColors.darkSurface : TColors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(_height / 2),
              border: showBorder
                  ? Border.all(color: dark ? TColors.darkBorder : TColors.borderPrimary)
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: TColors.primary, size: TSizes.iconSm + 4),
                const SizedBox(width: TSizes.sm + 2),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: dark ? TColors.darkGrey : TColors.textSecondary),
                  ),
                ),
                // Kabın kendisiyle aynı eylem; ayrı bir dokunma hedefi değil,
                // yalnız "burası aranır" işareti.
                Container(
                  width: _actionSize,
                  height: _actionSize,
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.circular(_actionSize / 2),
                  ),
                  child: const Icon(
                    Iconsax.search_normal,
                    color: TColors.textWhite,
                    size: TSizes.iconSm + 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
