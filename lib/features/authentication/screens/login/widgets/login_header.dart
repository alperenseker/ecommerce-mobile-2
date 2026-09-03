/// Giriş ekranının başlığı: geri düğmesi, marka logosu, başlık ve alt başlık.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class TLoginHeader extends StatelessWidget {
  const TLoginHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Geri düğmesi — dönülecek bir ekran yoksa karşılama ekranına düşer.
        TRoundedContainer(
          padding: EdgeInsets.zero,
          radius: TSizes.borderRadiusMd,
          backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
          child: IconButton(
            onPressed: () =>
                Navigator.canPop(context) ? Get.back() : Get.offAllNamed(TRoutes.welcome),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwItems),
        const Image(
          height: 60,
          image: AssetImage('assets/logos/logo2.png'),
        ),
        Text(TTexts.loginTitle.tr, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.sm),
        Text(TTexts.loginSubTitle.tr, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}
