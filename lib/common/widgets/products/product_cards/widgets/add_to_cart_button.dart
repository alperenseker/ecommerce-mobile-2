/// Ürün kartının "sepete ekle" düğmesi.
///
/// TASARIM.md §6: **sakin** düğme — beyaz zemin + `borderPrimary` çerçeve,
/// basılınca indigo. Bir ızgarada 10 dolu indigo düğme ekranı bağırtıyor
/// (web'de de aynı gerekçeyle `btn--ghost` kullanılıyor).
///
/// Stok kuralı [TProductStock] üzerinden okunur: stok yoksa ve kullanıcının
/// stoksuz sipariş yetkisi de yoksa düğme **kapalıdır** ve "stokta yok" yazar.
///
/// Ürün sepetteyse düğme yerine **miktar adımlayıcısı** çizilir (referanstaki
/// davranış): kullanıcı ızgaradan çıkmadan adet artırıp azaltabilsin.
/// Miktar değişimi iyimserdir; sunucu hatasında `CartController` geri alır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../../features/shop/models/product_model.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../cart/add_remove_cart_button.dart';
import 'product_stock_badge.dart';

class ProductCardAddToCartButton extends StatelessWidget {
  const ProductCardAddToCartButton({super.key, required this.product, this.compact = false});

  final ProductModel product;

  /// Yatay kartta daha kısa düğme.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final orderable = TProductStock.resolve(product).canOrder;
    final cartController = CartController.instance;

    return Obx(() {
      // Sepetteki adet 0'dan büyükse düğme yerine adımlayıcı çizilir.
      final quantity = cartController.getProductQuantityInCart(product.id);
      if (quantity > 0) {
        return SizedBox(
          width: double.infinity,
          height: compact ? 28 : 32,
          child: Center(
            child: TProductQuantityWithAddRemoveButton(
              width: compact ? 24 : 28,
              height: compact ? 24 : 28,
              iconSize: TSizes.sm,
              quantity: quantity,
              add: () => cartController.addOneToCart(cartController.convertToCartItem(product, 1)),
              remove: () => cartController.removeOneFromCart(cartController.convertToCartItem(product, 1)),
            ),
          ),
        );
      }
      return _button(context, dark, orderable);
    });
  }

  Widget _button(BuildContext context, bool dark, bool orderable) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 28 : 32,
      child: OutlinedButton(
        onPressed: orderable ? () => _addToCart() : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: dark ? TColors.darkSurface : TColors.white,
          foregroundColor: TColors.primary,
          disabledForegroundColor: TColors.darkGrey,
          side: BorderSide(
            color: orderable
                ? (dark ? TColors.darkBorder : TColors.borderPrimary)
                : (dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(orderable ? Iconsax.shopping_bag : Iconsax.slash, size: 14),
            const SizedBox(width: TSizes.xs),
            Flexible(
              child: Text(
                (orderable ? TTexts.addToBag : TTexts.outOfStock).tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge!.apply(
                      color: orderable ? TColors.primary : TColors.darkGrey,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sepete ekleme.
  void _addToCart() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      // Girişsiz kullanıcıya sepet gösterilmez (TASARIM.md / KURALLAR).
      authRepo.showSignInRequiredPopup();
      return;
    }

    final cartController = CartController.instance;
    final cartItem = cartController.convertToCartItem(product, 1);
    cartController.addOneToCart(cartItem);
  }
}
