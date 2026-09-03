import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../utils/constants/sizes.dart';
import '../../utils/helpers/helper_functions.dart';

class TSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: TSizes.appBarHeight,
    left: TSizes.defaultSpace,
    bottom: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
  );
  static const EdgeInsetsGeometry paddingWithDefaultWidth = EdgeInsets.only(
    left: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
  );

  static const EdgeInsetsGeometry paddingOnlyVertical = EdgeInsets.symmetric(
    vertical: TSizes.defaultSpace,
  );

  static const EdgeInsetsGeometry paddingWithDefaultHeight = EdgeInsets.only(
    top: TSizes.defaultSpace,
    left: TSizes.defaultSpace,
    bottom: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
  );
  static EdgeInsetsGeometry topNotchStylePadding = EdgeInsets.only(
    top: THelperFunctions.getTopSafeArea(Get.context!) < 1 ? TSizes.defaultSpace : THelperFunctions.getTopSafeArea(Get.context!),
    left: TSizes.defaultSpace,
    bottom: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
  );
  static EdgeInsetsGeometry topNotchAppBarPaddingWithNoBottom = EdgeInsets.only(
    top: THelperFunctions.getTopSafeArea(Get.context!),
    left: TSizes.defaultSpace,
    right: TSizes.defaultSpace,
  );
}
