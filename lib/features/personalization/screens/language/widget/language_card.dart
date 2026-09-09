/// Dil kartı (radyo düğmeli sürüm).
///
/// ⚠️ Bu widget ile [AllLanguageWidget], [DefaultSectionWidget] ve
/// [LanguageHeader] **ekran tarafından kullanılmıyor** — referansta da
/// kullanılmıyorlardı. KURALLAR §4 ("hiçbir dosya eksilmez") gereği
/// taşındılar; ekranın kendi satır çizimi `language_screen.dart` içinde.
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
  final String languageName;
  final String languageCode;
  final String flagAsset;

  const LanguageCard({
    super.key,
    required this.languageName,
    required this.languageCode,
    required this.flagAsset,
  });

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(
      () => GestureDetector(
        onTap: () => controller.changeLanguage(languageCode),
        child: TRoundedContainer(
          showBorder: true,
          radius: TSizes.borderRadiusMd,
          backgroundColor: dark ? TColors.darkSurface : TColors.white,
          borderColor: TColors.borderSecondary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    TRoundedContainer(
                      radius: TSizes.borderRadiusSm,
                      padding: const EdgeInsets.all(TSizes.sm),
                      backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
                      child: TCircularImage(image: flagAsset, padding: 0, height: 40, width: 40),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Text(
                        languageName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              /// -- Seçim düğmesi
              //
              // ⚠️ Referansta `Radio(groupValue:, onChanged:)` vardı; o iki alan
              // Flutter 3.32'de kullanımdan kalktı. Davranış aynı, sarmalayıcı
              // `RadioGroup` grubu yönetiyor.
              RadioGroup<String>(
                groupValue: controller.selectedLocale.value.languageCode,
                onChanged: (value) => controller.changeLanguage(languageCode),
                child: Radio<String>(value: languageCode, activeColor: TColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
