import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../styles/spacing_styles.dart';

/// Bir akış bittiğinde gösterilen ortak "başarılı" ekranı.
///
/// Devam düğmesinin ne yapacağına çağıran karar veriyor ([onPressed]); ekranın
/// kendisi yönlendirme bilmiyor, bu yüzden kayıt/ödeme gibi farklı akışlarda
/// tekrar kullanılabiliyor.
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
                const SizedBox(height: TSizes.spaceBtwItems/2),
                Text(subTitle, style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: onPressed, child: Text(TTexts.tContinue.tr)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
