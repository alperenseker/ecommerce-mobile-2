/// Onboarding ileri düğmesi — yuvarlak indigo düğme.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/onboarding_controller.dart';

class TOnBoardingNextButton extends StatelessWidget {
  const TOnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: TSizes.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () => OnBoardingController.instance.nextPage(),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: TColors.primary,
          minimumSize: const Size(TSizes.buttonHeight, TSizes.buttonHeight),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Iconsax.arrow_right_3, color: TColors.white),
      ),
    );
  }
}
