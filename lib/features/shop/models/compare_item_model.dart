/// A single product inside a user's comparison list (from /compare/user/{userId}).
/// Mirrors the fields the website's compare table reads off each item.
class CompareItemModel {
  final String comparisonItemId;
  final String productId;
  final String productName;
  final String mainImage;
  final String slug;
  final double price;
  final double? oldPrice;

  /// Sunucu artik karsilastirma kaleminde de fiyat bayraklarini gonderiyor
  /// (CompareController fiyat cozumleyiciden geciyor). Ana urundeki kural.
  final bool hasPrice;
  final bool priceHidden;

  bool get isPriceHidden => priceHidden || !hasPrice;

  final int stockAmount;
  final String description;
  final String categoryName;
  final String? categoryId;
  final String color;
  final String size;
  final double? weight;
  final double? width;
  final double? height;
  final double? depth;
  final bool isActive;

  CompareItemModel({
    required this.comparisonItemId,
    required this.productId,
    required this.productName,
    required this.mainImage,
    required this.slug,
    required this.price,
    this.oldPrice,
    this.hasPrice = true,
    this.priceHidden = false,
    required this.stockAmount,
    required this.description,
    required this.categoryName,
    this.categoryId,
    required this.color,
    required this.size,
    this.weight,
    this.width,
    this.height,
    this.depth,
    required this.isActive,
  });

  factory CompareItemModel.fromJson(Map<String, dynamic> json) {
    // Backend mixes camelCase / PascalCase keys.
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k] as T?;
      }
      return null;
    }

    String str(List<String> keys) => pick<dynamic>(keys)?.toString() ?? '';

    // Numeric values can arrive as number or string ("0.3").
    double? num$(List<String> keys) {
      final v = pick<dynamic>(keys);
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String && v.trim().isNotEmpty) {
        return double.tryParse(v.trim().replaceAll(',', '.'));
      }
      return null;
    }

    return CompareItemModel(
      comparisonItemId: str(['comparisonItemId', 'ComparisonItemId']),
      productId: str(['productId', 'ProductId']),
      productName: str(['productName', 'ProductName', 'name', 'Name']),
      mainImage: str(['mainImage', 'MainImage', 'thumbnail', 'Thumbnail']),
      slug: str(['slug', 'Slug']),
      price: num$(['price', 'Price']) ?? 0,
      oldPrice: num$(['oldPrice', 'OldPrice', 'salePrice', 'SalePrice']),
      // Alan gelmezse eski davranis: fiyat var, gizli degil.
      hasPrice: (json['hasPrice'] ?? json['HasPrice']) as bool? ?? true,
      priceHidden: (json['priceHidden'] ?? json['PriceHidden']) as bool? ?? false,
      stockAmount: (num$(['stockAmount', 'StockAmount']) ?? 0).toInt(),
      description: str(['description', 'Description']),
      categoryName: str(['categoryName', 'CategoryName']),
      categoryId: pick<dynamic>(['categoryId', 'CategoryId'])?.toString(),
      color: str(['color', 'Color']),
      size: str(['size', 'Size']),
      weight: num$(['weight', 'Weight']),
      width: num$(['width', 'Width']),
      height: num$(['height', 'Height']),
      depth: num$(['depth', 'Depth']),
      isActive: pick<bool>(['isActive', 'IsActive']) ?? true,
    );
  }
}
