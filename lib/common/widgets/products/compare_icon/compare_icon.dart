/// Karşılaştırma düğmesi — ürün kimliğini ayrı alan olarak alan sürüm.
///
/// Referansta iki ayrı dosyada aynı adla iki sınıf var; ikisi de kullanılıyor
/// (bkz. `favourite_icon/compare_icon.dart`). KURALLAR §4 gereği ikisi de
/// taşındı, birleştirilmedi.
///
/// 🔴 FAZ 06 — `CompareController` o fazda geliyor; aşağıdaki `// FAZ 06`
/// satırları o zaman açılacak.
library;

import 'package:flutter/material.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
// FAZ 06 — import '../../../../features/shop/controllers/product/compare_controller.dart';
import '../../../../features/shop/models/product_model.dart';
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
    // FAZ 06 — final controller = Get.put(CompareController());
    // return Obx(() => TCircularIcon(... controller.isInCompare(productId) ...));
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
    // FAZ 06 — CompareController.instance.toggleCompare(productId, product);
  }
}
