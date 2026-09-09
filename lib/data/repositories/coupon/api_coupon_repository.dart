import 'package:get/get.dart';

import '../../../features/shop/models/coupon_model.dart';

/// Kupon repository'si.
///
/// TODO: sunucuda `/coupons` ucu yok. Eklenince bu metotlar `dio` ile gerçek
/// isteklere bağlanmalı (bkz. [ApiCategoryRepository] deseni).
class ApiCouponRepository extends GetxController {
  static ApiCouponRepository get instance => Get.isRegistered<ApiCouponRepository>() ? Get.find() : Get.put(ApiCouponRepository());

  Future<List<CouponModel>> fetchAllItems() async => [];

  Future<CouponModel> fetchSingleItem(String id) async => CouponModel.empty();

  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {}
}
