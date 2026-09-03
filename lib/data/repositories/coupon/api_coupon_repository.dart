/// Kupon doğrulama ve indirim hesabı uçları.
library;

import 'package:get/get.dart';

import '../../../features/shop/models/coupon_model.dart';

/// TODO: backend'de /coupons endpoint'i yok. Eklenince dio ile bu metodları
/// gerçek isteklere bağlayın (bkz. ApiCategoryRepository deseni).
class ApiCouponRepository extends GetxController {
  static ApiCouponRepository get instance => Get.isRegistered<ApiCouponRepository>() ? Get.find() : Get.put(ApiCouponRepository());

  Future<List<CouponModel>> fetchAllItems() async => [];

  Future<CouponModel> fetchSingleItem(String id) async => CouponModel.empty();

  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {}
}
