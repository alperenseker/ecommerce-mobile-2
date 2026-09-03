/// Kartın sağ üstündeki karşılaştırma düğmesi (kalbin altında durur).
///
/// TASARIM.md §6: yuvarlak beyaz düğme (32px), ince çerçeve.
///
/// 🔴 FAZ 06 — karşılaştırma mantığı `CompareController`'da; o controller
/// FAZ 06'nın kapsamında ve ürün detayına (FAZ 05) bağlı. Aşağıdaki
/// `// FAZ 06` satırları o fazda açılacak.
///
/// NOT: Aynı adı taşıyan ikinci bir sınıf `products/compare_icon/` altında da
/// var (referansta da öyle); ikisi farklı imzalarla çağrılıyor, bu yüzden
/// birleştirilmedi (KURALLAR §4).
library;

import 'package:flutter/material.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
// FAZ 06 — import '../../../../features/shop/controllers/product/compare_controller.dart';
import '../../../../features/shop/models/product_model.dart';
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
    // FAZ 06 — final controller = Get.put(CompareController());
    // return Obx(() => TCircularIcon(
    //       icon: Icons.balance,
    //       color: controller.isInCompare(productModel.id) ? TColors.primary : null,
    //       onPressed: () => controller.toggleCompare(productModel.id, productModel),
    //       ...
    //     ));
    return TCircularIcon(
      width: width,
      height: height,
      size: size,
      showBorder: true,
      icon: Icons.balance,
      onPressed: _toggle,
    );
  }

  void _toggle() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }
    // FAZ 06 — CompareController.instance.toggleCompare(productModel.id, productModel);
  }
}
