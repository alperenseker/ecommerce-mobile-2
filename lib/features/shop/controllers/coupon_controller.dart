/// Kupon controller'ı.
///
/// ⚠️ Sunucuda kupon ucu HENÜZ YOK (`ApiCouponRepository` boş liste döndürüyor,
/// referansta da öyle). Ekran bu yüzden bugün "kupon yok" boş durumunu
/// gösteriyor; uç eklenince repository'yi bağlamak yetecek.
///
/// Uygulanan kupon burada tutulur; ödeme sayfası (FAZ 07) kodu buradan okur —
/// kupon ekranı sipariş oluşturmaz, yalnız seçimi taşır.
library;

import 'package:get/get.dart';

import '../../../data/repositories/coupon/api_coupon_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/coupon_model.dart';
import 'product/checkout_controller.dart';

class CouponController extends GetxController {
  static CouponController get instance => Get.find();
  final Rx<CouponModel> coupon = CouponModel.empty().obs;
  RxBool isCouponToggled = false.obs;

  // Repository enjeksiyonu
  final ApiCouponRepository couponRepository = ApiCouponRepository.instance;

  Future<List<CouponModel>> fetchAllItems() {
    return couponRepository.fetchAllItems();
  }

  Future<void> applyCoupon(CouponModel selectedCoupon) async {
    if (selectedCoupon.usageCount == selectedCoupon.usageLimit) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.noMoreCoupon.tr);
    } else {
      coupon.value = selectedCoupon;
      isCouponToggled.value = true;
      // Ödeme özeti kuponu buradan görüyor. Controller kurulu değilse
      // (ödeme ekranı hiç açılmadıysa) dokunulmaz — kupon zaten
      // `coupon` üzerinde taşınıyor ve ekran açılınca oradan okunuyor.
      if (Get.isRegistered<CheckoutController>()) {
        CheckoutController.instance.isCouponToggled.value = true;
      }
      Get.back();
      TLoaders.successSnackBar(title: TTexts.great.tr, message: TTexts.couponApplied.tr);
    }
  }

  Future<void> updateUsageCount(CouponModel coupon) async {
    int count = coupon.usageCount;
    count++;
    await couponRepository.updateSingleField(coupon.id, {
      'usageCount': count,
    });
  }
}
