/// Ortak "başarılı" ekranı: animasyon + başlık + açıklama + tek düğme.
///
/// Devam düğmesinin ne yapacağını çağıran belirler ([onPressed]); ekran
/// kendi başına yönlendirme yapmaz.
library;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../styles/spacing_styles.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.image, required this.title, required this.subTitle, required this.onPressed});

  final String image, title, subTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight * 2,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Image
                const SizedBox(height: TSizes.spaceBtwSections * 2),
                Lottie.asset(image, width: MediaQuery.of(context).size.width * 0.8),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Title & SubTitle
                Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(subTitle, style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: onPressed, child: const Text(TTexts.tContinue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
