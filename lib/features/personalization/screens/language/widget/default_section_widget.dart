/// "Varsayılan" bölümü — uygulamanın yedek dilini ayrı bir başlık altında
/// gösterir; arama kutusuna yazılan metinle eşleşmiyorsa gizlenir.
///
/// 🔴 Referansta varsayılan **Fransızca** yazılıydı (şablondan kalma).
/// Bu uygulamanın yedek dili `fallbackLocale: Locale('en','US')`, yani
/// **İngilizce**; çevirisi olmayan her anahtar oraya düşüyor. Yanlış dili
/// "varsayılan" diye göstermemek için düzeltildi.
///
/// ⚠️ `LanguageScreen` bu widget'ı kullanmıyor (referansta da kullanmıyordu);
/// dosya eşliği için taşındı.
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

  /// Uygulamanın yedek dili (bkz. `app.dart` → `fallbackLocale`).
  static const String _fallbackCode = 'en';

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    final defaultLanguage = controller.allLanguages.firstWhere(
      (lang) => lang['code'] == _fallbackCode,
      orElse: () => controller.allLanguages.first,
    );

    return Obx(() {
      final query = controller.searchQuery.value.toLowerCase();
      final matches = query.isEmpty || defaultLanguage['name']!.toLowerCase().contains(query);
      if (!matches) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Column(
          spacing: TSizes.spaceBtwItems,
          children: [
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
