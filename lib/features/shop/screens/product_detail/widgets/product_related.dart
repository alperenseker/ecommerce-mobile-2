/// "Benzer ürünler": aynı kategorideki diğer ürünler.
///
/// Web `catalog.related()` ile aynı kural — aynı `CategoryId`, kendisi hariç,
/// en çok 6 ürün. Kategori tek alan olarak geliyor (`categoryIds` boş);
/// bkz. `faz/DURUM.md`, FAZ 04 notu.
///
/// Katalog zaten bellekteyse ([ProductController.allProducts]) ek istek
/// atılmaz; boşsa (derin bağlantıyla açılan ürün) kategoriye göre çekilir.
/// Ürün bulunamazsa bölüm **hiç çizilmez** — boş raf kullanıcıya bir şey
/// anlatmıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../data/repositories/product/api_products_repository.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/product/product_controller.dart';
import '../../../models/product_model.dart';

class TProductRelated extends StatefulWidget {
  const TProductRelated({super.key, required this.product, this.limit = 6});

  final ProductModel product;
  final int limit;

  @override
  State<TProductRelated> createState() => _TProductRelatedState();
}

class _TProductRelatedState extends State<TProductRelated> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TProductRelated oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Varyant seçimi ürünü değiştirir; benzerler de yeni ürünün kategorisinden.
    if (oldWidget.product.id != widget.product.id) _future = _load();
  }

  Future<List<ProductModel>> _load() async {
    final categoryId = widget.product.categoryId ?? '';
    if (categoryId.isEmpty) return const [];

    List<ProductModel> pool = ProductController.instance.allProducts;
    if (pool.isEmpty) {
      pool = await ApiProductRepository.instance.fetchProductsByCategory(categoryId);
    }

    return pool
        .where((p) => p.categoryId == categoryId && p.id != widget.product.id)
        .take(widget.limit)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
            child: TVerticalProductShimmer(itemCount: 2),
          );
        }

        final products = snapshot.data ?? const <ProductModel>[];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: TSectionHeading(title: TTexts.relatedProducts.tr, showActionButton: false),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            SizedBox(
              height: TSizes.productCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: TSizes.spaceBtwItems / 2),
                itemBuilder: (_, index) => SizedBox(
                  width: 170,
                  child: TProductCardVertical(product: products[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
