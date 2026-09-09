/// "Siparişlerim" — kullanıcının alışverişleri (sipariş grupları).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import 'widgets/orders_list.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.dark : TColors.light,

      /// -- Başlık
      appBar: TAppBar(
        title: Text(TTexts.myOrders.tr, style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          TSizes.md,
          TSizes.defaultSpace,
          MediaQuery.paddingOf(context).bottom,
        ),

        /// -- Alışverişler
        child: const TOrderListItems(),
      ),
    );
  }
}
