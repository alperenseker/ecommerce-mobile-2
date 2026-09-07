/// Kupon rotasının bağımlılıkları.
library;

import 'package:get/get.dart';

import '../features/shop/controllers/coupon_controller.dart';

class CouponBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Çekirdek
    Get.lazyPut(() => CouponController());
  }
}
