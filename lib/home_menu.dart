import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'utils/constants/colors.dart';
import 'utils/constants/sizes.dart';
import 'utils/helpers/helper_functions.dart';

/// Uygulamanın ana kabuğu: 5 sekmeli alt gezinme.
///
/// Sekmeler referanstakiyle aynı sırada — ana sayfa · mağaza · favori ·
/// karşılaştır · sepet. Görünüm TASARIM.md §6'daki alt gezinme kuralına
/// uyar: beyaz zemin, 1px üst çizgi, seçili ikon indigo, sayaç balonu `deal`.
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppScreenController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Obx(
        () => Container(
          // Ayrım gölgeyle değil çizgiyle veriliyor (TASARIM.md §5).
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.white,
            border: Border(
              top: BorderSide(
                color: dark ? TColors.darkBorder : TColors.borderSecondary,
                width: TSizes.dividerHeight,
              ),
            ),
          ),
          child: MediaQuery(
            // Sistem yazı büyütmesi alt çubuğu taşırmasın diye ölçek sabit.
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: NavigationBar(
              height: 48,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              selectedIndex: controller.selectedMenu.value,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              indicatorColor: TColors.primary.withValues(alpha: 0.12),
              onDestinationSelected: (index) => controller.selectedMenu.value = index,
              destinations: [
                _dest(Iconsax.home, controller.selectedMenu.value == 0),
                _dest(Iconsax.shop, controller.selectedMenu.value == 1),
                // FAZ 06 — sayaçlar sepet/favori/karşılaştırma controller'ları
                // geldiğinde bağlanacak; referanstaki kaynaklar şunlar:
                //   favori    : FavouriteController.instance.favorites.length
                //   karşılaştır: CompareController.instance.compareIds.length
                //   sepet     : CartController.instance.noOfCartItems.value
                _badgeDest(Iconsax.heart, 0, controller.selectedMenu.value == 2),
                _badgeDest(Icons.balance, 0, controller.selectedMenu.value == 3),
                _badgeDest(Iconsax.shopping_bag, 0, controller.selectedMenu.value == 4),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedMenu.value]),
    );
  }

  /// Sayaçsız sekme; seçiliyken ikon indigoya döner.
  NavigationDestination _dest(IconData icon, bool selected) {
    return NavigationDestination(
      icon: Icon(icon, size: TSizes.iconMd, color: selected ? TColors.primary : TColors.darkGrey),
      label: '',
    );
  }

  /// Sayaç balonlu sekme. Balon rengi `deal`: sayı dikkat çekmeli ama
  /// indigo eylem rengiyle karışmamalı.
  NavigationDestination _badgeDest(IconData icon, int count, bool selected) {
    final iconWidget = Icon(icon, size: TSizes.iconMd, color: selected ? TColors.primary : TColors.darkGrey);
    return NavigationDestination(
      icon: count > 0
          ? Badge(
              backgroundColor: TColors.deal,
              textColor: TColors.white,
              label: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              child: iconWidget,
            )
          : iconWidget,
      label: '',
    );
  }
}

/// Seçili sekmeyi tutan controller. Ekran listesi sabittir; sekme değişince
/// ekranlar yeniden kurulmaz, durumları korunur.
class AppScreenController extends GetxController {
  static AppScreenController get instance => Get.find();

  final Rx<int> selectedMenu = 0.obs;

  /// FAZ 01'de sekmeler yer tutucu. Gerçek ekranlar geldikçe sırayla
  /// değişecek: 0-1 → FAZ 04 (HomeScreen, StoreScreen),
  /// 2-3-4 → FAZ 06 (FavouriteScreen, CompareScreen, CartScreen).
  final screens = const [
    _PlaceholderScreen(title: 'Ana Sayfa', phase: 'FAZ 04'),
    _PlaceholderScreen(title: 'Mağaza', phase: 'FAZ 04'),
    _PlaceholderScreen(title: 'Favoriler', phase: 'FAZ 06'),
    _PlaceholderScreen(title: 'Karşılaştır', phase: 'FAZ 06'),
    _PlaceholderScreen(title: 'Sepet', phase: 'FAZ 06'),
  ];
}

/// Henüz yazılmamış sekmelerin yerini tutan geçici ekran. İskeletin gezinme
/// akışı bununla sınanıyor; ilgili fazda silinecek.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.phase});

  final String title;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title — $phase', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
