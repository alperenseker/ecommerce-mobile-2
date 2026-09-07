/// "Tüm diller" bölümü — arama süzgecinden geçen dilleri alt alta dizer.
///
/// ⚠️ `LanguageScreen` bu widget'ı kullanmıyor (referansta da kullanmıyordu);
/// dosya eşliği için taşındı. Bkz. [LanguageCard].
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/language_controller.dart';
import 'language_card.dart';

class AllLanguageWidget extends StatelessWidget {
  const AllLanguageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Column(
        spacing: TSizes.spaceBtwItems,
        children: [
          /// -- Bölüm başlığı
          TSectionHeading(title: TTexts.allLanguages.tr, showActionButton: false),

          /// -- Dil listesi
          Obx(
            () => Column(
              spacing: TSizes.spaceBtwItems,
              children: controller.filteredLanguages
                  .map(
                    (language) => LanguageCard(
                      languageName: language['name']!,
                      languageCode: language['code']!,
                      flagAsset: language['flag']!,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
