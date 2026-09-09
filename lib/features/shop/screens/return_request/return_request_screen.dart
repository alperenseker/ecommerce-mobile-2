/// İade / değişim talepleri listesi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import 'widgets/return_request_list.dart';

class ReturnRequestScreen extends StatelessWidget {
  const ReturnRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(TTexts.returnAndExchange.tr),
        showSkipButton: false,
        showActions: false,
        showBackArrow: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          TSizes.md,
          TSizes.defaultSpace,
          MediaQuery.paddingOf(context).bottom,
        ),
        child: const TReturnRequestListItems(),
      ),
    );
  }
}
