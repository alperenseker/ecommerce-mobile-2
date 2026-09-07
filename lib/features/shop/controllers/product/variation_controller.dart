/// Öznitelik (beden/renk) tabanlı varyasyon seçimi.
///
/// 🔴 Bu controller, sunucudaki ESKİ varyasyon modelini (`product.variations`,
/// öznitelik değerleri) sürer. Canlı sunucu bugün varyantları **ayrı ürünler**
/// olarak veriyor (`products/{id}/variants`) ve ürün detayındaki asıl seçici
/// [ProductVariantController] üzerinden çiziliyor. Referansta ikisi de var,
/// KURALLAR §4 gereği ikisi de taşındı — biri diğerinin yerine geçmez.
library;

import 'dart:ui';

import 'package:get/get.dart';

import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../models/product_model.dart';
import '../../models/product_variation_model.dart';
import 'cart_controller.dart';
import 'images_controller.dart';

class VariationController extends GetxController {
  static VariationController get instance => Get.find();

  /// Değişkenler
  RxMap selectedAttributes = {}.obs;
  RxString variationStockStatus = ''.obs;
  Rx<ProductVariationModel> selectedVariation = ProductVariationModel.empty().obs;

  /// -- Seçili varyasyonun stok durumu
  void getProductVariationStockStatus() {
    variationStockStatus.value =
        selectedVariation.value.stock > 0 ? TTexts.inStock.tr : TTexts.outOfStock.tr;
  }

  /// -- Ürün değişince seçimleri sıfırla
  void resetSelectedAttributes() {
    selectedAttributes.clear();
    variationStockStatus.value = '';
    selectedVariation.value = ProductVariationModel.empty();
  }

  /// -- Bir öznitelik seçildiğinde varyasyonu çöz
  void onAttributeSelected(ProductModel product, attributeName, attributeValue) {
    // Önce seçilen özniteliği listeye ekle.
    final selectedAttributes = Map<String, dynamic>.from(this.selectedAttributes);
    selectedAttributes[attributeName] = attributeValue;
    this.selectedAttributes[attributeName] = attributeValue;

    // Sonra bütün varyasyonlar arasında AYNI öznitelik kümesini taşıyanı bul.
    // Ör. seçilenler [Renk: Yeşil, Beden: S] → varyasyon [Renk: Yeşil,
    // Beden: S] seçilir.
    final ProductVariationModel selectedVariation = product.variations!.firstWhere(
      (variation) => _isSameAttributeValues(variation.attributeValues, selectedAttributes),
      orElse: () => ProductVariationModel.empty(),
    );

    // Seçilen varyasyonun görselini büyük görsel yap.
    if (selectedVariation.image.isNotEmpty) {
      ImagesController.instance.selectedProductImage.value = selectedVariation.image.value;
    }

    // Seçili varyasyonun sepetteki adedi: alt çubuktaki miktar alanı bu ürüne
    // ait adetle açılsın, önceki varyasyondan kalan sayı sızmasın.
    if (selectedVariation.id.isNotEmpty) {
      final cartController = CartController.instance;
      cartController.productQuantityInCart.value =
          cartController.getVariationQuantityInCart(product.id, selectedVariation.id);
    }

    this.selectedVariation.value = selectedVariation;

    getProductVariationStockStatus();
  }

  /// -- Seçilen öznitelikler bir varyasyonun öznitelikleriyle birebir mi
  bool _isSameAttributeValues(
    Map<String, dynamic> variationAttributes,
    Map<String, dynamic> selectedAttributes,
  ) {
    // Seçilenler 3, varyasyonunki 2 taneyse eşleşme yoktur.
    if (variationAttributes.length != selectedAttributes.length) return false;

    // Tek bir değer bile farklıysa eşleşme yoktur. Ör. [Yeşil, L] x [Yeşil, S]
    for (final key in variationAttributes.keys) {
      if (variationAttributes[key] != selectedAttributes[key]) return false;
    }

    return true;
  }

  /// -- Bir özniteliğin hangi değerleri fiilen stokta
  Set<String?> getAttributesAvailabilityInVariation(
    List<ProductVariationModel> variations,
    String attributeName,
  ) {
    final availableVariationAttributeValues = variations
        .where((variation) =>
            // Boş ya da stoksuz değerler seçilemez.
            variation.attributeValues[attributeName] != null &&
            variation.attributeValues[attributeName]!.isNotEmpty &&
            variation.stock > 0)
        .map((variation) => variation.attributeValues[attributeName])
        .toSet();

    return availableVariationAttributeValues;
  }

  /// Renk listesini metin gösterimine çevirir.
  List<String> convertColorsToStrings(List<Color> colors) {
    return colors.map((color) => THelperFunctions.computeColorValue(color).toString()).toList();
  }

  /// Metin gösterimini renge geri çevirir.
  List<Color> convertStringsToColors(List<String> colorStrings) {
    return colorStrings.map((colorString) => THelperFunctions.restoreColorFromValue(colorString)).toList();
  }
}
