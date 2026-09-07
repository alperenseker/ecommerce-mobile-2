/// Radyo düğmeli dil kartı.
///
/// ⚠️ Bu widget'ı `LanguageScreen` **kullanmıyor** — ekranın kendi satırı
/// (`TLanguageTile`) var; referansta da durum aynıydı. Referansla dosya
/// eşliği bozulmasın diye (KURALLAR §4) taşındı ve TASARIM.md paletine
/// çevrildi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/language_controller.dart';

class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key, required this.languageName, required this.languageCode, required this.flagAsset});

  final String languageName;
  final String languageCode;
  final String flagAsset;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(
      () => RadioGroup<String>(
        // `Radio`'nun kendi `groupValue`/`onChanged` alanları Flutter 3.32'de
        // kullanımdan kalktı; seçim artık üstteki `RadioGroup`'tan yönetiliyor.
        groupValue: controller.selectedLocale.value.languageCode,
        onChanged: (value) => controller.changeLanguage(value ?? languageCode),
        child: GestureDetector(
          onTap: () => controller.changeLanguage(languageCode),
          child: TRoundedContainer(
            showBorder: true,
            radius: TSizes.cardRadiusMd,
            borderColor: TColors.borderSecondary,
            backgroundColor: dark ? TColors.darkSurface : TColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    /// -- Bayrak
                    TCircularImage(image: flagAsset, padding: 0, height: 40, width: 40),
                    const SizedBox(width: TSizes.spaceBtwItems),

                    /// -- Dil adı
                    Text(languageName, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),

                /// -- Seçim düğmesi
                Radio<String>(value: languageCode, activeColor: TColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
