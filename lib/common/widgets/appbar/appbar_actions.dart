/// Başlığın sağındaki ortak eylemler: sepet · bildirimler.
///
/// 🔴 Bu şerit ÖNCE destek · bildirim · profil taşıyordu. Destek ve profil
/// **alt gezinmeye** indi (kaldırılan istek listesi ve karşılaştırma
/// sekmelerinin yerine), sepet de alt gezinmeden **buraya** çıktı: sepet
/// alışverişin her adımında bakılan yer, sayacıyla birlikte başlıkta durması
/// alt çubuktan daha görünür. Profil avatarı da artık burada değil, alt
/// çubuğun kendi sekmesinde.
///
/// Tek widget olarak kullanılır: `actions: const [TAppBarActions()]`.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/shop/controllers/product/cart_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';

class TAppBarActions extends StatelessWidget {
  const TAppBarActions({super.key, this.showCart = true, this.showNotifications = true});

  /// Sepet düğmesi. Sepet ekranının kendisinde kapatılır.
  final bool showCart;

  /// Bildirim düğmesi. Bildirim ekranının kendisinde kapatılır.
  final bool showNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCart)
          Obx(() {
            // Sayaç sıfırsa balon HİÇ çizilmez: "0" yazan balon boş sepette de
            // dikkat çekiyordu.
            final count = CartController.instance.noOfCartItems.value;
            final button = IconButton(
              icon: const Icon(Iconsax.shopping_bag, color: TColors.iconPrimaryLight),
              tooltip: TTexts.myCart.tr,
              onPressed: () => Get.toNamed(TRoutes.cart),
            );
            if (count == 0) return button;
            return Badge(
              // TASARIM.md §6: sayaç balonu `deal` rengi.
              backgroundColor: TColors.deal,
              textColor: TColors.white,
              offset: const Offset(-6, 6),
              label: Text(
                '$count',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              child: button,
            );
          }),
        if (showNotifications)
          IconButton(
            icon: const Icon(Iconsax.notification, color: TColors.iconPrimaryLight),
            tooltip: TTexts.notifications.tr,
            onPressed: () => Get.toNamed(TRoutes.notification),
          ),
        const SizedBox(width: TSizes.xs),
      ],
    );
  }
}
