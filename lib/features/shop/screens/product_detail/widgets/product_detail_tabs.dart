/// Ürün detayının sekmeleri: **açıklama · özellikler · yorumlar**.
///
/// Web (`pages/product.js`) ile aynı düzen. Material `TabBarView` yerine tek
/// panel çizilir: sekmelerin içerikleri (2 satırlık açıklama ↔ 40 satırlık
/// yorum listesi) çok farklı yükseklikte ve `TabBarView` sabit yükseklik
/// istiyor; sayfa zaten kaydırılıyor.
///
/// TASARIM.md §6: seçili sekme indigo, altında 2px indigo çizgi; sekme
/// başlıkları **büyük harf değil**.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/product_model.dart';
import 'product_reviews_section.dart';
import 'product_specification.dart';

class TProductDetailTabs extends StatefulWidget {
  const TProductDetailTabs({super.key, required this.product, required this.description});

  final ProductModel product;

  /// Zaten ayrıştırılmış açıklama metni (bkz. `parseDescription`).
  final String description;

  @override
  State<TProductDetailTabs> createState() => _TProductDetailTabsState();
}

class _TProductDetailTabsState extends State<TProductDetailTabs> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final reviewCount = widget.product.reviewsCount ?? 0;

    final labels = <String>[
      TTexts.description.tr,
      TTexts.specifications.tr,
      '${TTexts.reviews.tr} ($reviewCount)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Sekme başlıkları — dar ekranda yatay kayar.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = _selected == index;
              return GestureDetector(
                onTap: () => setState(() => _selected = index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm + TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? TColors.primary
                            : (dark ? TColors.darkBorder : TColors.borderSecondary),
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.titleMedium!.apply(
                          color: selected ? TColors.primary : TColors.darkGrey,
                          fontWeightDelta: selected ? 1 : 0,
                        ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Seçili panel
        switch (_selected) {
          0 => _DescriptionPanel(text: widget.description),
          1 => TProductSpecification(product: widget.product, showHeading: false),
          _ => TProductReviewsSection(product: widget.product),
        },
      ],
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return Text(
        TTexts.noDescription.tr,
        style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
      );
    }
    // 1C metni düz metindir; satır sonları korunur.
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.6),
    );
  }
}
