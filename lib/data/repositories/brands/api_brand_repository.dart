import 'package:get/get.dart';

import '../../../features/shop/models/brand_model.dart';

/// Marka repository'si.
///
/// TODO: sunucuda `/brands` ucu yok. Eklenince bu metotlar `dio` ile gerçek
/// isteklere bağlanmalı (bkz. [ApiCategoryRepository] deseni).
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
