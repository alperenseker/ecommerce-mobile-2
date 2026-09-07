/// Sepet ikonu + sayaç balonu.
///
/// TASARIM.md §6: sayaç balonu `deal` (mercan) — sayı dikkat çekmeli ama
/// indigo eylem rengiyle karışmamalı. Sayaç 0 iken balon HİÇ çizilmez;
/// referansta "0" yazan bir balon duruyordu ve boş sepette de dikkat
/// çekiyordu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../features/shop/screens/cart/cart.dart';
import '../../../../utils/constants/colors.dart';

/// Sepet sayacını gösteren özel widget.
class TCartCounterIcon extends StatelessWidget {
  const TCartCounterIcon({
    super.key,
    this.iconColor, // İkon rengi
    this.counterBgColor, // Balon zemin rengi
    this.counterTextColor, // Balon yazı rengi
  });

  final Color? iconColor, counterBgColor, counterTextColor;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Obx(() {
      final count = controller.noOfCartItems.value;
      final icon = IconButton(
        onPressed: () => Get.to(() => const CartScreen(showBackArrow: true)),
        icon: Icon(Iconsax.shopping_bag, color: iconColor),
      );

      if (count <= 0) return icon;

      return Badge(
        backgroundColor: counterBgColor ?? TColors.deal,
        textColor: counterTextColor ?? TColors.white,
        label: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        child: icon,
      );
    });
  }
}
