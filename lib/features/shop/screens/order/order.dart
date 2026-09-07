/// "Siparişlerim" — kullanıcının alışverişleri (sipariş grupları).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import 'widgets/orders_list.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// -- Başlık
      appBar: TAppBar(
        title: Text(TTexts.myOrders.tr, style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(TSizes.defaultSpace),

        /// -- Alışverişler
        child: TOrderListItems(),
      ),
    );
  }
}
