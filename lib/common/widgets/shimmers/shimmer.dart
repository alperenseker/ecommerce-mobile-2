/// Yükleme parıltısı (shimmer) temel bloğu.
///
/// TASARIM.md §6: geçiş `softGrey` → `lightGrey` arasında olur. Referanstaki
/// `Colors.grey[300]/[100]` çifti yeni palette soğuk duruyordu.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class TShimmerEffect extends StatelessWidget {
  const TShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.radius = TSizes.borderRadiusMd,
    this.color,
  });

  final double width, height, radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Shimmer.fromColors(
      baseColor: dark ? TColors.darkSurface : TColors.softGrey,
      highlightColor: dark ? TColors.darkBorder : TColors.lightGrey,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? (dark ? TColors.darkSurface : TColors.softGrey),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
