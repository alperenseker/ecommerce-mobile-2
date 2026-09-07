/// Karşılaştırma düğmesi — ürün kimliğini ayrı alan olarak alan sürüm.
///
/// Referansta iki ayrı dosyada aynı adla iki sınıf var; ikisi de kullanılıyor
/// (bkz. `favourite_icon/compare_icon.dart`). KURALLAR §4 gereği ikisi de
/// taşındı, birleştirilmedi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../features/shop/controllers/product/compare_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/colors.dart';
import '../../icons/t_circular_icon.dart';

/// Toggles a product in/out of the comparison list. Drop it anywhere and pass
/// a product — it owns its own add/remove logic (like [TFavouriteIcon]).
class TCompareIcon extends StatelessWidget {
  const TCompareIcon({
    super.key,
    required this.productId,
    required this.product,
    this.width = 32,
    this.height = 32,
    this.size = 16,
  });

  final double? width, height, size;
  final String productId;
  final ProductModel product;

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
        color: controller.isInCompare(productId) ? TColors.primary : null,
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
    controller.toggleCompare(productId, product);
  }
}
