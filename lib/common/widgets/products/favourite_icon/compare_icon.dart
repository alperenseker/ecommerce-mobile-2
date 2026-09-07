/// Kartın sağ üstündeki karşılaştırma düğmesi (kalbin altında durur).
///
/// TASARIM.md §6: yuvarlak beyaz düğme (32px), ince çerçeve.
///
/// Seçili hâl `CompareController.compareIds` üzerinden okunur; sınır (4 ürün)
/// ve "aynı kategori" kuralı controller'da.
///
/// NOT: Aynı adı taşıyan ikinci bir sınıf `products/compare_icon/` altında da
/// var (referansta da öyle); ikisi farklı imzalarla çağrılıyor, bu yüzden
/// birleştirilmedi (KURALLAR §4).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../features/shop/controllers/product/compare_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/colors.dart';
import '../../icons/t_circular_icon.dart';

/// A custom icon widget which handles its own logic to add or remove products
/// from the Compare list. Pass a product and it does the toggle logic itself.
class TCompareIcon extends StatelessWidget {
  const TCompareIcon({
    super.key,
    required this.productModel,
    this.width = 32,
    this.height = 32,
    this.size = 16,
  });

  final double? width, height, size;
  final ProductModel productModel;

  @override
  Widget build(BuildContext context) {
    // Controller `general_bindings`te kayıtlı (bkz. favourite_icon.dart).
    final controller = CompareController.instance;
    return Obx(
      () => TCircularIcon(
        width: width,
        height: height,
        size: size,
        showBorder: true,
        icon: Icons.balance,
        color: controller.isInCompare(productModel.id) ? TColors.primary : null,
        onPressed: () => _toggle(controller),
      ),
    );
  }

  void _toggle(CompareController controller) {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      // Karşılaştırma listesi sunucuda kullanıcıya bağlı.
      authRepo.showSignInRequiredPopup();
      return;
    }
    controller.toggleCompare(productModel.id, productModel);
  }
}
