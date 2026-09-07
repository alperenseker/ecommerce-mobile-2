/// Ürün detayındaki görsel galerisi.
///
/// Küçük resim listesi ve seçili büyük görsel burada tutulur; varyant
/// değişince [getAllProductImages] yeniden çağrılır ve galeri o varyantın
/// görsellerine döner.
///
/// 🔴 Referansta bu metot doğrudan `build()` içinde çağrılıyor ve `Rx`
/// değerini çizim sırasında yazıyordu (GetX'te bu, çizim ortasında yeniden
/// çizim tetikler). Burada liste de controller'da (`images`) tutuluyor ve
/// metot yalnız `initState` / varyant değişiminde çağrılıyor.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../models/product_model.dart';

class ImagesController extends GetxController {
  static ImagesController get instance => Get.find();

  /// Büyük alanda gösterilen görsel.
  RxString selectedProductImage = ''.obs;

  /// Küçük resim şeridinin kaynağı.
  final RxList<String> images = <String>[].obs;

  /// -- Ürünün ve (varsa) varyasyonlarının bütün görselleri
  List<String> getAllProductImages(ProductModel product) {
    // Aynı görsel iki kez listelenmesin diye Set.
    final Set<String> collected = {};

    // Kapak görseli her zaman ilk sırada ve açılışta seçili.
    if (product.thumbnail.isNotEmpty) collected.add(product.thumbnail);

    if (product.images != null) {
      collected.addAll(product.images!.where((e) => e.isNotEmpty));
    }

    if (product.variations != null && product.variations!.isNotEmpty) {
      collected.addAll(
        product.variations!.map((variation) => variation.image.value).where((e) => e.isNotEmpty),
      );
    }

    final list = collected.toList();
    images.assignAll(list);
    selectedProductImage.value = product.thumbnail;
    return list;
  }

  /// -- Görseli tam ekran aç
  void showEnlargedImage(String image) {
    Get.to(
      fullscreenDialog: true,
      () => Dialog.fullscreen(
        backgroundColor: TColors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: TSizes.defaultSpace * 2,
                  horizontal: TSizes.defaultSpace,
                ),
                child: image.isEmpty
                    ? Image.asset(TImages.productImageFallback)
                    : CachedNetworkImage(
                        imageUrl: image,
                        errorWidget: (_, _, _) => Image.asset(TImages.productImageFallback),
                      ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 150,
                  child: OutlinedButton(onPressed: () => Get.back(), child: Text(TTexts.close.tr)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
