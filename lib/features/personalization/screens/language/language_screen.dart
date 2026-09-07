/// Dil seçimi ekranı: arama, bayraklar, seçili dil işareti.
///
/// Seçim anında uygulanır (`Get.updateLocale`) ve `GetStorage`'a `'language'`
/// anahtarıyla yazılır; uygulamayı yeniden başlatmak gerekmez.
///
/// 🔴 Diller **istek üzerine** yükleniyor: `LanguageController.changeLanguage`
/// yalnız seçilen dilin sözlüğünü belleğe alıyor (`Languages.ensureLoaded`).
///
/// TASARIM.md §1/§6: referanstaki turuncu degrade başlık kalktı; sade beyaz
/// başlık + arama alanı geldi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/language_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// Her dilin kendi dilindeki adı; altyazı olarak görünür.
  static const Map<String, String> nativeNames = {
    'kk': 'Қазақша',
    'ru': 'Русский',
    'tr': 'Türkçe',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'pt': 'Português',
    'pt_BR': 'Português (Brasil)',
    'vi': 'Tiếng Việt',
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageController());

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(TTexts.selectLanguage.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Column(
        children: [
          /// -- Açıklama + arama
          Padding(
            padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TTexts.chooseYourLanguage.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                TextField(
                  onChanged: controller.filterLanguages,
                  decoration: InputDecoration(
                    hintText: TTexts.searchLanguage.tr,
                    prefixIcon: const Icon(Iconsax.search_normal, size: TSizes.iconSm),
                  ),
                ),
              ],
            ),
          ),

          /// -- Dil listesi
          Expanded(
            child: Obx(() {
              final languages = controller.filteredLanguages;
              if (languages.isEmpty) {
                return Center(
                  child: Text(TTexts.noDataFound.tr, style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  TSizes.defaultSpace,
                  0,
                  TSizes.defaultSpace,
                  TSizes.defaultSpace,
                ),
                itemCount: languages.length,
                separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems),
                itemBuilder: (_, index) {
                  final language = languages[index];
                  return TLanguageTile(
                    languageName: language['name']!,
                    nativeName: nativeNames[language['code']] ?? '',
                    languageCode: language['code']!,
                    flagAsset: language['flag']!,
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: ElevatedButton.icon(
          onPressed: () => Get.back(),
          label: Text(TTexts.saveSettings.tr),
          icon: const Icon(Icons.check_rounded, color: TColors.white),
        ),
      ),
    );
  }
}

/// Listedeki tek dil satırı: bayrak + ad + kendi dilindeki adı + seçim işareti.
class TLanguageTile extends StatelessWidget {
  const TLanguageTile({
    super.key,
    required this.languageName,
    required this.nativeName,
    required this.languageCode,
    required this.flagAsset,
  });

  final String languageName;
  final String nativeName;
  final String languageCode;
  final String flagAsset;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      // 'pt_BR' gibi bölgeli kodlarda `languageCode` yalnız 'pt' döner;
      // karşılaştırma bu yüzden tam kod üzerinden yapılıyor.
      final selected = controller.selectedLocale.value;
      final selectedCode =
          selected.countryCode == null || selected.countryCode!.isEmpty || selected.countryCode == 'US'
              ? selected.languageCode
              : '${selected.languageCode}_${selected.countryCode}';
      final isSelected = selectedCode == languageCode;

      return GestureDetector(
        onTap: () => controller.changeLanguage(languageCode),
        child: TRoundedContainer(
          showBorder: true,
          radius: TSizes.cardRadiusMd,
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: isSelected
              ? (dark ? TColors.darkAccent : TColors.accent)
              : (dark ? TColors.darkSurface : TColors.white),
          borderColor: isSelected ? TColors.primary : TColors.borderSecondary,
          child: Row(
            children: [
              /// -- Bayrak
              TCircularImage(image: flagAsset, padding: 0, height: 40, width: 40),
              const SizedBox(width: TSizes.spaceBtwItems),

              /// -- Adlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languageName, style: Theme.of(context).textTheme.titleSmall),
                    if (nativeName.isNotEmpty)
                      Text(
                        nativeName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                      ),
                  ],
                ),
              ),

              /// -- Seçim işareti
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? TColors.primary : Colors.transparent,
                  border: Border.all(color: isSelected ? TColors.primary : TColors.borderPrimary, width: 2),
                ),
                child: isSelected ? const Icon(Icons.check, color: TColors.white, size: 14) : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}
