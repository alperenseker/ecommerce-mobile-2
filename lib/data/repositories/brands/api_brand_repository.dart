/// Marka uçları (`brands`).
library;

import 'package:get/get.dart';

import '../../../features/shop/models/brand_model.dart';

/// TODO: backend'de /brands endpoint'i yok. Eklenince dio ile bu metodları
/// gerçek isteklere bağlayın (bkz. ApiCategoryRepository deseni).
class ApiBrandRepository extends GetxController {
  static ApiBrandRepository get instance => Get.isRegistered<ApiBrandRepository>() ? Get.find() : Get.put(ApiBrandRepository());

  Future<List<BrandModel>> fetchAllItems() async => [];

  Future<BrandModel> fetchSingleItem(String id) async => BrandModel.empty();

  Future<List<BrandModel>> getFeaturedBrands() async => [];

  Future<List<BrandModel>> getBrandsForCategory(String categoryId, int limit) async => [];

  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {}

  Future<void> uploadDummyData(List<BrandModel> brands) async {
    throw UnsupportedError('Marka toplu veri yükleme backend tarafında henüz desteklenmiyor.');
  }
}
