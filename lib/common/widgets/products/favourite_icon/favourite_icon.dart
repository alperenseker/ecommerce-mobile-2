/// Kartın sağ üstündeki kalp (istek listesi) düğmesi.
///
/// TASARIM.md §6: yuvarlak beyaz düğme (32px), ince çerçeve.
///
/// 🔴 FAZ 06 — istek listesi mantığı `FavouriteController`'da ve o controller
/// FAZ 06'nın kapsamında. Aşağıdaki `// FAZ 06` satırları o fazda açılınca
/// düğme dolu kalbe döner. Misafir kapısı ŞİMDİ çalışıyor.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
// FAZ 06 — import '../../../../features/shop/controllers/product/favourites_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../icons/t_circular_icon.dart';

class TFavouriteIcon extends StatelessWidget {
  /// Ürünü istek listesine ekleyip çıkaran, kendi mantığını taşıyan ikon.
  /// Tasarımınıza koyup ürün kimliğini geçmeniz yeterli.
  const TFavouriteIcon({
    super.key,
    required this.productId,
    required this.productModel,
    this.width = 32,
    this.height = 32,
    this.size = 16,
  });

  final double? width, height, size;
  final String productId;
  final ProductModel productModel;

  @override
  Widget build(BuildContext context) {
    // FAZ 06 — final controller = Get.put(FavouriteController());
    // return Obx(() => TCircularIcon(
    //       icon: controller.isFavourite(productId) ? Iconsax.heart5 : Iconsax.heart,
    //       color: controller.isFavourite(productId) ? TColors.error : null,
    //       onPressed: () => controller.toggleFavoriteProduct(productId, productModel),
    //       ...
    //     ));
    return TCircularIcon(
      width: width,
      height: height,
      size: size,
      showBorder: true,
      icon: Iconsax.heart,
      onPressed: _toggle,
    );
  }

  void _toggle() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }
    // FAZ 06 — FavouriteController.instance.toggleFavoriteProduct(productId, productModel);
  }
}
