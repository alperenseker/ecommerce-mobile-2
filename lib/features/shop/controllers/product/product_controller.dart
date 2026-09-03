/// Katalog ürünlerini tutan ana controller.
///
/// Ana sayfanın üç bloğu (yeni gelenler, öne çıkanlar, en çok görüntülenen)
/// **tek** katalog çağrısından türetilir; referansta her liste ayrı ayrı
/// `fetchAllItems()` çağırıyordu ve açılışta katalog 3 kez indiriliyordu —
/// ana sayfa/mağaza yavaşlığının ana kaynağı buydu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/product/api_products_repository.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/user_settings_controller.dart';
import '../../models/product_model.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  var selectedSize = 'M'.obs;
  var selectedColor = Colors.black.obs;

  // Beden güncelle
  void updateSize(String size) {
    selectedSize.value = size;
  }

  // Renk güncelle
  void updateColor(Color color) {
    selectedColor.value = color;
  }

  final isLoading = false.obs;
  var selectedChip = 'Trending'.obs;
  final productRepository = ApiProductRepository.instance;
  RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  RxList<ProductModel> newArrivalProducts = <ProductModel>[].obs;
  RxList<ProductModel> mostViewedProducts = <ProductModel>[].obs;
  RxList<ProductModel> bestSellerProducts = <ProductModel>[].obs;

  /// Ana sayfanın kategori bloklarında kullanılan tam katalog. Kategori
  /// başına ayrı istek atmamak için burada tutuluyor.
  RxList<ProductModel> allProducts = <ProductModel>[].obs;

  /// -- Ürünleri arka uçtan yükle
  @override
  void onInit() {
    fetchHomeProducts();
    super.onInit();
  }

  /// Kataloğu bir kez çeker, ana sayfanın bütün listelerini ondan türetir.
  Future<void> fetchHomeProducts() async {
    try {
      isLoading.value = true;
      final all = await productRepository.fetchAllItems();

      allProducts.assignAll(all);
      featuredProducts.assignAll(all.where((p) => p.isFeatured));
      newArrivalProducts.assignAll(all.where((p) => p.isNewArrival));

      final mostViewed = [...all]..sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
      mostViewedProducts.assignAll(mostViewed);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void selectChip(String chipName) {
    selectedChip.value = chipName;
  }

  // Seçili çipe göre gösterilecek listeyi verir.
  List<ProductModel> get selectedProductList {
    switch (selectedChip.value) {
      case 'Most Viewed':
        return mostViewedProducts;
      case 'Best Sellers':
        return bestSellerProducts;
      case 'Trending':
        return featuredProducts;
      default:
        return bestSellerProducts;
    }
  }

  /// Öne çıkan ürünleri ayrıca yükle.
  void fetchFeaturedProducts() async {
    try {
      isLoading.value = true;

      final all = await productRepository.fetchAllItems();
      final products = all.where((p) => p.isFeatured).toList();

      featuredProducts.assignAll(products);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void fetchNewArrivalProducts() async {
    try {
      final all = await productRepository.fetchAllItems();
      final products = all.where((p) => p.isNewArrival).toList();
      newArrivalProducts.assignAll(products);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// En çok görüntülenen ürünleri ayrıca yükle.
  void fetchMostViewedProducts() async {
    try {
      isLoading.value = true;

      final products = await productRepository.fetchAllItems();

      // Görüntülenme sayısına göre azalan.
      products.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));

      mostViewedProducts.assignAll(products);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Ürünün fiyatı ya da varyantlı üründe fiyat aralığı.
  String getProductPrice(ProductModel product) {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    // Varyant yoksa basit fiyat (indirimli varsa o).
    if (product.productType == ProductType.simple || (product.variations?.isEmpty ?? true)) {
      return ((product.salePrice ?? 0.0) > 0.0 ? product.salePrice : product.price).toString();
    } else {
      // Varyantlar arasındaki en küçük ve en büyük fiyatı bul.
      for (var variation in product.variations!) {
        double priceToConsider = variation.salePrice > 0.0 ? variation.salePrice : variation.price;

        if (priceToConsider < smallestPrice) {
          smallestPrice = priceToConsider;
        }

        if (priceToConsider > largestPrice) {
          largestPrice = priceToConsider;
        }
      }

      if (smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        return '$smallestPrice - ₸$largestPrice';
      }
    }
  }

  /// -- İndirim yüzdesi
  String? calculateSalePercentage(double originalPrice, double? salePrice) {
    if (salePrice == null || salePrice <= 0.0) return null;
    if (originalPrice <= 0) return null;

    double percentage = ((originalPrice - salePrice) / originalPrice) * 100;
    return percentage.toStringAsFixed(0);
  }

  /// -- Ürünün stok durumu metni
  ///
  /// Stokta olmayan ürün, kullanıcıda `CanOrderWithoutStock` yetkisi varsa
  /// "stokta yok" yerine "ön sipariş" der (bkz. [ProductStockBadge]).
  String getProductStockStatus(ProductModel product) {
    final bool inStock;
    if (product.productType.name == ProductType.simple.name) {
      inStock = product.stock > 0 && !(product.isOutOfStock ?? false);
    } else {
      final stock = product.variations?.fold(0, (previousValue, element) => previousValue + element.stock);
      inStock = stock != null && stock > 0;
    }

    if (inStock) return TTexts.inStock.tr;

    final canOrderWithoutStock =
        Get.isRegistered<UserSettingsController>() && UserSettingsController.instance.canOrderWithoutStock;
    return canOrderWithoutStock ? TTexts.preOrder.tr : TTexts.outOfStock.tr;
  }

  Future<void> updateProductStock(String productId, int quantitySold, String variationId) async {
    try {
      final product = await productRepository.fetchSingleItem(productId);

      if (variationId.isEmpty) {
        product.soldQuantity += quantitySold;

        await productRepository.updateItem(product);
      } else {
        final variation = product.variations!.where((variation) => variation.id == variationId).first;
        variation.soldQuantity += quantitySold;
        await productRepository.updateItem(product);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  Future<ProductModel> getProduct(String productId) async {
    return await productRepository.fetchSingleItem(productId);
  }

  Future<List<ProductModel>> getAllNewArrivalProduct() async {
    return await productRepository.fetchAllItems();
  }

  Future<void> updateProductView(String productId, ProductModel product) async {
    int view = product.views ?? 0;
    view++;
    await productRepository.updateSingleField(productId, {"views": view});
  }

  Future<void> addProductLike(String productId, ProductModel product) async {
    // Beğeni sayacı sunucuda henüz yok; referansta da yorumda bırakılmış.
    // await productRepository.updateSingleField(productId, {"likes": like});
  }

  Future<void> removeProductLike(String productId, ProductModel product) async {
    // Bkz. [addProductLike].
    // await productRepository.updateSingleField(productId, {"likes": like});
  }
}
