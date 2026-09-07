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
import '../data/services/notifications/notification_service.dart';
import '../features/authentication/controllers/otp_controller.dart';
import '../features/personalization/controllers/address_controller.dart';
import '../features/personalization/controllers/notifcation_controller.dart';
import '../features/personalization/controllers/public_settings_controller.dart';
import '../features/personalization/controllers/settings_controller.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../features/personalization/controllers/user_settings_controller.dart';
import '../features/shop/controllers/all_products_controller.dart';
import '../features/shop/controllers/brand_controller.dart';
import '../features/shop/controllers/categories_controller.dart';
import '../features/shop/controllers/coupon_controller.dart';
import '../features/shop/controllers/home_controller.dart';
import '../features/shop/controllers/product/banner_controller.dart';
import '../features/shop/controllers/product/cart_controller.dart';
import '../features/shop/controllers/product/checkout_controller.dart';
import '../features/shop/controllers/product/compare_controller.dart';
import '../features/shop/controllers/product/favourites_controller.dart';
import '../features/shop/controllers/product/images_controller.dart';
import '../features/shop/controllers/product/order_controller.dart';
import '../features/shop/controllers/product/product_controller.dart';
import '../features/shop/controllers/product/variation_controller.dart';
import '../features/shop/controllers/review_controller.dart';
import '../features/shop/controllers/search_controller.dart';
import '../features/shop/controllers/store_controller.dart';
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

    /// FAZ 05 — ürün detayında kullanılan çekirdek controller'lar.
    /// `ProductVariantController` ve `ImagesController` ürüne özel durum
    /// taşıdığı için burada DEĞİL, `ProductDetailScreen.initState` içinde
    /// `Get.put` ile kuruluyor — ekran her açıldığında sıfırdan başlasın.
    Get.lazyPut(() => VariationController(), fenix: true);
    Get.lazyPut(() => ImagesController(), fenix: true);
    Get.lazyPut(() => ReviewController(), fenix: true);

    /// -- Kişiselleştirme (FAZ 03'te açıldı)
    /// `UserController` ve `UserSettingsController` girişten hemen sonra
    /// `screenRedirect()` içinde çağrılıyor; `SettingsController`'ı da
    /// `UserController` kuruyor.
    /// FAZ 07 — adres controller'ı ödeme ekranı için erken geldi (ekranları
    /// FAZ 09'da). Ödeme ekranı, `OrderController` ve adres formları
    /// `.instance` ile okuyor.
    Get.lazyPut(() => AddressController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => UserController(), fenix: true);
    Get.lazyPut(() => UserSettingsController(), fenix: true);
    /// FAZ 09 — bildirimler. Ekranları kendi binding'ini (`NotificationBinding`)
    /// taşıyor; buradaki tembel kayıt, bildirim gönderen diğer akışların
    /// (`.instance`) listeye ulaşabilmesi için.
    Get.lazyPut(() => NotificationController(), fenix: true);

    /// FAZ 34 — üç genel anahtar (kayıt aç/kapa, ödeme modu). Anonim uçtan
    /// okunuyor; kayıt ekranı giriş yapmamış kullanıcıya da çizilecek, bu
    /// yüzden `permanent` ve uygulama açılışında bir kez yükleniyor.
    Get.put(PublicSettingsController(), permanent: true);
    Get.lazyPut(() => OTPController());

    /// FAZ 04 — katalog (ekranlar arasında `.instance` ile erişiliyor).
    /// `fenix: true`: ekran kapanıp controller düşse bile bir sonraki
    /// erişimde yeniden kurulur.
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);
    Get.lazyPut(() => BrandController(), fenix: true);
    Get.lazyPut(() => StoreController(), fenix: true);
    Get.lazyPut(() => AllProductsController(), fenix: true);
    Get.lazyPut(() => TSearchController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => BannerController(), fenix: true);

    /// FAZ 06 — sepet · favori · karşılaştırma · kupon
    /// Üçü de ürün kartlarından, ürün detayından ve alt gezinme sayaçlarından
    /// `.instance` ile okunuyor; `fenix: true` ile ekran kapansa bile bir
    /// sonraki erişimde yeniden kuruluyorlar.
    /// `CompareController` referansın binding'inde YOK (orada her ekranda
    /// `Get.put` ile kuruluyordu); alt gezinme sayacı uygulama açılışında
    /// okunduğu için buraya alındı — üç sayaç aynı yerden beslensin.
    Get.lazyPut(() => FavouriteController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    Get.lazyPut(() => CompareController(), fenix: true);
    Get.lazyPut(() => CouponController(), fenix: true);

    /// FAZ 07 — ödeme.
    /// `CheckoutController` ve `OrderController` ödeme ekranının `initState`
    /// içinde `Get.put` ile kuruluyor (ekran her açıldığında ödeme modu
    /// yeniden okunmalı); buradaki tembel kayıt, ekran kapandıktan sonra
    /// onay ekranının ve bildirimlerin `.instance` çağrılarını ayakta tutar.
    Get.lazyPut(() => CheckoutController(), fenix: true);
    Get.lazyPut(() => OrderController(), fenix: true);

    /// FAZ 09 — yerel bildirim servisi (cihaz üstü bildirimler).
    /// `GetxService`: uygulama boyunca ayakta kalır, `Get.delete` ile düşmez.
    Get.put(TNotificationService());

    /// Dil controller'ı `main.dart`'ta `permanent` kuruluyor — `GetMaterialApp`
    /// başlangıç locale'ini ondan okuduğu için burada geç kalırdı.
  }
}
