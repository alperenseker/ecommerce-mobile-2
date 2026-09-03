/// Models for the `/products/{id}/variants` endpoint.
///
/// The backend groups a product's variants by a "Design" (shown to the user as
/// **Model**) and a "Color" (shown as **Renk**). Selecting a Model + Color
/// resolves to a concrete variant product (its own `ProductId`), which the app
/// then loads as a full product. Mirrors the web `getProductVariants()` flow.
class ProductVariantsModel {
  final bool hasVariants;
  final List<VariantDesignOption> designOptions;
  final List<VariantColorOption> colorOptions;

  /// design value -> the colors available for that design
  final Map<String, List<VariantColorOption>> designColorMap;
  final String selectedDesign;
  final String selectedColor;
  final List<VariantItem> variants;

  ProductVariantsModel({
    required this.hasVariants,
    required this.designOptions,
    required this.colorOptions,
    required this.designColorMap,
    required this.selectedDesign,
    required this.selectedColor,
    required this.variants,
  });

  static ProductVariantsModel empty() => ProductVariantsModel(
        hasVariants: false,
        designOptions: const [],
        colorOptions: const [],
        designColorMap: const {},
        selectedDesign: '',
        selectedColor: '',
        variants: const [],
      );

  /// Whether there is anything meaningful to render (more than one model OR
  /// more than one color).
  bool get isSelectable =>
      hasVariants && (designOptions.length > 1 || colorOptions.length > 1);

  factory ProductVariantsModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return ProductVariantsModel.empty();

    final designs = _asList(_pick(json, ['DesignOptions', 'designOptions']))
        .map((e) => VariantDesignOption.fromJson(_asMap(e)))
        .toList();

    final colors = _asList(_pick(json, ['ColorOptions', 'colorOptions']))
        .map((e) => VariantColorOption.fromJson(_asMap(e)))
        .toList();

    final rawMap = _asMap(_pick(json, ['DesignColorMap', 'designColorMap']));
    final designColorMap = <String, List<VariantColorOption>>{};
    rawMap.forEach((key, value) {
      designColorMap[key.toString()] = _asList(value)
          .map((e) => VariantColorOption.fromJson(_asMap(e)))
          .toList();
    });

    final variants = _asList(_pick(json, ['Variants', 'variants']))
        .map((e) => VariantItem.fromJson(_asMap(e)))
        .toList();

    return ProductVariantsModel(
      hasVariants: _pick(json, ['HasVariants', 'hasVariants']) == true,
      designOptions: designs,
      colorOptions: colors,
      designColorMap: designColorMap,
      selectedDesign:
          _pick(json, ['SelectedDesign', 'selectedDesign'])?.toString() ?? '',
      selectedColor:
          _pick(json, ['SelectedColor', 'selectedColor'])?.toString() ?? '',
      variants: variants,
    );
  }
}

class VariantDesignOption {
  final String value;
  final bool isAvailable;

  VariantDesignOption({required this.value, required this.isAvailable});

  factory VariantDesignOption.fromJson(Map<String, dynamic> json) =>
      VariantDesignOption(
        value: _pick(json, ['Value', 'value'])?.toString() ?? '',
        isAvailable: _pick(json, ['IsAvailable', 'isAvailable']) != false,
      );
}

class VariantColorOption {
  final String color;
  final bool isAvailable;
  final String productId;

  VariantColorOption({
    required this.color,
    required this.isAvailable,
    required this.productId,
  });

  factory VariantColorOption.fromJson(Map<String, dynamic> json) =>
      VariantColorOption(
        color: _pick(json, ['Color', 'color'])?.toString() ?? '',
        isAvailable: _pick(json, ['IsAvailable', 'isAvailable']) != false,
        productId:
            _pick(json, ['ProductId', 'productId', 'id'])?.toString() ?? '',
      );
}

class VariantItem {
  final String productId;
  final String name;
  final String sku;
  final double price;
  final double? oldPrice;

  /// Sunucu varyant basina da fiyat bayraklarini gonderiyor
  /// (`/api/products/{id}/variants`). Ana urundeki kural ile ayni.
  final bool hasPrice;
  final bool priceHidden;

  bool get isPriceHidden => priceHidden || !hasPrice;

  final int stockAmount;
  final String stockStatus;
  final String slug;
  final String color;
  final String mainImage;

  VariantItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.price,
    required this.oldPrice,
    this.hasPrice = true,
    this.priceHidden = false,
    required this.stockAmount,
    required this.stockStatus,
    required this.slug,
    required this.color,
    required this.mainImage,
  });

  factory VariantItem.fromJson(Map<String, dynamic> json) => VariantItem(
        productId: _pick(json, ['ProductId', 'productId', 'id'])?.toString() ?? '',
        name: _pick(json, ['Name', 'name'])?.toString() ?? '',
        sku: _pick(json, ['Sku', 'sku'])?.toString() ?? '',
        price: _toDouble(_pick(json, ['Price', 'price'])),
        oldPrice: _toDoubleOrNull(_pick(json, ['OldPrice', 'oldPrice'])),
        // Alan gelmezse eski davranis: fiyat var, gizli degil.
        hasPrice: _pick(json, ['HasPrice', 'hasPrice']) as bool? ?? true,
        priceHidden: _pick(json, ['PriceHidden', 'priceHidden']) as bool? ?? false,
        stockAmount:
            _toDouble(_pick(json, ['StockAmount', 'stockAmount', 'stock'])).toInt(),
        stockStatus:
            _pick(json, ['StockStatus', 'stockStatus'])?.toString() ?? '',
        slug: _pick(json, ['Slug', 'slug'])?.toString() ?? '',
        color: _pick(json, ['Color', 'color'])?.toString() ?? '',
        mainImage: _pick(json, ['MainImage', 'mainImage'])?.toString() ?? '',
      );
}

/// ---- shared parsing helpers (tolerant of PascalCase / camelCase) ----

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}
