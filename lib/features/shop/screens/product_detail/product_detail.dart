/// Ürün detay ekranı.
///
/// Düzen (TASARIM.md §6 + web `pages/product.js`):
///   galeri → künye (ad · kod · stok · puan · fiyat kutusu) → varyant seçici
///   → sekmeler (açıklama · özellikler · yorumlar) → benzer ürünler,
///   altta sabit "miktar + sepete ekle" çubuğu.
///
/// 🔴 Ekranda gösterilen ürün [ProductVariantController.displayProduct]'tır;
/// kullanıcının dokunduğu ürünle başlar, varyant seçilince o varyantın
/// ÜRÜNÜYLE değişir (her varyant ayrı bir üründür).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/products/cart/bottom_add_to_cart_widget.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/images_controller.dart';
import '../../controllers/product/product_variant_controller.dart';
import '../../models/product_model.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_detail_tabs.dart';
import 'widgets/product_meta_data.dart';
import 'widgets/product_related.dart';
import 'widgets/product_variant_selector.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductVariantController _variantController;
  late final ImagesController _imagesController;

  /// Gösterilen ürün değiştikçe sepetteki adeti tazeleyen işçi; ekran
  /// kapanınca bırakılmalı, yoksa controller ayakta kaldıkça dinlemeye
  /// devam eder.
  Worker? _displayProductWorker;

  @override
  void initState() {
    super.initState();

    // Galeri ve varyant durumu ÜRÜNE ÖZELDİR; ekran her açıldığında yeniden
    // kurulur, yoksa bir önceki ürünün görselleri/seçimleri sızıyor.
    _imagesController = Get.put(ImagesController());
    _imagesController.getAllProductImages(widget.product);

    _variantController = Get.put(ProductVariantController());
    _variantController.initialize(widget.product);

    // Alt çubuktaki miktar alanı, ürünün SEPETTEKİ adediyle açılır. Varyant
    // değişince gösterilen ürün de değişiyor; işçi (`ever`) o an adeti yeni
    // ürüne göre tazeliyor, yoksa önceki varyantın adedi ekranda kalıyor.
    final cartController = CartController.instance;
    cartController.updateAlreadyAddedProductCount(widget.product);
    _displayProductWorker = ever(
      _variantController.displayProduct,
      (ProductModel p) => cartController.updateAlreadyAddedProductCount(p),
    );
  }

  @override
  void dispose() {
    _displayProductWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.white,
      body: Obx(() {
        // Ekranda gösterilen ürün — seçilen varyantın ürünüyle değişir.
        final product = _variantController.displayProduct.value;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1 — Görsel galerisi (+ favori / karşılaştır düğmeleri)
              TProductImageSlider(product: product),

              /// Varyant yüklenirken ince ilerleme çizgisi.
              if (_variantController.isLoading.value)
                const LinearProgressIndicator(minHeight: 2),

              /// 2 — Künye · varyantlar · sekmeler
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TProductMetaData(product: product),

                    /// Varyantı olmayan üründe kendini gizler.
                    const TProductVariantSelector(),

                    TProductDetailTabs(
                      product: product,
                      description: parseDescription(product.description),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],
                ),
              ),

              /// 3 — Benzer ürünler (aynı kategoriden)
              TProductRelated(product: product),

              // Alt çubuğun altında kalan içeriği kurtaran boşluk.
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(
        () => TBottomAddToCart(product: _variantController.displayProduct.value),
      ),
    );
  }
}

/// 1C açıklaması bazen Quill "delta" JSON'u olarak geliyor
/// (`[{"insert":"..."}]`); düz metne çevrilir. Çevrilemezse ham metin
/// olduğu gibi gösterilir — açıklamayı hiç göstermemektense.
String parseDescription(String? jsonDescription) {
  if (jsonDescription == null) return '';

  try {
    final List<dynamic> delta = jsonDecode(jsonDescription);
    String description = '';
    for (var block in delta) {
      if (block is Map && block.containsKey('insert')) {
        description += block['insert'].toString().replaceAll('\\n', '\n');
      }
    }
    return description.trim();
  } catch (e) {
    return jsonDescription;
  }
}
