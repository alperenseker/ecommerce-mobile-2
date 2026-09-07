/// Bir ürünün bütün değerlendirmeleri (tam ekran).
///
/// Ürün detayının "yorumlar" sekmesindeki blokla **aynı** widget'ı kullanır
/// ([TProductReviewsSection]); iki ayrı yorum listesi bakımı zor oluyordu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../models/product_model.dart';
import 'product_reviews_section.dart';

class SingleProductReviewsScreen extends StatelessWidget {
  const SingleProductReviewsScreen({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(TTexts.allReview.tr.replaceAll(':', '').trim()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          // Tam ekranda daha fazla yorum çekilir.
          child: TProductReviewsSection(product: product, pageSize: 50),
        ),
      ),
    );
  }
}
