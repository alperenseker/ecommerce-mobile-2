/// Ürün kartının "sepete ekle" düğmesi.
///
/// TASARIM.md §6: **sakin** düğme — beyaz zemin + `borderPrimary` çerçeve,
/// basılınca indigo. Bir ızgarada 10 dolu indigo düğme ekranı bağırtıyor
/// (web'de de aynı gerekçeyle `btn--ghost` kullanılıyor).
///
/// Stok kuralı [TProductStock] üzerinden okunur: stok yoksa ve kullanıcının
/// stoksuz sipariş yetkisi de yoksa düğme **kapalıdır** ve "stokta yok" yazar.
///
/// 🔴 FAZ 06 — sepete ekleme fiilen bu fazda BAĞLANMADI. `CartController`
/// FAZ 06'nın kapsamında (bkz. `faz/06-SEPET-FAVORI-KARSILASTIRMA.md`) ve
/// `VariationController`/`ImagesController` (FAZ 05) üzerinden ürün detayına
/// bağlı. Aşağıdaki `// FAZ 06` satırları o fazda açılacak; düğmenin
/// görünümü, kapalı hâli ve misafir kapısı ŞİMDİ çalışıyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../data/repositories/authentication/authentication_repository.dart';
// FAZ 06 — import '../../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../../features/shop/models/product_model.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
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

    // FAZ 06 — sepetteki adet burada okunacak ve 0'dan büyükse düğme yerine
    // +/- adımlayıcı çizilecek (referanstaki davranış):
    // final quantity = CartController.instance.getProductQuantityInCart(product.id);

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

  /// Sepete ekleme. Misafir kapısı şimdiden çalışıyor; sepetin kendisi
  /// FAZ 06'da bağlanacak.
  void _addToCart() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      // Girişsiz kullanıcıya sepet gösterilmez (TASARIM.md / KURALLAR).
      authRepo.showSignInRequiredPopup();
      return;
    }

    // FAZ 06 — referanstaki hâli:
    // final cartController = CartController.instance;
    // final cartItem = cartController.convertToCartItem(product, 1);
    // cartController.addOneToCart(cartItem);
  }
}
