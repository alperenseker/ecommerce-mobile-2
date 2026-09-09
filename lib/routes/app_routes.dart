import 'package:get/get.dart';

import '../home_menu.dart';
import 'routes.dart';

// Aşağıdaki importlar ekranları getiren fazlarda açılacak. Rota **sabitleri**
// `routes.dart` içinde eksiksiz duruyor; burada yalnız var olan sayfalar var.
import '../bindings/sign_in_binding.dart';
import '../features/authentication/screens/login/login.dart';
import '../features/authentication/screens/onboarding/onboarding.dart';
import '../features/authentication/screens/otp/otp_screen.dart';
import '../features/authentication/screens/password_configuration/forget_password.dart';
import '../features/authentication/screens/phone_number/phone_number_screen.dart';
import '../features/authentication/screens/pin/register_pin_screen.dart';
import '../features/authentication/screens/pin/update_pin_screen.dart';
import '../features/authentication/screens/pin/verify_pin_screen.dart';
import '../features/authentication/screens/signup/signup.dart';
import '../features/authentication/screens/signup/verify_email.dart';
import '../features/authentication/screens/welcome/welcome_screen.dart';
import '../features/shop/screens/home/home.dart';
import '../features/shop/screens/search/search.dart';
import '../features/shop/screens/store/store.dart';
import '../bindings/coupon_binding.dart';
import '../features/shop/screens/cart/cart.dart';
import '../features/shop/screens/coupon/coupon_screen.dart';
import '../features/shop/screens/favourites/favourite.dart';
import '../features/shop/screens/checkout/checkout.dart';
import '../features/shop/screens/order/order.dart';
import '../features/shop/screens/order/order_detail/order_detail_screen.dart';
import '../features/shop/screens/return_request/return_request_screen.dart';
import '../bindings/language_binding.dart';
import '../bindings/notifcation_binding.dart';
import '../features/personalization/screens/address/add_new_address.dart';
import '../features/personalization/screens/address/address.dart';
import '../features/personalization/screens/language/language_screen.dart';
import '../features/personalization/screens/notification/notifcation_detail_screen.dart';
import '../features/personalization/screens/notification/notifcation_screen.dart';
import '../features/personalization/screens/profile/profile.dart';
import '../features/personalization/screens/setting/settings.dart';
import '../features/chat/screens/chat/chat_screen.dart';
import '../features/chat/screens/chat_list_screen/chat_list_screen.dart';

/// GetX sayfa tablosu.
///
/// Rota adları `TRoutes` üzerinden veriliyor; ekranı olmayan rotalar burada
/// **yorumda** duruyor. Bir fazın işi bittiğinde kendi satırlarını açar —
/// böylece hangi ekranın hangi fazda geleceği tek yerden okunuyor.
class AppRoutes {
  static final pages = [
    GetPage(name: TRoutes.homeMenu, page: () => const HomeMenu()),

    // FAZ 03 — kimlik
    GetPage(name: TRoutes.phoneSignIn, page: () => const PhoneNumberScreen(), binding: SignInBinding()),
    GetPage(name: TRoutes.signup, page: () => const SignupScreen()),
    GetPage(name: TRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: TRoutes.logIn, page: () => const LoginScreen()),
    GetPage(name: TRoutes.forgetPassword, page: () => const ForgetPasswordScreen()),
    GetPage(name: TRoutes.onBoarding, page: () => const OnBoardingScreen()),
    GetPage(name: TRoutes.welcome, page: () => const WelcomeScreen()),
    GetPage(name: TRoutes.pin, page: () => const RegisterPinScreen()),
    GetPage(name: TRoutes.verifyPin, page: () => const VerifyPinScreen()),
    GetPage(name: TRoutes.updatePin, page: () => const UpdatePinScreen()),
    GetPage(name: TRoutes.otpVerification, page: () => const OtpScreen()),

    // FAZ 04 — katalog
    GetPage(name: TRoutes.home, page: () => const HomeScreen()),
    GetPage(name: TRoutes.store, page: () => const StoreScreen()),
    GetPage(name: TRoutes.search, page: () => SearchScreen()),

    // FAZ 05
    // GetPage(name: TRoutes.productReviews, page: () => const ProductReviewsScreen()),

    // FAZ 06 — karşılaştırmanın rotası YOK (referansta da yok); o ekran
    // yalnız alt gezinme sekmesinden açılıyor.
    GetPage(name: TRoutes.favourites, page: () => const FavouriteScreen()),
    GetPage(name: TRoutes.cart, page: () => const CartScreen(showBackArrow: true)),
    GetPage(name: TRoutes.coupon, page: () => const CouponScreen(), binding: CouponBinding(), transition: Transition.fade),

    // FAZ 07
    GetPage(name: TRoutes.checkout, page: () => const CheckoutScreen()),

    // FAZ 08 — siparişler ve iade.
    // `orderDetail` İKİ görünümü birden karşılar: argüman `OrderGroupModel`
    // ise alışveriş (grup), `OrderModel` ise tek sipariş görünümü açılır
    // (web'deki `?groupId=` / `?orderId=` karşılığı). Referansta da tek rota
    // var, yenisi eklenmedi.
    // `returnRequestDetail` rotası referansta da KAYITLI DEĞİL — ekran
    // listeden `Get.to` ile açılıyor, sabiti `TRoutes`'ta duruyor.
    GetPage(name: TRoutes.order, page: () => const OrderScreen()),
    GetPage(name: TRoutes.orderDetail, page: () => const OrderDetail()),
    GetPage(name: TRoutes.returnRequest, page: () => const ReturnRequestScreen()),

    // FAZ 09 — hesap, adres defteri, ayarlar, bildirimler, dil.
    // `settings` giriş kapısı: başlıktaki profil avatarı (`TProfileActionIcon`)
    // buraya gidiyor, oradan siparişler/adresler/kuponlar açılıyor.
    GetPage(name: TRoutes.settings, page: () => const SettingsScreen()),
    GetPage(name: TRoutes.userProfile, page: () => const ProfileScreen()),
    GetPage(name: TRoutes.userAddress, page: () => const UserAddressScreen()),
    GetPage(name: TRoutes.addNewAddress, page: () => const AddNewAddressScreen(), transition: Transition.fade),
    GetPage(name: TRoutes.notification, page: () => const NotificationScreen(), binding: NotificationBinding(), transition: Transition.fade),
    GetPage(name: TRoutes.notificationDetails, page: () => const NotificationDetailScreen(), binding: NotificationBinding(), transition: Transition.fade),
    GetPage(name: TRoutes.language, page: () => const LanguageScreen(), binding: LanguageBinding()),

    // FAZ 10 — destek sohbeti.
    GetPage(name: TRoutes.chatList, page: () => const ChatListScreen()),
    GetPage(name: TRoutes.chat, page: () => const ChatScreen()),
  ];

  /// Adlı rota bu sürümde açılmış mı.
  ///
  /// Fazlar sırayla geldiği için bir ekran, ona yönlendiren koddan SONRA
  /// yazılabiliyor (ör. FAZ 07'nin onay ekranı FAZ 08'in sipariş detayına
  /// gönderiyor). Yönlendirmeden önce bu sorulur; rota henüz yoksa GetX'in
  /// "bilinmeyen rota" ekranı yerine güvenli bir yere düşülür.
  static bool isRegistered(String name) => pages.any((page) => page.name == name);
}
