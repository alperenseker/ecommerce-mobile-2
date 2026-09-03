/// Ürün kartındaki stok **hapı** ve stok kuralının tek kaynağı.
///
/// 🔴 KURAL (FAZ 04 / web `data/product-model.js` → `M.stock`):
///   `StockAmount > 0 && StockStatus != 'out_of_stock'`   → **var**
///   değilse ve kullanıcıda `CanOrderWithoutStock` varsa   → **ön sipariş**
///   ikisi de değilse                                      → **yok**
/// "Stokta yok" ile "siparişe kapalı" AYNI ŞEY DEĞİLDİR; stoksuz sipariş
/// yetkisi olan bayi stok bitse de sipariş verebilir.
///
/// TASARIM.md §2: var → `success`/`successSoft`, ön sipariş →
/// `warning`/`warningSoft`, yok → `darkGrey`/`softGrey`.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// FAZ 06 — referansta bu bilgi `CartController.canOrderWithoutStock`
// üzerinden okunuyor; o getter de yalnızca aşağıdaki controller'a vekâlet
// ediyor. Sepet controller'ı gelince satır referanstaki hâline dönebilir.
// import '../../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../../features/personalization/controllers/user_settings_controller.dart';
import '../../../../../features/shop/models/product_model.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

/// Bir ürünün stok durumu. Rozet, "sepete ekle" düğmesi ve ürün detayı aynı
/// kaynaktan okusun diye burada tanımlı.
enum ProductStockState {
  /// Stokta var.
  inStock,

  /// Stokta yok ama kullanıcı stoksuz sipariş verebiliyor.
  preOrder,

  /// Stokta yok ve sipariş edilemez.
  outOfStock;

  /// Sepete eklenebilir mi.
  bool get canOrder => this != ProductStockState.outOfStock;
}

/// Stok kuralının yardımcıları.
class TProductStock {
  TProductStock._();

  /// Kullanıcının stoksuz sipariş yetkisi. Ayarlar henüz yüklenmediyse ya da
  /// kullanıcı misafirse yetki **yoktur** (güvenli taraf).
  static bool get canOrderWithoutStock =>
      _controllerReady && UserSettingsController.instance.canOrderWithoutStock;

  /// Ürün fiilen stokta mı: hem miktar hem sunucunun `StockStatus` alanı.
  static bool isInStock(ProductModel product) =>
      product.isInStock && !(product.isOutOfStock ?? false);

  /// Ürünün stok durumunu dosya başındaki kurala göre çözer.
  static ProductStockState resolve(ProductModel product) {
    if (isInStock(product)) return ProductStockState.inStock;
    return canOrderWithoutStock ? ProductStockState.preOrder : ProductStockState.outOfStock;
  }

  /// `UserSettingsController` genel bağımlılıklarda `lazyPut` ile kayıtlı;
  /// `isRegistered` yalnız KURULMUŞ nesne için true döner, bu yüzden
  /// `isPrepared` de sorulur (yoksa ayarlar hiç okunmaz).
  static bool get _controllerReady =>
      Get.isRegistered<UserSettingsController>() || Get.isPrepared<UserSettingsController>();
}

/// Stok durumunu gösteren küçük hap rozet.
class ProductStockBadge extends StatelessWidget {
  const ProductStockBadge({super.key, required this.product, this.compact = false});

  final ProductModel product;

  /// Dar kartlarda (yatay kart) daha küçük dolgu/yazı.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Controller yoksa Obx'in bağımlanacağı bir gözlemlenebilir de olmaz;
    // Obx bu durumda "improper use of GetX" atıyor. O yüzden sabit çizilir.
    if (!TProductStock._controllerReady) return _badge(context, TProductStock.resolve(product));

    final controller = UserSettingsController.instance;
    return Obx(() {
      final canPreOrder = controller.settings.value.canOrderWithoutStock;
      final state = TProductStock.isInStock(product)
          ? ProductStockState.inStock
          : (canPreOrder ? ProductStockState.preOrder : ProductStockState.outOfStock);
      return _badge(context, state);
    });
  }

  Widget _badge(BuildContext context, ProductStockState state) {
    final (Color fg, Color bg, String label, IconData icon) = switch (state) {
      ProductStockState.inStock => (TColors.success, TColors.successSoft, TTexts.inStock.tr, Iconsax.tick_circle),
      ProductStockState.preOrder => (TColors.warning, TColors.warningSoft, TTexts.preOrder.tr, Iconsax.clock),
      ProductStockState.outOfStock => (TColors.darkGrey, TColors.softGrey, TTexts.outOfStock.tr, Iconsax.slash),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TSizes.xs : TSizes.sm,
        vertical: TSizes.xs / 2,
      ),
      // Hap rozet: yarıçap yüksekliğin yarısından büyük.
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: compact ? 10 : 12),
          SizedBox(width: TSizes.xs / 1.5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .apply(color: fg, fontSizeDelta: compact ? -1 : 0, fontWeightDelta: 1),
            ),
          ),
        ],
      ),
    );
  }
}
