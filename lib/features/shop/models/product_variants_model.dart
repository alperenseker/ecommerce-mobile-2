/// `/products/{id}/variants` ucunun modelleri.
///
/// Sunucu bir urunun varyantlarini "Design" (ekranda **Model**) ve "Color"
/// (ekranda **Renk**) altinda grupluyor. Model + Renk secimi somut bir varyant
/// URUNUNE (kendi `ProductId`si) cozuluyor; uygulama onu tam urun olarak
/// yukluyor. Web `getProductVariants()` akisiyla ayni.
///
/// 🔴 UC DIZI, UC AYRI BICIM (canlidan dogrulandi, 2026-09-04):
///   * `DesignOptions[]` -> `{ Type, Value, ProductIds[], IsAvailable }`
///   * `ColorOptions[]`  -> `{ Type, Value, ProductIds[], IsAvailable }`
///   * `DesignColorMap[model][]` -> `{ Color, ProductId, IsAvailable }`
/// Yani ust seviyedeki secenekler `Value` + **cogul** `ProductIds` tasiyor,
/// eslemedekiler `Color` + **tekil** `ProductId`. Yalniz `Color`/`ProductId`
/// okuyan bir ayrıştırıcı butun renkleri tek bos secenege cokertir — web'de
/// varyantlarin hic gorunmemesinin sebebi tam olarak buydu. Iki bicim de
/// kabul edilir.
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

  /// Cizilecek anlamli bir sey var mi (birden fazla model YA DA birden fazla
  /// renk). Tek uyeli grupta secilecek bir sey yoktur.
  bool get isSelectable =>
      hasVariants && (designOptions.length > 1 || colorOptions.length > 1);

  /// Ekranda kullanilabilir hale getirilmis kopya.
  ///
  /// Web `ui/variants.js` -> `V.load()` ile ayni iki kural:
  ///   1. Tek uye varsa (varyant <= 1, model <= 1, renk <= 1) secici hic
  ///      cizilmez -> [ProductVariantsModel.empty].
  ///   2. TEK MODELLI (ya da modelsiz) gruplarda renk listesi `Variants`ten
  ///      YENIDEN KURULUR. Sunucu `ColorOptions`i RENK ADINA gore grupluyor:
  ///      iki ayri urun ayni '7016' kodunu tasiyorsa TEK secenek doner ve
  ///      icinde iki `ProductId` olur — o secenege dokunan kullaniciyi hangi
  ///      urune goturecegimiz belirsiz kalir. Uyelerin rengi hic yoksa (elle
  ///      kurulan gruplar) hepsi tek BOS secenege coker. Iki durumda da her
  ///      uye kendi seceneğini alir.
  ///      Cok modelli grupta renkler zaten `DesignColorMap`ten okunuyor
  ///      (orada `ProductId` tekil), dokunulmaz.
  ProductVariantsModel normalized() {
    if (!hasVariants) return ProductVariantsModel.empty();
    if (variants.length <= 1 &&
        designOptions.length <= 1 &&
        colorOptions.length <= 1) {
      return ProductVariantsModel.empty();
    }

    return ProductVariantsModel(
      hasVariants: hasVariants,
      designOptions: designOptions,
      colorOptions: _normalizeColors(),
      designColorMap: designColorMap,
      selectedDesign: selectedDesign,
      selectedColor: _cleanColor(selectedColor),
      variants: variants,
    );
  }

  /// Bkz. [normalized] 2. kural.
  List<VariantColorOption> _normalizeColors() {
    if (variants.length <= 1) return colorOptions;
    if (designOptions.length > 1) return colorOptions;

    // Her uye kendi seceneğini alsin. Etiket renk kodu; renk yoksa bos kalir
    // ve secici liste kipine duser (bkz. [colorsDistinguishVariants]).
    return variants
        .map((v) => VariantColorOption(
              color: _cleanColor(v.color),
              // Stok kurali urun kartindakiyle ayni: miktar > 0 VE
              // `StockStatus != 'out_of_stock'`.
              isAvailable: v.stockAmount > 0 && v.stockStatus != 'out_of_stock',
              productIds: [v.productId],
            ))
        .toList();
  }

  /// Renk yuvarlaklari varyantlari birbirinden AYIRABILIYOR mu.
  ///
  /// Ayiramiyorsa (renk bos ya da iki urun ayni kodu tasiyor) yuvarlak
  /// gostermek yaniltici olur: kullanici iki ayri urunu tek dugme olarak
  /// gorur. O durumda secici resim + isim + fiyat satirlarina duser.
  bool get colorsDistinguishVariants {
    if (variants.length < 2) return false;
    final codes = variants.map((v) => _cleanColor(v.color)).toList();
    if (codes.any((c) => c.isEmpty)) return false;
    return codes.toSet().length == codes.length;
  }

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

  /// Bu modele ait varyant urun kimlikleri (`ProductIds`). Sunucu burada
  /// **cogul** gonderiyor; tekil `ProductId` de kabul edilir.
  final List<String> productIds;

  VariantDesignOption({
    required this.value,
    required this.isAvailable,
    this.productIds = const [],
  });

  String get productId => productIds.isNotEmpty ? productIds.first : '';

  factory VariantDesignOption.fromJson(Map<String, dynamic> json) =>
      VariantDesignOption(
        value: _pick(json, ['Value', 'value', 'Design', 'design', 'Name', 'name'])
                ?.toString() ??
            '',
        isAvailable: _pick(json, ['IsAvailable', 'isAvailable']) != false,
        productIds: _asIdList(json),
      );
}

class VariantColorOption {
  final String color;
  final bool isAvailable;

  /// Bu renge ait varyant urun kimlikleri. Ust seviyedeki `ColorOptions`
  /// **cogul** (`ProductIds`), `DesignColorMap` icindekiler **tekil**
  /// (`ProductId`) gonderiyor; ikisi de buraya akiyor.
  final List<String> productIds;

  VariantColorOption({
    required this.color,
    required this.isAvailable,
    required this.productIds,
  });

  /// Secim yapilinca acilacak urun. Cogul listede ilk uye kullanilir.
  String get productId => productIds.isNotEmpty ? productIds.first : '';

  factory VariantColorOption.fromJson(Map<String, dynamic> json) =>
      VariantColorOption(
        color: _cleanColor(
            _pick(json, ['Value', 'value', 'Color', 'color'])?.toString() ?? ''),
        isAvailable: _pick(json, ['IsAvailable', 'isAvailable']) != false,
        productIds: _asIdList(json),
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

/// `ProductIds` (dizi) ya da `ProductId` (tek) — hangisi gelirse.
List<String> _asIdList(Map<String, dynamic> json) {
  final many = _pick(json, ['ProductIds', 'productIds']);
  if (many is List) {
    return many
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final single = _pick(json, ['ProductId', 'productId', 'id'])?.toString() ?? '';
  return single.isEmpty ? const [] : [single];
}

/// Sunucu renksiz uyelerde bazen `"undefined"` metnini gonderiyor; bos deger
/// ile ayni sey: renk yok.
String _cleanColor(String value) {
  final v = value.trim();
  return (v.isEmpty || v == 'undefined' || v == 'null') ? '' : v;
}

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
