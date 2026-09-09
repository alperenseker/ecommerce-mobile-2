/// Dil ekranı: arama, bayraklar ve seçimin kaydı.
///
/// Seçim anında uygulanır (`Get.updateLocale`) — uygulama yeniden
/// başlatılmadan bütün `.tr` metinleri yeniden çizilir — ve `GetStorage`'a
/// **`'language'`** anahtarıyla yazılır.
///
/// ⚠️ TASARIM.md §1: referanstaki turuncu gradyan başlık kaldırıldı; beyaz,
/// gölgesiz başlık ve altında 1px çizgi (§6) kullanılıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/language_controller.dart';

/// Her dilin kendi dilindeki adı; listede alt satır olarak görünür.
const Map<String, String> kNativeLanguageNames = {
  'kk': 'Қазақша',
  'tr': 'Türkçe',
  'fr': 'Français',
  'en': 'English',
  'pt_BR': 'Português (Brasil)',
  'de': 'Deutsch',
  'pt': 'Português',
  'ru': 'Русский',
  'es': 'Español',
  'vi': 'Tiếng Việt',
};

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
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
            padding: const EdgeInsets.fromLTRB(
              TSizes.defaultSpace,
              TSizes.md,
              TSizes.defaultSpace,
              TSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TTexts.chooseYourLanguage.tr, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: TSizes.sm + 2),
                // Mağazadaki arama kutusuyla aynı hap dili.
                _SearchField(onChanged: controller.filterLanguages),
              ],
            ),
          ),

          /// -- Dil listesi
          ///
          /// 🔴 Diller artık tek tek yüzen kartlar DEĞİL, **tek bir kartın
          /// içinde** alt alta satırlar. On dil on ayrı kart olunca liste
          /// parçalanıyor, seçili olanı bulmak zorlaşıyordu.
          Expanded(
            child: Obx(() {
              final languages = controller.filteredLanguages;
              if (languages.isEmpty) {
                return Center(
                  child: Text(TTexts.noDataFound.tr, style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  TSizes.defaultSpace,
                  0,
                  TSizes.defaultSpace,
                  TSizes.defaultSpace,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: dark ? TColors.darkSurface : TColors.white,
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: dark ? TColors.darkBorder : TColors.borderSecondary,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < languages.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: TSizes.md + 40 + TSizes.md,
                              color: dark ? TColors.darkBorder : TColors.borderSecondary,
                            ),
                          _LanguageRow(
                            languageName: languages[i]['name']!,
                            nativeName: kNativeLanguageNames[languages[i]['code']] ?? '',
                            languageCode: languages[i]['code']!,
                            flagAsset: languages[i]['flag']!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),

      /// -- Kaydet (sabit)
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.white,
          border: Border(
            top: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.back(),
                label: Text(TTexts.saveSettings.tr),
                icon: const Icon(Icons.check_rounded),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hap biçimli arama kutusu (mağaza ekranıyla aynı dil).
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  static const double _height = 48.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_height / 2),
      borderSide: BorderSide(color: dark ? TColors.darkBorder : TColors.borderPrimary),
    );

    return TextField(
      onChanged: onChanged,
      textAlignVertical: TextAlignVertical.center,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: TTexts.searchLanguage.tr,
        filled: true,
        fillColor: dark ? TColors.darkSurface : TColors.white,
        isDense: false,
        constraints: const BoxConstraints(minHeight: _height),
        contentPadding: const EdgeInsets.symmetric(vertical: TSizes.sm + TSizes.xs),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: TSizes.md, right: TSizes.sm + TSizes.xs),
          child: Icon(Icons.search, size: 20, color: TColors.primary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: const SizedBox(width: TSizes.md),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: TColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Tek dil satırı: bayrak + ad + kendi dilindeki adı + seçim işareti.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
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
      final isSelected = controller.selectedLocale.value.languageCode == languageCode;

      return InkWell(
        onTap: () => controller.changeLanguage(languageCode),
        child: Container(
          // Seçili satır zeminiyle işaretleniyor; çerçeve kartın kendisinde.
          color: isSelected
              ? (dark ? TColors.darkAccent : TColors.accent)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 2),
          child: Row(
            children: [
              TCircularImage(image: flagAsset, padding: 0, height: 40, width: 40),
              const SizedBox(width: TSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: Theme.of(context).textTheme.bodyLarge!.apply(
                        fontWeightDelta: isSelected ? 1 : 0,
                      ),
                    ),
                    if (nativeName.isNotEmpty)
                      Text(nativeName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                height: 22,
                width: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? TColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? TColors.primary : TColors.borderPrimary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: TColors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}
