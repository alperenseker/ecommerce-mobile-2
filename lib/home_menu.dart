import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'common/styles/shadows.dart';
import 'common/widgets/drawer/app_sidebar.dart';
import 'utils/constants/colors.dart';
import 'utils/constants/sizes.dart';
import 'utils/helpers/helper_functions.dart';

import 'features/chat/screens/chat/chat_screen.dart';
import 'features/personalization/screens/setting/settings.dart';
import 'features/shop/screens/home/home.dart';
import 'features/shop/screens/store/store.dart';

/// Uygulamanın kabuğu: 4 sekmeli alt gezinme (ana sayfa · mağaza · destek ·
/// profil) ve seçili sekmenin gövdesi.
///
/// 🔴 Gezinme çubuğu ekranın dibine **yapışık değil**: kenarlardan
/// [_barMargin] boşlukla, yuvarlak köşeli, yüzen bir çubuk olarak duruyor.
/// Dibe yapışık çubuk hem cihazın kendi kaydırma çubuğuyla dip dibe geliyor
/// hem de sayfanın parçasıymış gibi okunuyordu.
///
/// Sekme ekranları `IndexedStack` yerine listeden seçiliyor — referanstaki
/// davranışın aynısı: sekme değişince ekran yeniden kuruluyor, böylece
/// listeler her dönüşte tazeleniyor.
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  /// Çubuğun yan kenarlara ve ekranın dibine olan uzaklığı.
  ///
  /// Dip payı yandan fazla: çubuk ekranın dibinden belirgin biçimde
  /// **yukarıda** dursun, altından içerik aksın.
  static const double _barSideMargin = 12.0;
  static const double _barBottomMargin = 20.0;

  /// Yüzen çubuğun yüksekliği ve köşe yarıçapı (hap değil, yumuşak köşe).
  ///
  /// 36px'lik çubuk fazla ince kalmıştı; ikonun rahat nefes aldığı bir ölçüye
  /// çıkarıldı ama hâlâ dibe yapışık ilk hâlinden (56) kısa.
  static const double _barHeight = 54.0;
  static const double _barRadius = 18.0;

  /// Sekme ikonu; çubukla orantılı.
  static const double _iconSize = 24.0;

  /// İkonlar dikeyde ortalanır, sonra bu kadar **yukarı** alınır: çubuğun
  /// altıyla arasında yüksekliğin %5'i kadar pay kalsın diye. Aşağı yapışık
  /// duran ikon çubuğu dengesiz gösteriyordu.
  static const double _iconLift = _barHeight * 0.05;

  /// Seçili sekmenin arkasındaki hap.
  ///
  /// 🔴 Material'in `NavigationBar`'ı burada kullanılmıyor: göstergesi
  /// 64x32'ye **sabit** (Flutter `navigation_bar.dart`, `_kIndicatorHeight`)
  /// ve dışarıdan ölçülendirilemiyor; 36px'lik çubukta çerçeveye değip
  /// çubuğun tamamını boyuyordu. Sekme satırı bu yüzden elde çiziliyor —
  /// davranış aynı, ölçüler çubuğa uyuyor.
  static const double _indicatorWidth = 52.0;
  static const double _indicatorHeight = 34.0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppScreenController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      key: controller.scaffoldKey,

      /// 🔴 Yan menü ANA SAYFANIN değil BU Scaffold'un: içerideki Scaffold'a
      /// bağlıyken menü yalnız gövdeyi örtüyor, yüzen alt gezinme çubuğu
      /// menünün ÜSTÜNDE kalıyordu. Buradan açılınca menü bütün ekranı —
      /// çubuk dahil — kaplıyor.
      drawer: const TAppSidebar(),

      /// Gövde çubuğun ALTINA kadar uzanır: içerik çubuğun altından akıp
      /// gidiyor, çubuk sayfanın parçası değil ekranın orada duran bir
      /// katmanı gibi okunuyor. Karşılığında Scaffold, çubuğun kapladığı
      /// yüksekliği (çubuk + dip payı + cihazın alt güvenli alanı) gövdenin
      /// `MediaQuery` dolgusuna yazıyor; sekme ekranları listelerinin sonuna
      /// `MediaQuery.paddingOf(context).bottom` kadar pay ekleyerek son
      /// satırın çubuğun altında SAKLI kalmasını önlüyor.
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        // Cihazın alt güvenli alanı burada tüketiliyor; sekme satırı aynı
        // boşluğu bir daha eklemesin diye SafeArea dışarıda duruyor.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_barSideMargin, 0, _barSideMargin, _barBottomMargin),
          child: Container(
            /// Çubuk ekranın dibine yapışık DEĞİL: kenarlardan boşluklu,
            /// yuvarlak köşeli, sayfanın üstünde yüzen bir katman.
            /// Ayrım hem 1px çerçeveyle hem kısık gölgeyle veriliyor —
            /// TASARIM.md §5 gölgeyi yalnız gerçekten üste çıkan katmanlara
            /// izin veriyor, yüzen çubuk da onlardan biri.
            height: _barHeight,
            decoration: BoxDecoration(
              color: dark ? TColors.dark : TColors.white,
              borderRadius: BorderRadius.circular(_barRadius),
              border: Border.all(
                color: dark ? TColors.darkBorder : TColors.borderSecondary,
                width: TSizes.dividerHeight,
              ),
              boxShadow: [TShadowStyle.floatingBarShadow],
            ),
            child: ClipRRect(
              // Seçim hapı ve dokunma dalgası köşelerden taşmasın.
              borderRadius: BorderRadius.circular(_barRadius - TSizes.dividerHeight),
              child: Material(
                color: Colors.transparent,
                child: MediaQuery(
                  /// Kullanıcının yazı ölçeği büyükse sayaç balonu ince
                  /// çubuğu taşırıyor; ölçek sabitleniyor.
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: Padding(
                    // İkonları ortalanmış yerlerinden azıcık yukarı iten pay.
                    padding: const EdgeInsets.only(bottom: _iconLift),
                    child: Obx(
                      () => Row(
                        children: [
                          _tab(controller, 0, Iconsax.home),
                          _tab(controller, 1, Iconsax.shop),
                          _tab(controller, 2, Iconsax.headphone),
                          _tab(controller, 3, Iconsax.user),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedMenu.value]),
    );
  }

  /// Tek sekme: seçiliyken ikon indigoya döner ve arkasında yumuşak hap belirir.
  ///
  /// Sayaç balonu YOK: sayacı olan tek sekme sepetti, o da başlığa taşındı.
  Widget _tab(AppScreenController controller, int index, IconData icon) {
    final selected = controller.selectedMenu.value == index;
    final child = Icon(icon, size: _iconSize, color: selected ? TColors.primary : TColors.darkGrey);

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectedMenu.value = index,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: _indicatorWidth,
                height: _indicatorHeight,
                decoration: BoxDecoration(
                  color: selected ? TColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(_indicatorHeight / 2),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Seçili sekmeyi tutan denetleyici.
///
/// Sekme listesi burada duruyor (referanstaki gibi); ekranlar geldikçe
/// [screens] içindeki yer tutucular gerçek ekranlarla değiştirilecek.
class AppScreenController extends GetxController {
  static AppScreenController get instance => Get.find();

  final Rx<int> selectedMenu = 0.obs;

  /// Yan menüyü açmak için kabuğun Scaffold'una tutamak.
  ///
  /// Başlıktaki menü düğmesi `Scaffold.of(context)` ile ULAŞAMAZ: en yakın
  /// Scaffold sekmenin kendi Scaffold'u ve onun menüsü yok. Kabuğa bu
  /// anahtarla erişiliyor.
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  /// Yan menüyü açar (başlıktaki menü düğmesi çağırır).
  void openMenu() => scaffoldKey.currentState?.openDrawer();

  /// Dört sekme: ana sayfa · mağaza · destek · profil.
  ///
  /// 🔴 İstek listesi ve karşılaştırma buradan KALKTI: ikisi de her gün
  /// açılan yerler değil, ürün kartındaki kalp/terazi ile beslenen
  /// **birikimler**. Alt çubuğun iki değerli yuvasını tutuyorlardı; artık
  /// profil sekmesinin içindeler. Sepet de başlığa çıktı
  /// (`TAppBarActions`), yerlerine her ekrandan tek dokunuşla açılması
  /// anlamlı olan destek ve profil geldi.
  ///
  /// İkisi de **sekme kipinde** açılıyor: geri okları yok, çünkü alt
  /// gezinmenin bir sekmesi geri gidilecek bir yer değil.
  final screens = const [
    HomeScreen(),
    StoreScreen(),
    ChatScreen(showBackArrow: false),
    SettingsScreen(isTab: true),
  ];
}
