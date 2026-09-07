/// Kartın sağ üstündeki kalp (istek listesi) düğmesi.
///
/// TASARIM.md §6: yuvarlak beyaz düğme (32px), ince çerçeve.
///
/// Dolu/boş kalp `FavouriteController.favorites` aynasından okunur; kart,
/// ürün detayı ve favori listesi böylece kendiliğinden senkron kalır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../features/shop/controllers/product/favourites_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/colors.dart';
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
    // Controller `general_bindings`te kayıtlı; her kart çiziminde `Get.put`
    // çağırmak boşuna bir nesne daha yaratıyordu.
    final controller = FavouriteController.instance;
    return Obx(
      () => TCircularIcon(
        width: width,
        height: height,
        size: size,
        showBorder: true,
        icon: controller.isFavourite(productId) ? Iconsax.heart5 : Iconsax.heart,
        // Dolu kalp mercan (`deal`); indigo eylem rengiyle karışmasın.
        color: controller.isFavourite(productId) ? TColors.deal : null,
        onPressed: () => _toggle(controller),
      ),
    );
  }

  void _toggle(FavouriteController controller) {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      // Favoriler sunucuda kullanıcıya bağlı; misafirin listesi yoktur.
      authRepo.showSignInRequiredPopup();
      return;
    }
    controller.toggleFavoriteProduct(productId, productModel);
  }
}
