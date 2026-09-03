import 'package:get/get.dart';

import '../data/repositories/address/api_address_repository.dart';
import '../data/repositories/attributes/api_attribute_repository.dart';
import '../data/repositories/banners/api_banner_repository.dart';
import '../data/repositories/categories/api_category_repository.dart';
import '../data/repositories/chat/api_chat_repository.dart';
import '../data/repositories/notifications/api_notification_repository.dart';
import '../data/repositories/order/api_order_repository.dart';
import '../data/repositories/product/api_products_repository.dart';
import '../data/repositories/reviews/api_reviews_repository.dart';
import '../data/repositories/settings/api_settings_repository.dart';
import '../data/repositories/stats/api_order_stats_repository.dart';
import '../data/repositories/user/api_user_repository.dart';
import '../data/repositories/user/api_user_settings_repository.dart';
import '../data/repositories/cart/api_cart_repository.dart';
import '../data/repositories/wishlist/api_wishlist_repository.dart';
import '../features/authentication/controllers/otp_controller.dart';
import '../features/personalization/controllers/public_settings_controller.dart';
import '../features/personalization/controllers/settings_controller.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../features/personalization/controllers/user_settings_controller.dart';
import '../utils/helpers/network_manager.dart';

/// Uygulama açılışında kurulan genel bağımlılıklar.
///
/// Kayıt sırası referanstakiyle aynı tutulur. Yorumda kalan satırlar henüz
/// gelmemiş controller'lara aittir; her biri ait olduğu fazda açılacak.
class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    /// -- Çekirdek
    Get.put(NetworkManager());

    /// -- Repository'ler (FAZ 02'de açıldı)
    /// `fenix: true` ile tembel kayıt: hepsi ince API sarmalayıcı, açılışta
    /// yan etkileri yok; 15'ini birden kurmak yalnız soğuk açılışı
    /// yavaşlatıyordu. `.instance` / `Get.find()` yine çalışır — nesne ilk
    /// erişimde kurulur ve sonrasında ayakta kalır.
    Get.lazyPut(() => ApiAddressRepository(), fenix: true);
    Get.lazyPut(() => ApiUserRepository(), fenix: true);
    Get.lazyPut(() => ApiUserSettingsRepository(), fenix: true);
    Get.lazyPut(() => ApiSettingsRepository(), fenix: true);
    Get.lazyPut(() => ApiNotificationRepository(), fenix: true);
    Get.lazyPut(() => ApiProductRepository(), fenix: true);
    Get.lazyPut(() => ApiBannerRepository(), fenix: true);
    Get.lazyPut(() => ApiCategoryRepository(), fenix: true);
    Get.lazyPut(() => ApiOrderRepository(), fenix: true);
    Get.lazyPut(() => ApiReviewsRepository(), fenix: true);
    Get.lazyPut(() => ApiAttributeRepository(), fenix: true);
    Get.lazyPut(() => ApiOrderStatsRepository(), fenix: true);
    Get.lazyPut(() => ApiChatRepository(), fenix: true);
    Get.lazyPut(() => ApiCartRepository(), fenix: true);
    Get.lazyPut(() => ApiWishlistRepository(), fenix: true);

    /// FAZ 05 — ürün detayında kullanılan çekirdek controller'lar
    // Get.lazyPut(() => VariationController(), fenix: true);
    // Get.lazyPut(() => ImagesController(), fenix: true);

    /// -- Kişiselleştirme (FAZ 03'te açıldı)
    /// `UserController` ve `UserSettingsController` girişten hemen sonra
    /// `screenRedirect()` içinde çağrılıyor; `SettingsController`'ı da
    /// `UserController` kuruyor.
    // FAZ 09 — Get.lazyPut(() => AddressController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => UserController(), fenix: true);
    Get.lazyPut(() => UserSettingsController(), fenix: true);
    // FAZ 09 — Get.lazyPut(() => NotificationController(), fenix: true);

    /// FAZ 34 — üç genel anahtar (kayıt aç/kapa, ödeme modu). Anonim uçtan
    /// okunuyor; kayıt ekranı giriş yapmamış kullanıcıya da çizilecek, bu
    /// yüzden `permanent` ve uygulama açılışında bir kez yükleniyor.
    Get.put(PublicSettingsController(), permanent: true);
    Get.lazyPut(() => OTPController());

    /// FAZ 04 / 06 — mağaza (ekranlar arasında `.instance` ile erişiliyor)
    // Get.lazyPut(() => CategoryController(), fenix: true);
    // Get.lazyPut(() => FavouriteController(), fenix: true);
    // Get.lazyPut(() => ProductController(), fenix: true);
    // Get.lazyPut(() => CartController(), fenix: true);
    // Get.lazyPut(() => CouponController(), fenix: true);

    /// FAZ 09 — bildirim servisi
    // Get.put(TNotificationService());

    /// FAZ 11 — dil
    // Get.put(LanguageController());
  }
}
