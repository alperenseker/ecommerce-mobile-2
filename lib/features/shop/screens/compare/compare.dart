/// Karşılaştırma ekranı — ürün başlıkları + özellik blokları.
///
/// 🔴 Sunum tamamen değişti. Eskiden **donuk etiket sütunlu, yatay kaydırılan
/// bir tablo** vardı: telefonda ürün sütunlarının yarısı ekran dışında
/// kalıyordu, kullanıcı karşılaştırmak için sağa sola sürüyordu — oysa
/// karşılaştırmanın bütün anlamı değerleri AYNI ANDA görmek. Yeni düzende
/// etiket, değerlerin **üstünde** tam genişlikte duruyor; altındaki hücreler
/// ekranı eşit bölüşüyor ve yatay kaydırma tamamen kalktı. İki üründe hücre
/// ~%50, dörtte ~%25 genişlik alıyor.
///
/// Alan kuralları aynen korundu (web `pages/compare.js`):
///   1. **Sütunlar eşit genişlikte** — uzun adlı ürün ötekileri ezmez.
///   2. **Ürün adı KIRPILMAZ**, uzunsa alt satıra geçer.
///   3. **Bütün ürünlerde boş olan satır çizilmez** — "—" dolu bir tablo
///      bilgiden çok gürültü.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/appbar_actions.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/products/product_cards/widgets/product_stock_badge.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/erp_source_helper.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/categories_controller.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/compare_controller.dart';
import '../../models/compare_item_model.dart';
import '../../models/product_model.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  /// Başlık kartındaki ürün görselinin yüksekliği.
  static const double _imageH = 96;

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthenticationRepository.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(TTexts.comparison.tr),
        showActions: true,
        showSkipButton: false,
        actions: const [TAppBarActions()],
      ),
      body:
          authRepo.isGuestUser
              ? TEmptyState.signInRequired(message: TTexts.compareLoginText.tr)
              : _body(context, dark),
    );
  }

  Widget _body(BuildContext context, bool dark) {
    final controller = CompareController.instance;

    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const TDelayedLoader();
      }
      if (controller.items.isEmpty) {
        return TEmptyState(
          icon: Iconsax.arrow_swap_horizontal,
          title: TTexts.comparisonEmpty.tr,
          message: TTexts.comparisonEmptyText.tr,
          actionText: TTexts.startShopping.tr,
          onAction: () => Get.offAllNamed(TRoutes.homeMenu),
        );
      }

      final items = controller.items.toList();
      final products = [for (final item in items) controller.productDetails[item.productId]];

      return ListView(
        padding: EdgeInsets.fromLTRB(
          TSizes.defaultSpace,
          TSizes.md,
          TSizes.defaultSpace,
          TSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _summary(context, controller, items.length),
          const SizedBox(height: TSizes.spaceBtwItems),
          _headerCard(context, controller, items, products, dark),
          const SizedBox(height: TSizes.spaceBtwItems),
          ..._specBlocks(context, controller, items, products, dark),
        ],
      );
    });
  }

  /// Kaç ürün karşılaştırılıyor + hepsini temizle.
  Widget _summary(BuildContext context, CompareController controller, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count / ${CompareController.maxItems} ${TTexts.products.tr}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextButton.icon(
          onPressed: controller.clearAll,
          icon: const Icon(Iconsax.trash, size: 16, color: TColors.error),
          label: Text(TTexts.clearAll.tr, style: const TextStyle(color: TColors.error)),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  /// Ürün başlıkları: görsel · ad · fiyat · stok · eylemler.
  ///
  /// Eskiden bunlar da tablonun birer satırıydı; artık tek bir kartta
  /// toplanıyorlar — karşılaştırılan ürünler önce **kim oldukları** ile
  /// tanıtılıyor, özellikler ondan sonra geliyor.
  Widget _headerCard(
    BuildContext context,
    CompareController controller,
    List<CompareItemModel> items,
    List<ProductModel?> products,
    bool dark,
  ) {
    final theme = Theme.of(context).textTheme;

    return _Card(
      dark: dark,
      // Ayırıcı çizgiler en uzun sütun kadar uzasın diye.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) _VerticalRule(dark: dark, stretch: true),
              Expanded(
                child: Padding(
                  // Anahtar, sütun genişliklerini ölçen widget testi için.
                  key: ValueKey('compare-column-${items[i].productId}'),
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.xs),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => controller.openProduct(items[i].productId),
                        child: SizedBox(
                          height: _imageH,
                          child:
                              items[i].mainImage.isEmpty
                                  ? Image.asset(TImages.productImageFallback, fit: BoxFit.contain)
                                  : CachedNetworkImage(
                                    imageUrl: items[i].mainImage,
                                    fit: BoxFit.contain,
                                    memCacheWidth: 320,
                                    errorWidget:
                                        (_, _, _) => Image.asset(TImages.productImageFallback),
                                  ),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),

                      /// Ad KIRPILMAZ: kesilen ad iki ürünü ayırt etmeyi
                      /// imkânsız kılıyor.
                      GestureDetector(
                        onTap: () => controller.openProduct(items[i].productId),
                        child: Text(
                          items[i].productName,
                          textAlign: TextAlign.center,
                          style: theme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: TSizes.xs),

                      /// Fiyat gizliyse rakam da eski fiyat da basılmaz.
                      Text(
                        items[i].isPriceHidden
                            ? TTexts.priceOnRequest.tr
                            : '₸${_fmt(items[i].price)}',
                        textAlign: TextAlign.center,
                        style:
                            items[i].isPriceHidden
                                ? theme.bodySmall
                                : theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (!items[i].isPriceHidden &&
                          items[i].oldPrice != null &&
                          items[i].oldPrice! > items[i].price)
                        Text(
                          '₸${_fmt(items[i].oldPrice)}',
                          style: theme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: TColors.darkGrey,
                          ),
                        ),
                      const SizedBox(height: TSizes.sm),
                      _stockCell(context, items[i], products[i]),
                      const SizedBox(height: TSizes.sm),
                      _actions(context, controller, items[i], products[i]),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sepete ekle + karşılaştırmadan kaldır.
  ///
  /// Stok kuralı [TProductStock] üzerinden okunur; ürün kaydı henüz
  /// gelmemişse "sepete ekle" kapalıdır (neyi ekleyeceğini bilmiyoruz).
  Widget _actions(
    BuildContext context,
    CompareController controller,
    CompareItemModel item,
    ProductModel? product,
  ) {
    final orderable = product != null && TProductStock.resolve(product).canOrder;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 32,
          child: OutlinedButton(
            onPressed:
                orderable
                    ? () {
                      final cart = CartController.instance;
                      cart.addOneToCart(cart.convertToCartItem(product, 1));
                    }
                    : null,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              (orderable ? TTexts.addToBag : TTexts.outOfStock).tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => controller.removeItem(item.comparisonItemId),
          icon: const Icon(Iconsax.trash, size: 14, color: TColors.error),
          label: Text(TTexts.remove.tr, style: const TextStyle(color: TColors.error)),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _stockCell(BuildContext context, CompareItemModel item, ProductModel? product) {
    if (product != null) return ProductStockBadge(product: product, compact: true);
    final inStock = item.stockAmount > 0;
    return _pill(
      context,
      text: (inStock ? TTexts.inStock : TTexts.outOfStock).tr,
      color: inStock ? TColors.success : TColors.darkGrey,
      background: inStock ? TColors.successSoft : TColors.softGrey,
    );
  }

  /// Özellik blokları: etiket üstte tam genişlikte, değerler altında eşit
  /// hücrelerde. Bütün ürünlerde boş olan özellik **hiç çizilmez**.
  List<Widget> _specBlocks(
    BuildContext context,
    CompareController controller,
    List<CompareItemModel> items,
    List<ProductModel?> products,
    bool dark,
  ) {
    final theme = Theme.of(context).textTheme;
    final blocks = <Widget>[];

    void textBlock(String label, List<String> values) {
      if (!values.any((v) => v.trim().isNotEmpty)) return;
      blocks.add(
        _block(context, dark, label, [
          for (final value in values)
            Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.center,
              style:
                  value.trim().isEmpty
                      ? theme.bodyMedium?.copyWith(color: TColors.darkGrey)
                      : theme.bodyMedium,
            ),
        ]),
      );
    }

    textBlock(TTexts.sku.tr, [for (final p in products) p?.sku ?? '']);
    textBlock(TTexts.category.tr, [
      for (var i = 0; i < items.length; i++) _categoryName(items[i], products[i]),
    ]);
    textBlock(TTexts.company.tr, [for (final p in products) TErpSource.label(p?.erpSource)]);
    textBlock(TTexts.unitWeight.tr, [
      for (var i = 0; i < items.length; i++) _measure(products[i]?.weight ?? items[i].weight, 'kg'),
    ]);
    textBlock(TTexts.dimensions.tr, [
      for (var i = 0; i < items.length; i++) _dimensions(items[i], products[i]),
    ]);

    /// Puan: hiçbir üründe değerlendirme yoksa blok çizilmez — sıfır yıldız
    /// dizisi "kötü ürün" izlenimi veriyor (ürün kartıyla aynı kural).
    if (products.any((p) => (p?.reviewsCount ?? 0) > 0)) {
      blocks.add(
        _block(context, dark, TTexts.rating.tr, [
          for (final p in products)
            (p?.reviewsCount ?? 0) > 0
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.star1, color: TColors.star, size: 14),
                    const SizedBox(width: 4),
                    Text((p!.rating ?? 0).toStringAsFixed(1), style: theme.bodyMedium),
                    const SizedBox(width: 2),
                    Text(
                      '(${p.reviewsCount})',
                      style: theme.labelMedium?.apply(color: TColors.darkGrey),
                    ),
                  ],
                )
                : Text('—', style: theme.bodyMedium?.copyWith(color: TColors.darkGrey)),
        ]),
      );
    }

    return blocks;
  }

  /// Tek özellik bloğu.
  Widget _block(BuildContext context, bool dark, String label, List<Widget> cells) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: _Card(
        dark: dark,
        padding: const EdgeInsets.fromLTRB(TSizes.md, TSizes.sm + 2, TSizes.md, TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔴 BÜYÜK HARFE ÇEVRİLMİYOR: Dart'ın `toUpperCase`i yerelden
            // habersiz, Türkçe "i" harfini "I" yapıyor ("İstek" → "ISTEK").
            // Küçük etiket görüntüsü harf aralığıyla veriliyor.
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!
                  .apply(color: TColors.darkGrey, fontWeightDelta: 1)
                  .copyWith(letterSpacing: 0.4),
            ),
            const SizedBox(height: TSizes.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) _VerticalRule(dark: dark),
                  Expanded(child: Center(child: cells[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Küçük hap rozet (ürün kaydı gelmemiş kalemler için).
  Widget _pill(
    BuildContext context, {
    required String text,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Birim ekli ölçü; null ya da 0 ise boş döner (blok kuralına girsin).
  static String _measure(double? value, String unit) =>
      (value == null || value == 0) ? '' : '${_fmt(value)} $unit';

  static String _dimensions(CompareItemModel item, ProductModel? product) {
    final w = product?.width ?? item.width;
    final h = product?.height ?? item.height;
    final d = product?.depth ?? item.depth;
    if ((w ?? 0) == 0 && (h ?? 0) == 0 && (d ?? 0) == 0) return '';
    return '${_fmt(w)} × ${_fmt(h)} × ${_fmt(d)} mm';
  }

  /// Kategori adı: karşılaştırma ucu çoğu zaman `CategoryName` boş gönderiyor
  /// ama `CategoryId` daima geliyor; ad yüklü kategori ağacından bulunur.
  static String _categoryName(CompareItemModel item, ProductModel? product) {
    if (item.categoryName.trim().isNotEmpty) return item.categoryName;
    final id = product?.categoryId ?? item.categoryId;
    if (id == null || id.isEmpty) return '';
    if (!Get.isRegistered<CategoryController>()) return '';
    final match = CategoryController.instance.allCategories.firstWhereOrNull((c) => c.id == id);
    return match?.name ?? '';
  }

  /// Sondaki ".0"ı atar (100.0 → "100", 0.5 → "0.5").
  static String _fmt(double? v) {
    if (v == null) return '0';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
}

/// Ekranın beyaz kartı — TASARIM.md §5: gölge yok, ayrım 1px çizgi.
class _Card extends StatelessWidget {
  const _Card({required this.child, required this.dark, this.padding});

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
      ),
      child: child,
    );
  }
}

/// Hücreleri ayıran ince dikey çizgi.
class _VerticalRule extends StatelessWidget {
  const _VerticalRule({required this.dark, this.stretch = false});

  final bool dark;

  /// Sütun boyunca uzasın mı (başlık kartı) yoksa kısa bir işaret mi kalsın
  /// (özellik blokları).
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: stretch ? null : 20,
      margin: const EdgeInsets.symmetric(horizontal: TSizes.xs),
      color: dark ? TColors.darkBorder : TColors.borderSecondary,
    );
  }
}
