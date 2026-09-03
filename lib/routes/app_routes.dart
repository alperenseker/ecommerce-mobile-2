import 'package:get/get.dart';

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
import '../home_menu.dart';
import 'routes.dart';

/// Adlı rotaların sayfa eşlemesi.
///
/// Rota **sabitleri** (`TRoutes`) referansla birebirdir; buradaki sayfalar ise
/// ekranlar yazıldıkça açılır. Yorumdaki her satır hangi fazda açılacağını
/// söyler — sırayı bozmamak için satırlar silinmedi.
class AppRoutes {
  static final pages = [
    GetPage(name: TRoutes.homeMenu, page: () => const HomeMenu()),

    /// FAZ 03 — kimlik (giriş, kayıt, OTP, PIN)
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

    /// FAZ 04 — katalog (ana sayfa, mağaza, arama)
    // GetPage(name: TRoutes.home, page: () => const HomeScreen()),
    // GetPage(name: TRoutes.store, page: () => const StoreScreen()),
    // GetPage(name: TRoutes.search, page: () => SearchScreen()),

    /// FAZ 05 — ürün detayı ve yorumlar
    /// (referansta da yorumdaydı, ekran ProductDetail içinden açılıyor)
    // GetPage(name: TRoutes.productReviews, page: () => const ProductReviewsScreen()),

    /// FAZ 06 — sepet · favori · karşılaştırma · kupon
    // GetPage(name: TRoutes.favourites, page: () => const FavouriteScreen()),
    // GetPage(name: TRoutes.cart, page: () => const CartScreen(showBackArrow: true)),
    // GetPage(name: TRoutes.coupon, page: () => const CouponScreen(), binding: CouponBinding(), transition: Transition.fade),

    /// FAZ 07 — ödeme
    // GetPage(name: TRoutes.checkout, page: () => const CheckoutScreen()),

    /// FAZ 08 — siparişler ve iade
    // GetPage(name: TRoutes.order, page: () => const OrderScreen()),
    // GetPage(name: TRoutes.orderDetail, page: () => const OrderDetail()),
    // GetPage(name: TRoutes.returnRequest, page: () => const ReturnRequestScreen()),

    /// FAZ 09 — hesap, adres, ayarlar, bildirim
    // GetPage(name: TRoutes.settings, page: () => const SettingsScreen()),
    // GetPage(name: TRoutes.userProfile, page: () => const ProfileScreen()),
    // GetPage(name: TRoutes.userAddress, page: () => const UserAddressScreen()),
    // GetPage(name: TRoutes.addNewAddress, page: () => const AddNewAddressScreen(), transition: Transition.fade),
    // GetPage(name: TRoutes.notification, page: () => const NotificationScreen(), binding: NotificationBinding(), transition: Transition.fade),
    // GetPage(name: TRoutes.notificationDetails, page: () => const NotificationDetailScreen(), binding: NotificationBinding(), transition: Transition.fade),

    /// FAZ 10 — destek sohbeti
    // GetPage(name: TRoutes.chatList, page: () => const ChatListScreen()),
    // GetPage(name: TRoutes.chat, page: () => ChatScreen()),

    /// FAZ 11 — dil seçimi
    // GetPage(name: TRoutes.language, page: () => const LanguageScreen()),
  ];
}
