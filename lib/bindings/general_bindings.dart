import 'package:get/get.dart';

import '../data/repositories/address/api_address_repository.dart';
import '../data/repositories/attributes/api_attribute_repository.dart';
import '../data/repositories/banners/api_banner_repository.dart';
import '../data/repositories/cart/api_cart_repository.dart';
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
import '../data/repositories/wishlist/api_wishlist_repository.dart';
import '../features/authentication/controllers/otp_controller.dart';
import '../data/services/notifications/notification_service.dart';
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
import '../features/shop/controllers/product/order_controller.dart';
import '../features/shop/controllers/product/product_controller.dart';
import '../features/shop/controllers/product/variation_controller.dart';
import '../features/shop/controllers/review_controller.dart';
import '../features/shop/controllers/search_controller.dart';
import '../features/shop/controllers/store_controller.dart';
import '../utils/helpers/network_manager.dart';

/// Uygulama açılışında kurulan genel bağımlılıklar.
///
/// Repository'ler referansta `fenix: true` ile **tembel** kaydediliyor: hepsi
/// ince API sarmalayıcısı, açılışta 15'ini birden kurmak yalnız soğuk açılışı
/// yavaşlatıyordu. `.instance` / `Get.find()` yine çalışır — nesne ilk
/// erişimde doğar ve sonra ayakta kalır. Aynı kural bu projede de korunuyor.
///
/// FAZ 02'de 15 repository, FAZ 04'te sekiz katalog denetleyicisi açıldı;
/// geri kalanlar geldiği fazda açılacak.
class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    /// -- Çekirdek
    Get.put(NetworkManager());

    // -- Repository'ler (referanstaki sıra ve `fenix: true` korundu)
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

    // FAZ 05 — ürün detayında kullanılan çekirdek denetleyiciler.
    //
    // 🔴 `ProductVariantController` ve `ImagesController` BURADA DEĞİL,
    // `ProductDetailScreen.initState` içinde `Get.put` ile kuruluyor: ikisi de
    // ÜRÜNE ÖZEL durum taşıyor (galeri, seçili model/renk) ve ekran her
    // açıldığında sıfırdan başlamalı. Burada `lazyPut` ile tutulsalardı bir
    // önceki ürünün görselleri/seçimleri yeni ürüne sızardı.
    Get.lazyPut(() => VariationController(), fenix: true);
    Get.lazyPut(() => ReviewController(), fenix: true);

    // -- Kişiselleştirme (FAZ 03'te girişin ihtiyaç duyduğu üçü açıldı)
    // ⚠️ `AddressController` aslında FAZ 09'un; ödeme ekranı adres olmadan
    // çalışamadığı için FAZ 07'de erken geldi (bkz. DURUM.md).
    Get.lazyPut(() => AddressController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => UserController(), fenix: true);
    Get.lazyPut(() => UserSettingsController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);

    // Üç genel anahtar (kayıt aç/kapa, ödeme modu). Anonim uçtan okunuyor;
    // kayıt ekranı giriş yapmamış kullanıcıya da çizileceği için `permanent`
    // ve uygulama açılışında bir kez yükleniyor.
    Get.put(PublicSettingsController(), permanent: true);
    Get.lazyPut(() => OTPController());

    // FAZ 04 — katalog (ekranlar arasında `.instance` ile erişiliyor).
    // `fenix: true`: ekran kapanıp controller düşse bile bir sonraki erişimde
    // yeniden kurulur; ana sayfa ↔ mağaza sekme geçişinde katalog yeniden
    // indirilmesin diye önemli.
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);
    Get.lazyPut(() => BrandController(), fenix: true);
    Get.lazyPut(() => StoreController(), fenix: true);
    Get.lazyPut(() => AllProductsController(), fenix: true);
    Get.lazyPut(() => TSearchController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => BannerController(), fenix: true);

    // Sepet · favori · karşılaştırma · kupon.
    // ⚠️ `CompareController` referansın binding'inde YOK (orada her ekranda
    // `Get.put` ile kuruluyordu); alt gezinmedeki sayaç uygulama açılışında
    // okunduğu için üç sayaç da tek yerden besleniyor.
    Get.lazyPut(() => FavouriteController(), fenix: true);
    Get.lazyPut(() => CompareController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    Get.lazyPut(() => CouponController(), fenix: true);

    // FAZ 07 — ödeme.
    // 🔴 Sıra önemli: `OrderController` kurulurken `AddressController.instance`
    // ve `CheckoutController` okunuyor; ikisi de yukarıda kayıtlı.
    Get.lazyPut(() => CheckoutController(), fenix: true);
    Get.lazyPut(() => OrderController(), fenix: true);

    // FAZ 09 — yerel bildirim servisi.
    // ⚠️ FAZ 07 sipariş sonrası yerel bildirim üretiyordu ama servis hiç
    // kurulmuyordu; `GetxService` olarak burada kuruluyor.
    Get.put(TNotificationService());

    // ⚠️ `LanguageController` burada DEĞİL `main.dart`'ta `permanent`
    // kuruluyor: `GetMaterialApp` başlangıç `locale`'ini ondan okuyor ve
    // `GeneralBindings` o noktada henüz çalışmamış oluyor.
  }
}
