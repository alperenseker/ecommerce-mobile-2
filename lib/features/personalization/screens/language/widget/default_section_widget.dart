/// "Varsayılan dil" bölümü.
///
/// ⚠️ Ekran tarafından kullanılmıyor (bkz. `language_card.dart` başındaki not).
///
/// 🔴 Varsayılan dil **İngilizce**, referanstaki gibi Fransızca değil:
/// uygulamanın yedek dili `fallbackLocale: Locale('en','US')` ve sözlüğü
/// olmayan diller de oraya düşüyor (`LanguageController.localeFor`).
/// Referanstaki `'fr'` şablondan kalmıştı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/language_controller.dart';
import 'language_card.dart';

class DefaultSectionWidget extends StatelessWidget {
  const DefaultSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    final defaultLanguage = controller.allLanguages.firstWhere(
      (lang) => lang['code'] == 'en',
      orElse: () => controller.allLanguages.first,
    );

    return Obx(() {
      // Varsayılan dil yalnız aramayla eşleşiyorsa (ya da arama boşsa) çizilir.
      final query = controller.searchQuery.value.toLowerCase();
      if (query.isNotEmpty && !defaultLanguage['name']!.toLowerCase().contains(query)) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Column(
          spacing: TSizes.spaceBtwItems,
          children: [
            /// -- Bölüm başlığı
            TSectionHeading(title: TTexts.defaultLabel.tr, showActionButton: false),
            LanguageCard(
              languageName: defaultLanguage['name']!,
              languageCode: defaultLanguage['code']!,
              flagAsset: defaultLanguage['flag'] ?? TImages.usa,
            ),
          ],
        ),
      );
    });
  }
}
