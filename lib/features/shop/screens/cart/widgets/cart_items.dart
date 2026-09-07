/// Sepet kalemleri — **şirkete (1C kaynağına) göre gruplu**.
///
/// 🔴 Sepette birden çok şirketin ürünü olabilir ve sipariş şirket başına ayrı
/// doğar (API.md: *bir ödeme = bir grup + şirket başına bir sipariş*). Kalemler
/// bu yüzden şirket başlıkları altında toplanır, her başlık kendi ara toplamını
/// gösterir ve altta "siparişiniz N ayrı siparişe bölünecek" notu çizilir.
/// **Bölme kararını sunucu verir**; buradaki gruplama yalnız gösterimdir.
///
/// Grup sırası kalemlerin sepetteki sırasıdır (bkz. `TErpSource.groupCartItems`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../common/widgets/products/cart/add_remove_cart_button.dart';
import '../../../../../common/widgets/products/cart/cart_item.dart';
import '../../../../../common/widgets/texts/t_product_price_text.dart';
import '../../../../../common/widgets/texts/t_product_title_text.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/cart_controller.dart';
import '../../../controllers/product/product_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../product_detail/product_detail.dart';

class TCartItems extends StatelessWidget {
  const TCartItems({
    super.key,
    this.showAddRemoveButtons = true,
    this.showSplitNote = true,
  });

  /// `false` ise (ör. ödeme ekranı) kalemler salt okunur çizilir. `true` ise
  /// (sepet ekranı) her kalem miktar adımlayıcısı ve çöp kutusu alır.
  final bool showAddRemoveButtons;

  /// Listenin altına "siparişiniz N ayrı siparişe bölünecek" bilgisini koyar.
  /// Yalnız sepette birden çok şirket varsa görünür.
  final bool showSplitNote;

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;

    return Obx(
      () {
        // Obx'in kalem değişikliklerini de görmesi için listeye dokunuyoruz.
        final itemCount = cartController.cartItems.length;
        if (itemCount == 0) return const SizedBox.shrink();

        final groups = cartController.companyGroups;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(height: TSizes.spaceBtwSections),
              _CompanyHeader(name: groups[i].name, subtotal: groups[i].subtotal),
              const SizedBox(height: TSizes.spaceBtwItems),
              _CompanyItems(
                items: groups[i].items,
                showAddRemoveButtons: showAddRemoveButtons,
              ),
            ],
            if (showSplitNote && groups.length > 1) ...[
              const SizedBox(height: TSizes.spaceBtwSections),
              _SplitNote(orderCount: groups.length),
            ],
          ],
        );
      },
    );
  }
}

/// Bir şirket kümesinin başlığı: şirket adı + o kümenin ara toplamı.
class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.name, required this.subtotal});

  final String name;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.shop, size: 16, color: TColors.primary),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₸${subtotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Bir şirkete ait kalemler.
class _CompanyItems extends StatelessWidget {
  const _CompanyItems({required this.items, required this.showAddRemoveButtons});

  final List<CartItemModel> items;
  final bool showAddRemoveButtons;

  @override
  Widget build(BuildContext context) {
    // -- Salt okunur liste (ödeme): sade düzen.
    if (!showAddRemoveButtons) {
      return ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwSections),
        itemBuilder: (_, index) => TCartItem(item: items[index]),
      );
    }

    // -- Düzenlenebilir liste (sepet): adımlayıcı + çöp kutusu.
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: TSizes.spaceBtwItems * 1.5),
      itemBuilder: (_, index) => _CartItemCard(item: items[index]),
    );
  }
}

/// "Siparişiniz N ayrı siparişe bölünecek" bilgilendirmesi.
class _SplitNote extends StatelessWidget {
  const _SplitNote({required this.orderCount});

  final int orderCount;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.infoSoft,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: TColors.info.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle, size: 18, color: TColors.info),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              TTexts.cartSplitNote.trParams({'count': '$orderCount'}),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItemModel item;

  /// Kalemin ürününü yükleyip detay sayfasını açar.
  Future<void> _openProductDetail(String productId) async {
    if (productId.isEmpty) return;
    try {
      final product = await ProductController.instance.getProduct(productId);
      Get.to(() => ProductDetailScreen(product: product));
    } catch (_) {
      // Yut: ürün kaldırılmış olabilir, sepette kalınır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final cartController = CartController.instance;

    // Kalem çevresinde kutu yok — satırları listenin `separatorBuilder`ı ayırır.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// -- Görsel (dokununca ürün detayı açılır)
        TRoundedImage(
          width: 84,
          height: 84,
          isNetworkImage: true,
          imageUrl: item.image ?? '',
          padding: const EdgeInsets.all(TSizes.xs),
          borderRadius: TSizes.productImageRadius,
          backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
          border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
          memCacheWidth: 200,
          onPressed: () => _openProductDetail(item.productId),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),

        /// -- Ad + birim fiyat
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TProductTitleText(title: item.title, maxLines: 2),
              const SizedBox(height: TSizes.xs),
              // Birim fiyat daima `price` (bkz. CartItemModel.unitPrice).
              TProductPriceText(price: item.unitPrice.toStringAsFixed(2)),
            ],
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems / 2),

        /// -- Sil + miktar adımlayıcısı
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// Kalemi tümüyle kaldır (onaylı)
            GestureDetector(
              onTap: () => cartController.removeItemFromCart(item),
              child: const Padding(
                padding: EdgeInsets.only(bottom: TSizes.sm, left: TSizes.sm),
                child: Icon(Iconsax.trash, color: TColors.darkGrey, size: 18),
              ),
            ),

            /// Miktar (+ / −) — değişim iyimser çizilir, hata olursa geri
            /// alınır. Sayı elle de yazılabilir (`onQuantitySet`): 500 adet
            /// isteyen bayi artı düğmesine 500 kez basmasın.
            TProductQuantityWithAddRemoveButton(
              width: 28,
              height: 28,
              iconSize: TSizes.md,
              quantity: item.quantity,
              add: () => cartController.addOneToCart(item),
              remove: () => cartController.removeOneFromCart(item),
              onQuantitySet: (value) => cartController.setQuantity(item, value),
            ),
          ],
        ),
      ],
    );
  }
}
