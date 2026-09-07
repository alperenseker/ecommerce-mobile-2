/// Ürün detayının altına sabitlenen eylem çubuğu: miktar seçici + "sepete ekle".
///
/// Stok kuralı tek kaynaktan ([TProductStock]) okunur:
///   stokta var → düğme açık · **ön sipariş** (stoksuz sipariş yetkisi olan
///   bayi) → düğme AÇIK · stok yok + yetki yok → düğme KAPALI ve "stokta yok".
/// "Stokta yok" ile "siparişe kapalı" aynı şey değildir.
///
/// 🔴 Miktar `CartController.productQuantityInCart` üzerinden okunur: ürün
/// sepetteyse alan sepetteki adetle açılır, "sepete ekle" o adeti **yazar**
/// (üstüne eklemez — referanstaki davranış). Varyant değişince adet yeni
/// ürünün sepetteki adedine döner; bu tazelemeyi `ProductDetailScreen`
/// içindeki `ever(displayProduct, …)` işçisi yapıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/styles/shadows.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../product_cards/widgets/product_stock_badge.dart';
import 'add_remove_cart_button.dart';

class TBottomAddToCart extends StatefulWidget {
  const TBottomAddToCart({super.key, required this.product});

  final ProductModel product;

  @override
  State<TBottomAddToCart> createState() => _TBottomAddToCartState();
}

class _TBottomAddToCartState extends State<TBottomAddToCart> {
  CartController get _cart => CartController.instance;

  /// Ekranda görünen miktar. Sepetteki adet 0 ise 1'den başlar — "0 adet
  /// ekle" anlamsız olurdu.
  int get _quantity {
    final inCart = _cart.productQuantityInCart.value;
    return inCart > 0 ? inCart : 1;
  }

  void _setQuantity(int value) => _cart.productQuantityInCart.value = value < 0 ? 0 : value;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // Yazılabilir miktar alanı klavye açılınca kaybolmasın diye çubuk yukarı
    // kalkar.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final stockState = TProductStock.resolve(widget.product);
    final orderable = stockState.canOrder;

    return Obx(() {
      // Miktar 0'a inerse eklenecek bir şey yoktur.
      final quantity = _quantity;
      final isActive = orderable && quantity >= 1;

      return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          0,
          TSizes.defaultSpace,
          TSizes.sm + keyboardInset,
        ),
        child: Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
            // TASARIM.md §5: üste çıkan katman gölge alır. Değer burada
            // tekrarlanmıyor; tek kaynak `TShadowStyle`.
            boxShadow: [TShadowStyle.overlayShadow],
          ),
          child: Row(
            children: [
              /// Miktar seçici — stok yoksa ve ön sipariş de yoksa kapalı.
              TProductQuantityWithAddRemoveButton(
                quantity: quantity,
                add: orderable ? () => _setQuantity(quantity + 1) : null,
                remove: orderable && quantity > 0 ? () => _setQuantity(quantity - 1) : null,
                onQuantitySet: orderable ? _setQuantity : null,
                addBackgroundColor: orderable ? TColors.primary : TColors.buttonDisabled,
                removeBackgroundColor: orderable ? TColors.primary : TColors.buttonDisabled,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),

              /// Sepete ekle
              Expanded(
                child: SizedBox(
                  height: TSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isActive ? _addToCart : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(orderable ? Iconsax.shopping_bag : Iconsax.slash, size: TSizes.iconSm),
                        const SizedBox(width: TSizes.sm),
                        Flexible(
                          child: Text(
                            (orderable ? TTexts.addToBag : TTexts.outOfStock).tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      );
    });
  }

  void _addToCart() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      // Sepet sunucuda kullanıcıya bağlı; girişsiz kullanıcıya sepet yok.
      authRepo.showSignInRequiredPopup();
      return;
    }

    // `addToCart` miktarı `productQuantityInCart`ten okuyor; ekrandaki değer
    // 0 ise (kullanıcı alanı boşalttı) 1'e yuvarlanır.
    _cart.productQuantityInCart.value = _quantity;
    _cart.addToCart(widget.product);
  }
}
