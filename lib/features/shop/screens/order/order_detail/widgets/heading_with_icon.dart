/// Sipariş detayındaki bölüm başlığı: daire ikon + başlık.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/helpers/helper_functions.dart';

class THeadingWithIcon extends StatelessWidget {
  const THeadingWithIcon({
    super.key,
    this.icon = Iconsax.add,
    required this.title,
    this.color = TColors.primary,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        // TASARIM.md §6: daire ikon yumuşak zeminde; ölçü referanstakinden
        // küçük (48 → 36), sayfa akışı ferah kalsın.
        TCircularIcon(
          icon: icon,
          width: 36,
          height: 36,
          size: TSizes.iconSm,
          backgroundColor: color.withValues(alpha: 0.1),
          color: color,
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge!.apply(color: dark ? TColors.light : TColors.dark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
