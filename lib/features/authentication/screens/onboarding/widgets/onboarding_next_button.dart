import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/onboarding_controller.dart';

/// Tanıtımda bir sonraki sayfaya geçiren yuvarlak düğme.
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
        // TASARIM.md §2: eylem rengi indigo; referanstaki siyah düğme kalktı.
        style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: TColors.primary),
        child: const Icon(Iconsax.arrow_right_3, color: TColors.white),
      ),
    );
  }
}
