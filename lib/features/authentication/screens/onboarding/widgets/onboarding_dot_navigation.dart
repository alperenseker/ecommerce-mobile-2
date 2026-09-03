/// Onboarding nokta göstergesi. Seçili nokta indigo (TASARIM.md renk kuralı:
/// seçili durum tek eylem rengiyle verilir).
library;

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/onboarding_controller.dart';

class TOnBoardingDotNavigation extends StatelessWidget {
  const TOnBoardingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;

    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: TSizes.defaultSpace,
      child: SmoothPageIndicator(
        count: 3,
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        effect: const ExpandingDotsEffect(
          activeDotColor: TColors.primary,
          dotColor: TColors.grey,
          dotHeight: 6,
        ),
      ),
    );
  }
}
