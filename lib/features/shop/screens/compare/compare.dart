/// Karşılaştırma ekranı — satır bazlı tablo.
///
/// Solda özellik adı, sağda her ürün için bir sütun; dört ürün yan yana
/// kıyaslanır (web `pages/compare.js` ile aynı okuma yönü).
///
/// 🔴 Üç tasarım kuralı web'den birebir geliyor:
///   1. **Sütunlar eşit genişlikte.** İçeriğe göre bölünen tabloda uzun adlı
///      ürünün sütunu şişip ötekileri eziyordu.
///   2. **Ürün adı KIRPILMAZ**, uzunsa alt satıra geçer. Karşılaştırmada
///      kesilen ad iki ürünü ayırt etmeyi imkânsız kılıyor.
///   3. **Dört üründe de boş olan satır çizilmez** — "—" dolu bir tablo
///      bilgiden çok gürültü.
///
/// Satır yükseklikleri `Table` tarafından o satırın en uzun hücresine göre
/// belirlenir; sabit yükseklik verilirse sarılan ad taşıyor.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/profile_action_icon.dart';
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

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  /// Sabit ölçüler: donuk etiket sütunu ile kaydırılabilir ürün sütunları
  /// aynı hizada kalsın diye. Ürün sütunlarının hepsi **aynı** genişlikte.
  static const double _labelW = 116;
  static const double _colW = 168;
  static const double _imageH = 120;

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthenticationRepository.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async => await Get.offAllNamed(TRoutes.homeMenu),
      child: Scaffold(
        appBar: TAppBar(
          title: Text(TTexts.comparison.tr),
          showActions: true,
          showSkipButton: false,
          actions: const [TProfileActionIcon()],
        ),
        body: authRepo.isGuestUser
            ? TEmptyState.signInRequired(message: TTexts.compareLoginText.tr)
            : _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final controller = CompareController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: TColors.primary));
      }
      if (controller.items.isEmpty) {
        return TEmptyState(
          icon: Icons.balance,
          title: TTexts.comparisonEmpty.tr,
          message: TTexts.comparisonEmptyText.tr,
          actionText: TTexts.startShopping.tr,
          onAction: () => Get.offAllNamed(TRoutes.homeMenu),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(context, controller),
          Expanded(child: _buildTable(context, controller, dark)),
        ],
      );
    });
  }

  /// Tablonun üstü: kalem sayısı + "hepsini temizle".
  Widget _topBar(BuildContext context, CompareController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.sm, TSizes.defaultSpace, TSizes.sm),
      child: Row(
        children: [
          Text(
            '${controller.items.length} / ${CompareController.maxItems} ${TTexts.products.tr}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: controller.clearAll,
            icon: const Icon(Iconsax.trash, size: 18, color: TColors.error),
            label: Text(TTexts.clearAll.tr, style: const TextStyle(color: TColors.error)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, CompareController controller, bool dark) {
    final items = controller.items;
    final products = [for (final item in items) controller.productDetails[item.productId]];
    final rows = _rowSpecs(context, controller, items, products);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, TSizes.defaultSpace),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? TColors.darkSurface : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              // Etiket sütunu dar ve sabit; ürün sütunları BİRBİRİYLE EŞİT.
              columnWidths: {
                0: const FixedColumnWidth(_labelW),
                for (var i = 0; i < items.length; i++) i + 1: const FixedColumnWidth(_colW),
              },
              // Satır yüksekliği en uzun hücreye göre; sarılan ad taşımasın.
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (var i = 0; i < rows.length; i++)
                  TableRow(
                    decoration: BoxDecoration(color: _zebra(i, dark)),
                    children: [
                      _labelCell(context, rows[i].label),
                      for (final cell in rows[i].cells) _valueCell(cell),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelCell(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _valueCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.sm),
      // Görseller ve değerler sütunun ORTASINDA hizalanır.
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  /// Tablo satırları. Metin satırlarında dört ürünün de değeri boşsa satır
  /// **hiç üretilmez** (bkz. [_textRow]).
  List<_Row> _rowSpecs(
    BuildContext context,
    CompareController controller,
    List<CompareItemModel> items,
    List<ProductModel?> products,
  ) {
    final theme = Theme.of(context).textTheme;
    final rows = <_Row>[];

    /// -- Görsel (dokununca ürün detayı açılır)
    rows.add(_Row(TTexts.products.tr, [
      for (final item in items)
        GestureDetector(
          onTap: () => controller.openProduct(item.productId),
          child: SizedBox(
            height: _imageH,
            child: item.mainImage.isEmpty
                ? Image.asset(TImages.productImageFallback, fit: BoxFit.contain)
                : CachedNetworkImage(
                    imageUrl: item.mainImage,
                    fit: BoxFit.contain,
                    memCacheWidth: 320,
                    errorWidget: (_, _, _) => Image.asset(TImages.productImageFallback),
                  ),
          ),
        ),
    ]));

    /// -- Ad: KIRPILMAZ, uzunsa alt satıra geçer.
    rows.add(_Row(TTexts.name.tr, [
      for (final item in items)
        GestureDetector(
          onTap: () => controller.openProduct(item.productId),
          child: Text(
            item.productName,
            textAlign: TextAlign.center,
            style: theme.titleSmall,
          ),
        ),
    ]));

    /// -- Fiyat (gizli fiyatta rakam basılmaz)
    rows.add(_Row(TTexts.price.tr.replaceAll(':', '').trim(), [
      for (final item in items)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.isPriceHidden ? TTexts.priceOnRequest.tr : '₸${_fmt(item.price)}',
              textAlign: TextAlign.center,
              style: item.isPriceHidden
                  ? theme.bodySmall?.copyWith(fontWeight: FontWeight.w500)
                  : theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            // Fiyat gizliyse eski fiyat da gösterilmez (sızıntı olur).
            if (!item.isPriceHidden && item.oldPrice != null && item.oldPrice! > item.price)
              Text(
                '₸${_fmt(item.oldPrice)}',
                style: theme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: TColors.darkGrey,
                ),
              ),
          ],
        ),
    ]));

    /// -- Stok: kuralın tek kaynağı `TProductStock`; ürün kaydı gelmediyse
    /// kalemin kendi stok adedine düşülür.
    rows.add(_Row(TTexts.availability.tr, [
      for (var i = 0; i < items.length; i++)
        products[i] != null
            ? ProductStockBadge(product: products[i]!, compact: true)
            : _pill(
                context,
                text: items[i].stockAmount > 0 ? TTexts.inStock.tr : TTexts.outOfStock.tr,
                color: items[i].stockAmount > 0 ? TColors.success : TColors.darkGrey,
                background: items[i].stockAmount > 0 ? TColors.successSoft : TColors.softGrey,
              ),
    ]));

    /// -- Metin satırları: dördü de boşsa çizilmez.
    _textRow(rows, context, TTexts.sku.tr, [for (final p in products) p?.sku ?? '']);
    _textRow(rows, context, TTexts.category.tr,
        [for (var i = 0; i < items.length; i++) _categoryName(items[i], products[i])]);
    _textRow(rows, context, TTexts.company.tr,
        [for (final p in products) TErpSource.label(p?.erpSource)]);
    _textRow(rows, context, TTexts.unitWeight.tr, [
      for (var i = 0; i < items.length; i++) _measure(products[i]?.weight ?? items[i].weight, 'kg'),
    ]);
    _textRow(rows, context, TTexts.dimensions.tr, [
      for (var i = 0; i < items.length; i++) _dimensions(items[i], products[i]),
    ]);

    /// -- Puan: hiçbir üründe değerlendirme yoksa satır çizilmez (sıfır
    /// yıldız dizisi "kötü ürün" izlenimi veriyor — FAZ 04'teki kartla aynı
    /// kural).
    final hasAnyRating = products.any((p) => (p?.reviewsCount ?? 0) > 0);
    if (hasAnyRating) {
      rows.add(_Row(TTexts.rating.tr, [
        for (final p in products)
          (p?.reviewsCount ?? 0) > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.star1, color: TColors.star, size: 14),
                    const SizedBox(width: 4),
                    Text((p!.rating ?? 0).toStringAsFixed(1), style: theme.bodyMedium),
                    const SizedBox(width: 2),
                    Text('(${p.reviewsCount})',
                        style: theme.labelMedium?.apply(color: TColors.darkGrey)),
                  ],
                )
              : Text('—', style: theme.bodyMedium?.copyWith(color: TColors.darkGrey)),
      ]));
    }

    /// -- Eylemler: sepete ekle + karşılaştırmadan kaldır.
    rows.add(_Row(TTexts.actions.tr, [
      for (var i = 0; i < items.length; i++)
        _Actions(item: items[i], product: products[i]),
    ]));

    return rows;
  }

  /// Metin satırı ekler; **dört üründe de boşsa satırı hiç eklemez**.
  void _textRow(List<_Row> rows, BuildContext context, String label, List<String> values) {
    if (!values.any((v) => v.trim().isNotEmpty)) return;

    final style = Theme.of(context).textTheme.bodyMedium;
    rows.add(_Row(label, [
      for (final value in values)
        Text(
          value.trim().isEmpty ? '—' : value,
          textAlign: TextAlign.center,
          style: value.trim().isEmpty ? style?.copyWith(color: TColors.darkGrey) : style,
        ),
    ]));
  }

  /// Küçük hap rozet (ürün kaydı gelmemiş satırlar için).
  Widget _pill(BuildContext context, {required String text, required Color color, required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Okunabilirlik için hafif zebra; tek satırlar saydam.
  Color _zebra(int i, bool dark) =>
      i.isOdd ? (dark ? TColors.darkContainer : TColors.lightGrey) : Colors.transparent;

  /// Birim ekli ölçü; null ya da 0 ise boş döner (satır kuralına girsin).
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

/// Bir tablo satırı: etiket + ürün başına bir hücre.
class _Row {
  const _Row(this.label, this.cells);

  final String label;
  final List<Widget> cells;
}

/// Bir ürün sütununun eylemleri: sepete ekle · karşılaştırmadan kaldır.
///
/// Stok kuralı [TProductStock] üzerinden okunur; ürün kaydı henüz gelmemişse
/// "sepete ekle" kapalıdır (neyi ekleyeceğini bilmiyoruz).
class _Actions extends StatelessWidget {
  const _Actions({required this.item, required this.product});

  final CompareItemModel item;
  final ProductModel? product;

  @override
  Widget build(BuildContext context) {
    final controller = CompareController.instance;
    final orderable = product != null && TProductStock.resolve(product!).canOrder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 32,
          child: OutlinedButton(
            onPressed: orderable
                ? () {
                    final cart = CartController.instance;
                    cart.addOneToCart(cart.convertToCartItem(product!, 1));
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
        const SizedBox(height: TSizes.xs),
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
}
