/// Markaları tutan controller.
library;

import 'package:get/get.dart';

import '../../../data/repositories/brands/api_brand_repository.dart';
import '../../../data/repositories/product/api_products_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/brand_model.dart';
import '../models/product_model.dart';

class BrandController extends GetxController {
  static BrandController get instance => Get.find();

  RxBool isLoading = true.obs;
  RxList<BrandModel> allBrands = <BrandModel>[].obs;
  RxList<BrandModel> featuredBrands = <BrandModel>[].obs;
  final brandRepository = ApiBrandRepository.instance;

  @override
  void onInit() {
    getFeaturedBrands();
    super.onInit();
  }

  /// -- Markaları yükle
  Future<void> getFeaturedBrands() async {
    try {
      isLoading.value = true;

      final fetchedBrands = await brandRepository.fetchAllItems();

      allBrands.assignAll(fetchedBrands);

      // Öne çıkanlar: en çok 4 marka.
      featuredBrands.assignAll(allBrands.where((brand) => brand.isFeatured).take(4).toList());
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // -- Kategoriye ait markalar
  Future<List<BrandModel>> getBrandsForCategory(String categoryId, int limit) async {
    final brands = await brandRepository.getBrandsForCategory(categoryId, limit);
    return brands;
  }

  /// Markanın ürünleri. [limit] = -1 ise hepsi.
  Future<List<ProductModel>> getBrandProducts(String brandId, int limit) async {
    final all = await ApiProductRepository.instance.fetchAllItems();
    var products = all.where((p) => p.brand?.id == brandId).toList();
    if (limit != -1) products = products.take(limit).toList();
    return products;
  }

  Future<void> updateBrandView(String brandId, BrandModel brand) async {
    int view = brand.viewCount!;
    view++;
    brandRepository.updateSingleField(brandId, {"viewCount": view});
  }
}
