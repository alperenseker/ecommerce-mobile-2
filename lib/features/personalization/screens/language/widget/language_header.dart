/// Dil ekranının başlığı (geri düğmesi + başlık + arama).
///
/// ⚠️ Ekran tarafından kullanılmıyor (bkz. `language_card.dart` başındaki not).
/// TASARIM.md §1 gereği referanstaki turuncu zemin kalktı; başlık beyaz,
/// ayrım 1px çizgi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: dark ? TColors.iconPrimaryDark : TColors.iconPrimaryLight,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Başlık
          Text(TTexts.languages.tr, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// -- Arama kutusu
          TextField(
            controller: TextEditingController(text: controller.searchQuery.value),
            onChanged: controller.filterLanguages,
            decoration: InputDecoration(hintText: TTexts.searchLanguage.tr),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],
      ),
    );
  }
}
