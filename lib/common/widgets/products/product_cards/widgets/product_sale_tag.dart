/// İndirim rozeti (görselin sol üstünde).
///
/// TASARIM.md §2: indirim rengi mercan (`deal`) — indigo eylem rengiyle
/// karışmasın diye ayrı tutuluyor.
library;

import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class ProductSaleTagWidget extends StatelessWidget {
  const ProductSaleTagWidget({
    super.key,
    required this.salePercentage,
  });

  final String? salePercentage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs / 2),
        decoration: BoxDecoration(
          color: TColors.deal,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          '-$salePercentage%',
          style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.white, fontWeightDelta: 2),
        ),
      ),
    );
  }
}
