/// Dil ekranının başlık bloğu: geri düğmesi, başlık ve arama kutusu.
///
/// 🔴 TASARIM.md §1/§6: referanstaki turuncu kavisli başlık kalktı; beyaz,
/// gölgesiz, altında 1px çizgi olan sade bir başlık geldi.
///
/// ⚠️ `LanguageScreen` bu widget'ı kullanmıyor — ekran `TAppBar` ile kendi
/// başlığını çiziyor, referansta da durum aynıydı. Dosya eşliği için taşındı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/styles/spacing_styles.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/language_controller.dart';

class LanguageHeader extends StatelessWidget {
  const LanguageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = LanguageController.instance;

    return Container(
      width: double.infinity,
      padding: TSpacingStyle.topNotchStylePadding,
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        // Ayrım gölgeyle değil çizgiyle veriliyor (TASARIM.md §5).
        border: Border(
          bottom: BorderSide(
            color: dark ? TColors.darkBorder : TColors.borderSecondary,
            width: TSizes.dividerHeight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Geri düğmesi
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Get.back(),
            icon: Icon(Iconsax.arrow_left_24, color: dark ? TColors.light : TColors.dark),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Başlık
          Text(TTexts.selectLanguage.tr, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Arama kutusu
          TextField(
            onChanged: controller.filterLanguages,
            decoration: InputDecoration(
              hintText: TTexts.searchLanguage.tr,
              prefixIcon: const Icon(Iconsax.search_normal, size: TSizes.iconSm),
            ),
          ),
        ],
      ),
    );
  }
}
