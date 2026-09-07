/// Ana sayfadaki arama kutusu (dokununca arama ekranını açar).
///
/// TASARIM.md §6 form alanı dili: 48px yükseklik, 8px köşe,
/// `borderPrimary` çerçeve.
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

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => SearchScreen()),
      child: Padding(
        padding: padding,
        child: Container(
          width: double.infinity,
          height: TSizes.inputFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
          decoration: BoxDecoration(
            color: showBackground
                ? (dark ? TColors.darkSurface : TColors.lightContainer)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
            border: showBorder
                ? Border.all(color: dark ? TColors.darkBorder : TColors.borderPrimary)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: TColors.darkGrey, size: TSizes.iconSm + 2),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
