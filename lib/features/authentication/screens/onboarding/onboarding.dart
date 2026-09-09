import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/onboarding_controller.dart';
import 'widgets/onboarding_dot_navigation.dart';
import 'widgets/onboarding_next_button.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_skip_button.dart';

/// Uygulamayı ilk kez açan kullanıcıya gösterilen üç sayfalık tanıtım.
class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller for managing onboarding logic and state.
    final controller = Get.put(OnBoardingController());
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
      body: Stack(
        children: [
          /// Horizontal Scrollable Pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: TImages.onBoardingImage1,
                title: TTexts.onBoardingTitle1.tr,
                subTitle: TTexts.onBoardingSubTitle1.tr,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage2,
                title: TTexts.onBoardingTitle2.tr,
                subTitle: TTexts.onBoardingSubTitle2.tr,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage3,
                title: TTexts.onBoardingTitle3.tr,
                subTitle: TTexts.onBoardingSubTitle3.tr,
              ),
            ],
          ),

          /// Skip Button
          const TOnBoardingSkipButton(),

          /// Dot Navigation SmoothPageIndicator
          const TOnBoardingDotNavigation(),

          /// Circular Button
          const TOnBoardingNextButton(),
        ],
      ),
    );
  }
}
