/// Mağaza ekranının tam sayfa yükleme iskeleti.
///
/// NOT: Referansta da bu widget hiçbir yerden çağrılmıyor (mağaza ekranı
/// doğrudan [TVerticalProductShimmer] kullanıyor). KURALLAR §4 gereği
/// silinmedi, referansla eşitlik için taşındı.
library;

import 'package:flutter/material.dart';

import '../../../../../common/widgets/shimmers/boxes_shimmer.dart';
import '../../../../../common/widgets/shimmers/brands_shimmer.dart';
import '../../../../../common/widgets/shimmers/list_tile_shimmer.dart';
import '../../../../../common/widgets/shimmers/shimmer.dart';
import '../../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../../utils/constants/sizes.dart';

class TStoreShimmerLoader extends StatelessWidget {
  const TStoreShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            SizedBox(height: TSizes.spaceBtwSections),
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TShimmerEffect(width: 100, height: 15),
                TShimmerEffect(width: 55, height: 55, radius: 55),
              ],
            ),
            SizedBox(height: TSizes.spaceBtwSections * 2),
            // Arama
            TShimmerEffect(width: double.infinity, height: 55),
            SizedBox(height: TSizes.spaceBtwSections),

            // Bölüm başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TShimmerEffect(width: 100, height: 15),
                TShimmerEffect(width: 80, height: 12),
              ],
            ),
            SizedBox(height: TSizes.spaceBtwSections),

            // Markalar
            TBrandsShimmer(),
            SizedBox(height: TSizes.spaceBtwSections * 2),

            // Kategoriler
            Row(
              children: [
                Expanded(child: TShimmerEffect(width: 100, height: 15)),
                SizedBox(width: TSizes.spaceBtwItems),
                Expanded(child: TShimmerEffect(width: 100, height: 15)),
                SizedBox(width: TSizes.spaceBtwItems),
                Expanded(child: TShimmerEffect(width: 100, height: 15)),
                SizedBox(width: TSizes.spaceBtwItems),
                Expanded(child: TShimmerEffect(width: 100, height: 15)),
              ],
            ),
            SizedBox(height: TSizes.spaceBtwSections),

            // Kategori markaları
            TListTileShimmer(),
            SizedBox(height: TSizes.spaceBtwSections),
            TBoxesShimmer(),
            SizedBox(height: TSizes.spaceBtwSections),

            // Ürünler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TShimmerEffect(width: 100, height: 15),
                TShimmerEffect(width: 80, height: 12),
              ],
            ),
            SizedBox(height: TSizes.spaceBtwSections),

            TVerticalProductShimmer(),
            SizedBox(height: TSizes.spaceBtwSections * 3),
          ],
        ),
      ),
    );
  }
}
