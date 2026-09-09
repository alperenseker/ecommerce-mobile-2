/// `/products/{id}/variants` ucunun modelleri.
///
/// 🔴 Uç **dizi değil NESNE** döndürür: `{ ParentProductId, CurrentProductId,
/// TotalVariants, HasVariants, Variants[], DesignOptions[], ColorOptions[],
/// DesignColorMap }`. Web'de varyantların hiç görünmemesinin sebebi buydu.
///
/// Sunucu varyantları bir "Design" (kullanıcıya **Model**) ve bir "Color"
/// (**Renk**) üzerinden gruplar. Model + Renk seçimi somut bir varyant ürüne
/// (kendi `ProductId`'si olan) çözülür ve uygulama onu tam ürün olarak yükler.
///
/// ⚠️ `SelectedDesign` / `SelectedColor` **her yanıtta gelmez**; okurken
/// yokluğa dayanıklı ol.
///
/// 🔴 UÇ TEK DEĞİL, **ÜÇ AYRI BİÇİM** gönderiyor (canlıdan doğrulandı):
///   * `DesignOptions[]` -> `{ Type, Value, ProductIds[], IsAvailable }`
///   * `ColorOptions[]`  -> `{ Type, Value, ProductIds[], IsAvailable }`
///   * `DesignColorMap[model][]` -> `{ Color, ProductId, IsAvailable }`
/// Yani üst seviyedeki seçenekler `Value` + **çoğul** `ProductIds` taşıyor,
/// eşlemedekiler `Color` + **tekil** `ProductId`. Yalnız `Color`/`ProductId`
/// okuyan bir ayrıştırıcı bütün renkleri tek boş seçeneğe çökertir — web'de
/// varyantların hiç görünmemesinin sebebi tam olarak buydu. İki biçim de
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

  /// Çizilecek anlamlı bir şey var mı (birden fazla model YA DA birden fazla
  /// renk). Tek üyeli grupta seçilecek bir şey yoktur.
  bool get isSelectable =>
      hasVariants && (designOptions.length > 1 || colorOptions.length > 1);

  /// Ekranda kullanılabilir hâle getirilmiş kopya.
  ///
  /// Web `ui/variants.js` -> `V.load()` ile aynı iki kural:
  ///   1. Tek üye varsa (varyant <= 1, model <= 1, renk <= 1) seçici hiç
  ///      çizilmez -> [ProductVariantsModel.empty].
  ///   2. TEK MODELLİ (ya da modelsiz) gruplarda renk listesi `Variants`ten
  ///      YENİDEN KURULUR. Sunucu `ColorOptions`ı RENK ADINA göre grupluyor:
  ///      iki ayrı ürün aynı '7016' kodunu taşıyorsa TEK seçenek döner ve
  ///      içinde iki `ProductId` olur — o seçeneğe dokunan kullanıcıyı hangi
  ///      ürüne götüreceğimiz belirsiz kalır. Üyelerin rengi hiç yoksa (elle
  ///      kurulan gruplar) hepsi tek BOŞ seçeneğe çöker. İki durumda da her
  ///      üye kendi seçeneğini alır.
  ///      Çok modelli grupta renkler zaten `DesignColorMap`ten okunuyor
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

    // Her üye kendi seçeneğini alsın. Etiket renk kodu; renk yoksa boş kalır
    // ve seçici liste kipine düşer (bkz. [colorsDistinguishVariants]).
    return variants
        .map((v) => VariantColorOption(
              color: _cleanColor(v.color),
              // Stok kuralı ürün kartındakiyle aynı: miktar > 0 VE
              // `StockStatus != 'out_of_stock'`.
              isAvailable: v.stockAmount > 0 && v.stockStatus != 'out_of_stock',
              productIds: [v.productId],
            ))
        .toList();
  }

  /// Renk yuvarlakları varyantları birbirinden AYIRABİLİYOR mu.
  ///
  /// Ayıramıyorsa (renk boş ya da iki ürün aynı kodu taşıyor) yuvarlak
  /// göstermek yanıltıcı olur: kullanıcı iki ayrı ürünü tek düğme olarak
  /// görür. O durumda seçici resim + isim + fiyat satırlarına düşer.
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

  /// Bu modele ait varyant ürün kimlikleri (`ProductIds`). Sunucu burada
  /// **çoğul** gönderiyor; tekil `ProductId` de kabul edilir.
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
  /// Bu renge ait varyant ürün kimlikleri. Üst seviyedeki `ColorOptions`
  /// **çoğul** (`ProductIds`), `DesignColorMap` içindekiler **tekil**
  /// (`ProductId`) gönderiyor; ikisi de buraya akıyor.
  final List<String> productIds;

  VariantColorOption({
    required this.color,
    required this.isAvailable,
    required this.productIds,
  });

  /// Seçim yapılınca açılacak ürün. Çoğul listede ilk üye kullanılır.
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

/// Sunucu renksiz üyelerde bazen `"undefined"` metnini gönderiyor; boş değer
/// ile aynı şey: renk yok.
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
