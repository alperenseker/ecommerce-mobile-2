import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_utils/t_utils.dart';

import '../../../utils/constants/enums.dart';
import 'brand_model.dart';
import 'category_model.dart';
import 'product_attribute_model.dart';
import 'product_review_model.dart';
import 'product_variation_model.dart';

/// Ürün modeli — katalogun temel taşı.
///
/// 🔴 **Fiyat gizleme buradan okunur.** `HasPrice` sunucunun fiyatı çözüp
/// çözemediğini, `PriceHidden` fiyatın bilerek gizlendiğini söyler;
/// [isPriceHidden] ikisinin bileşimidir ve web'deki `isPriceHidden()` ile
/// aynı kuralı uygular. Bu iki alanı atlarsan fiyatsız ürünlerde 0 ₸ görünür.
///
/// 🔴 `erpSource` ürünün hangi 1C şirketine ait olduğunu söyler; sipariş
/// şirket başına bölündüğü için sepet/ödeme akışı bu alana bakar.
///
/// `fromJson` alan adlarının **iki yazımını da** dener (`productId` / `ProductId`).
class ProductModel {
  // Basic Information
  String id;
  String title;
  String lowerTitle;
  String? sku;
  String? description;
  double price;
  double? salePrice; // Sale or discounted price

  /// Sunucu fiyati cozdu mu (`HasPrice`). Yanlissa urun "fiyatsiz"dir.
  bool hasPrice;

  /// Fiyat VARDI ama gizlendi (`PriceHidden`) — misafire fiyat gosterilmiyor
  /// (`settings.hidepricesforguests`). Iki durumda da sunucu `Price: 0`
  /// gonderir, o yuzden "0" basmak yerine bu bayraklara bakilir.
  bool priceHidden;

  /// Fiyat ekranda gosterilmemeli mi. Web'deki `isPriceHidden()` ile ayni
  /// kural — iki taraf ayni davransin diye tek yerde tutuluyor.
  bool get isPriceHidden => priceHidden || !hasPrice;
  String thumbnail; // Main Image
  List<String>? images; // List of image URLs
  ProductType productType; // simple, digital, variable

  // Inventory Information
  int stock; // Number of items in stock
  bool? isOutOfStock; // Whether product is out of stock
  int soldQuantity; // Total quantity sold

  // Brand & Category
  BrandModel? brand; // Associated brand
  List<String>? tags; // Multiple tags
  List<CategoryModel>? categories; // Multiple categories, including parent-child relationships
  List<String>? categoryIds; // Multiple category Ids, for the app product search
  String? categoryId; // Primary category id (used by the Compare feature)
  String? color; // Product colour (RAL code / name), shown in Compare
  String? size; // Product size, shown in Compare

  /// FAZ 26 — ürünün şirketi (`products.erpsource`, ör. `fores` / `foral`).
  /// Sepete eklenen kalemin şirketini backend senkronunu beklemeden bilmek
  /// için taşınıyor; yalnız GÖSTERİM içindir, siparişi sunucu böler.
  String erpSource;

  // Product Unit
  // UnitModel? unit; // Unit of measurement (weight, volume, etc.)

  // Product Attributes
  List<ProductAttributeModel>? attributes; // Product attributes (size, color, etc.)
  List<ProductVariationModel>? variations; // Variations based on attributes

  // Status & Visibility
  bool isRecommended; // Whether product is recommended
  bool isFeatured; // Whether product is featured
  bool isNewArrival; // New arrival flag
  bool isActive; // Product visibility status (active/inactive)
  bool isDraft; // Whether product is still in draft mode
  bool isDeleted; // Soft delete flag

  // Promotion and Pricing
  bool? onSale; // Flag if on sale
  DateTime? saleStartDate; // Sale start date
  DateTime? saleEndDate; // Sale end date

  // Stats
  int? views; // Number of product views
  int? likes; // Number of likes or favorites

  // Ratings
  double? rating; // Average rating
  int? ratingCount; // Number of ratings
  int? reviewsCount; // Number of reviews
  List<ReviewModel>? lastReviews;
  int fiveStarCount;
  int fourStarCount;
  int threeStarCount;
  int twoStarCount;
  int oneStarCount;

  /// FAZ 05 — künye/özellik tablosunda gösterilen iki alan. Sunucu ikisini de
  /// ürün listesinde gönderiyor (`Barcode`, `VatRate`); web `product.js` ->
  /// `specsHtml` de bunları basıyor. `vatRate` sunucudan METİN geliyor ("18").
  String? barcode;
  String? vatRate;

  // Dimensions & Packaging (shown in the product Specifications section)
  double? weight; // Unit weight (kg)
  double? weightNet; // Net package/box weight (kg)
  double? weightGross; // Gross package/box weight (kg)
  double? width; // Width (mm)
  double? height; // Height (mm)
  double? depth; // Depth (mm)
  double? volume; // Volume
  int? unitsPerBox; // Units per box

  // Audit & History
  String? createdBy; // User who created the product
  DateTime? createdAt; // Creation timestamp
  String? updatedBy; // Last updated by user
  DateTime? updatedAt; // Last update timestamp

  ProductModel({
    required this.id,
    required this.title,
    required this.lowerTitle,
    this.description = '',
    this.sku,
    required this.price,
    this.salePrice,
    this.hasPrice = true,
    this.priceHidden = false,
    required this.thumbnail,
    this.images,
    this.productType = ProductType.simple,
    this.stock = 0,
    this.isOutOfStock,
    this.soldQuantity = 0,
    this.brand,
    this.tags,
    this.categories,
    this.categoryIds,
    this.categoryId,
    this.color,
    this.size,
    this.erpSource = '',
    // this.unit,
    this.attributes,
    this.variations,
    this.isRecommended = false,
    this.isFeatured = false,
    this.isNewArrival = false,
    this.isActive = true,
    this.isDraft = false,
    this.isDeleted = false,
    this.onSale,
    this.saleStartDate,
    this.saleEndDate,
    this.views = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.reviewsCount = 0,
    // Initialize new review distribution fields to 0
    this.fiveStarCount = 0,
    this.fourStarCount = 0,
    this.threeStarCount = 0,
    this.twoStarCount = 0,
    this.oneStarCount = 0,
    this.likes = 0,
    this.barcode,
    this.vatRate,
    this.weight,
    this.weightNet,
    this.weightGross,
    this.width,
    this.height,
    this.depth,
    this.volume,
    this.unitsPerBox,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  /// Helper Function
  ///
  /// CHECK IF STOCK EXIST
  bool get isInStock {
    if (productType == ProductType.simple) return stock > 0 ? true : false;

    if (productType == ProductType.variable) {
      if (variations == null || variations!.isEmpty) return false;
      return variations!.any((variation) => variation.stock > 0 ? true : false);
    }

    return false;
  }

  /// Helper Function
  ///
  /// CHECK IF PRODUCT ON SALE
  bool get isOnSale {
    bool productOnSale = false;

    if (productType == ProductType.simple) {
      productOnSale = (salePrice != null && salePrice! > 0) ? true : false;
    } else {
      if (variations == null || variations!.isEmpty) return false;
      productOnSale = variations!.any((variation) => variation.salePrice > 0 ? true : false);
    }

    return productOnSale;
  }

  /// Helper Function
  ///
  /// CHECK STOCK TOTAL
  int get getStockTotal {
    if (productType == ProductType.simple) {
      return stock;
    } else {
      if (variations == null || variations!.isEmpty) return 0;
      return variations!.fold<int>(0, (previousValue, newValue) => previousValue + newValue.stock);
    }
  }

  /// 🔴 FİYAT SEMANTİĞİ (sunucu + web `data/product-model.js`):
  ///   * `Price`    -> **GÜNCEL** fiyat (ödenecek olan)
  ///   * `OldPrice` -> indirimden ÖNCEKİ fiyat; modelde [salePrice] alanına
  ///     ayrıştırılıyor (alan adı referanstan geliyor, değiştirilmedi)
  /// İndirim YALNIZ eski fiyat güncelden büyükse vardır. Alan adına bakıp
  /// "salePrice varsa indirimli fiyat odur" demek fiyatı TERS çevirir:
  /// müşteriye eski fiyatı ödetir ve rozete "-%25" yazdırır.
  ///
  /// Canlıda bugün `OldPrice` her üründe 0 (2026-09-04: 433/433), yani bu
  /// dal hiç çalışmıyor — ama çalıştığı gün doğru çalışsın.

  /// Üstü çizili gösterilecek eski fiyat; indirim yoksa null.
  double? get oldPrice => (salePrice ?? 0) > price && price > 0 ? salePrice : null;

  /// Gerçekten indirim var mı. Fiyatı gizli üründe indirim de gösterilmez —
  /// yüzde rozeti fiyatı dolaylı olarak sızdırırdı.
  bool get hasDiscount => !isPriceHidden && oldPrice != null;

  /// İndirim yüzdesi (tam sayı). İndirim yoksa 0.
  int get discountPercent => hasDiscount ? ((1 - price / oldPrice!) * 100).round() : 0;

  /// Helper Function
  ///
  /// GET PRODUCT PRICE OR PRICE RANGE
  String get getProductPrice {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    // If no variations exist, return the simple price or sale price
    if (productType.name == ProductType.simple.name || variations!.isEmpty) {
      return '₸${(salePrice ?? 0) > 0.0 ? salePrice : price}';
    } else {
      // Calculate the smallest and largest prices among variations
      for (var variation in variations!) {
        // Determine the price to consider (sale price if available, otherwise regular price)
        double priceToConsider = variation.salePrice > 0.0 ? variation.salePrice : variation.price;

        // Update smallest and largest prices
        if (priceToConsider < smallestPrice) {
          smallestPrice = priceToConsider;
        }

        if (priceToConsider > largestPrice) {
          largestPrice = priceToConsider;
        }
      }

      // If smallest and largest prices are the same, return a single price
      if (smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        // Otherwise, return a price range
        return '₸$smallestPrice - ₸$largestPrice';
      }
    }
  }

  /// GET PRODUCT SALE PRICE OR PRICE RANGE
  String get getProductPriceWithoutSalePrice {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    // If no variations exist, return the simple price or sale price
    if (productType.name == ProductType.simple.name || variations!.isEmpty) {
      return '₸$price';
    } else {
      // Calculate the smallest and largest prices among variations
      for (var variation in variations!) {
        // Determine the price to consider (sale price if available, otherwise regular price)
        double priceToConsider = variation.price;

        // Update smallest and largest prices
        if (priceToConsider < smallestPrice) {
          smallestPrice = priceToConsider;
        }

        if (priceToConsider > largestPrice) {
          largestPrice = priceToConsider;
        }
      }

      if (largestPrice == 0) return '';

      // If smallest and largest prices are the same, return a single price
      if (smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        // Otherwise, return a price range
        return '₸$smallestPrice - ₸$largestPrice';
      }
    }
  }

  /// Helper Function
  ///
  /// GET MAX SALE OF SIMPLE OR VARIABLE PRODUCT
  String? get getMaxDiscountPercentage {
    double maxDiscountPercentage = 0.0;

    // If no variations exist, calculate discount for simple product
    if (productType == ProductType.simple || variations!.isEmpty) {
      return getSimpleProductSalePercentage;
    } else {
      // Loop through each variation to find the maximum discount percentage
      for (var variation in variations!) {
        if (variation.salePrice > 0.0 && variation.price > 0.0) {
          double discountPercentage = ((variation.price - variation.salePrice) / variation.price) * 100;

          // Update maxDiscountPercentage if the current variation has a higher discount
          if (discountPercentage > maxDiscountPercentage) {
            maxDiscountPercentage = discountPercentage;
          }
        }
      }

      // Return the highest discount percentage found
      return maxDiscountPercentage > 0.0 ? maxDiscountPercentage.toStringAsFixed(0) : null;
    }
  }

  /// Helper Function
  ///
  /// GET PRODUCT SALE PERCENTAGE OR PRICE RANGE
  String get getSimpleProductSalePercentage {
    if (salePrice == null || salePrice! <= 0.0) return '';
    if (price <= 0) return '';

    double percentage = ((price - salePrice!) / price) * 100;
    return percentage.toStringAsFixed(0);
  }

  /// Helper Function
  ///
  /// GET PRODUCT SOLD QUANTITY
  String get getSoldQuantity {
    return productType.name == ProductType.simple.name
        ? soldQuantity.toString()
        : variations!.fold<int>(0, (previousValue, element) => previousValue + element.soldQuantity).toString();
  }

  /// Calculates and updates the average rating based on previous and new ratings.
  /// Additionally, it updates the star distribution counts.
  void updateAverageRating(double newRating) {
    if (ratingCount == null || ratingCount == 0) {
      // If there are no existing ratings, the new rating becomes the average.
      rating = newRating;
    } else {
      // Calculate the new average using the previous total and the new rating.
      double totalRatingSum = (rating! * ratingCount!);
      rating = (totalRatingSum + newRating) / (ratingCount! + 1);
    }

    // Increment the rating count as a new rating has been added.
    ratingCount = (ratingCount ?? 0) + 1;

    // --- New Logic for Updating Star Distribution ---
    int intRating = newRating.toInt();
    if (intRating >= 5) {
      fiveStarCount++;
    } else if (intRating == 4) {
      fourStarCount++;
    } else if (intRating == 3) {
      threeStarCount++;
    } else if (intRating == 2) {
      twoStarCount++;
    } else if (intRating <= 1) {
      oneStarCount++;
    }
  }

  String get formattedDate => TFormatter.formatDate(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDate(updatedAt);

  // toJson method to convert model to JSON format
  Map<String, dynamic> toJson() => {
    'title': title,
    'lowerTitle': lowerTitle,
    'description': description,
    'sku': sku,
    'price': price,
    'salePrice': salePrice,
    'hasPrice': hasPrice,
    'priceHidden': priceHidden,
    'thumbnail': thumbnail,
    'images': images,
    'productType': productType.name,
    'stock': getStockTotal,
    'isOutOfStock': !isInStock,
    'soldQuantity': soldQuantity,
    'brand': brand?.toJson(),
    'tags': tags,
    'categoryIds': categoryIds,
    'categories': categories?.map((c) => c.toJson()).toList(),
    // 'unit': unit?.toJson(),
    'attributes': attributes?.map((attr) => attr.toJson()).toList(),
    'variations': variations?.map((variation) => variation.toJson()).toList(),
    'isRecommended': isRecommended,
    'isFeatured': isFeatured,
    'isNewArrival': isNewArrival,
    'isActive': isActive,
    'isDraft': isDraft,
    'isDeleted': isDeleted,
    'onSale': isOnSale,
    'saleStartDate': saleStartDate,
    'saleEndDate': saleEndDate,
    'views': views,
    'rating': rating,
    'ratingCount': ratingCount,
    'reviewsCount': reviewsCount,
    'likes': likes,
    'barcode': barcode,
    'vatRate': vatRate,
    // New review distribution fields
    'fiveStarCount': fiveStarCount,
    'fourStarCount': fourStarCount,
    'threeStarCount': threeStarCount,
    'twoStarCount': twoStarCount,
    'oneStarCount': oneStarCount,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': DateTime.now(),
  };

  // fromJson method to create a model instance from JSON
  factory ProductModel.fromJson(String id, Map<String, dynamic> json) {
    // Helper: hem camelCase hem snake_case hem PascalCase key'leri yakala
    T? get<T>(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k] as T?;
      }
      return null;
    }

    // images alanı backend'den JSON string olarak geliyor: "[\"url1\",\"url2\"]"
    List<String> parseImages(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return List<String>.from(raw);
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return List<String>.from(decoded);
        } catch (_) {}
      }
      return [];
    }

    // Sayısal alanlar backend'den bazen number ("0.3"), bazen string ("16") gelebiliyor.
    double? getNum(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        if (v is num) return v.toDouble();
        if (v is String && v.trim().isNotEmpty) {
          return double.tryParse(v.trim().replaceAll(',', '.'));
        }
      }
      return null;
    }

    return ProductModel(
      id: id,
      title: get<String>(['title', 'name', 'Name']) ?? '',
      lowerTitle: get<String>(['lowerTitle']) ??
          (get<String>(['title', 'name', 'Name']) ?? '').toLowerCase(),
      description: get<String>(['description', 'Description']) ?? '',
      sku: get<String>(['sku', 'Sku']),
      price: (get<num>(['price', 'Price']) ?? 0).toDouble(),
      salePrice: (get<num>(['salePrice', 'oldprice', 'OldPrice']))?.toDouble(),
      // Alan gelmezse eski davranis korunur: fiyat var, gizli degil.
      hasPrice: get<bool>(['hasPrice', 'HasPrice']) ?? true,
      priceHidden: get<bool>(['priceHidden', 'PriceHidden']) ?? false,
      thumbnail: get<String>(['thumbnail', 'mainimage', 'mainImage', 'MainImage']) ?? '',
      images: parseImages(get<dynamic>(['images', 'Images'])),
      productType: ProductType.simple, // backend'de variation yok
      stock: get<int>(['stock', 'stockamount', 'StockAmount']) ?? 0,
      isOutOfStock: get<bool>(['isOutOfStock']) ??
          ((get<String>(['stockstatus', 'StockStatus']) ?? '') == 'out_of_stock'),
      categoryId: get<String>(['categoryId', 'CategoryId', 'categoryid']),
      color: get<String>(['color', 'Color']),
      size: get<String>(['size', 'Size']),
      erpSource: get<String>(['erpSource', 'ErpSource', 'erpsource']) ?? '',
      soldQuantity: get<int>(['soldQuantity']) ?? 0,
      isRecommended: get<bool>(['isRecommended']) ?? false,
      isFeatured: get<bool>(['isFeatured', 'isfeatured', 'IsFeatured']) ?? false,
      isNewArrival: get<bool>(['isNewArrival', 'isnewarrival', 'IsNewArrival']) ?? false,
      isActive: get<bool>(['isActive', 'isactive', 'IsActive']) ?? true,
      isDraft: (get<String>(['status', 'Status']) ?? '') == 'draft',
      isDeleted: false,
      onSale: get<bool>(['onSale']),
      views: get<int>(['views', 'Views']) ?? 0,
      rating: (get<num>(['rating', 'averageRating', 'AverageRating']) ?? 0).toDouble(),
      ratingCount: get<int>(['ratingCount', 'totalReviewCount', 'TotalReviewCount']) ?? 0,
      reviewsCount: get<int>(['reviewsCount', 'totalReviewCount', 'TotalReviewCount']) ?? 0,
      fiveStarCount: get<int>(['fiveStarCount']) ?? 0,
      fourStarCount: get<int>(['fourStarCount']) ?? 0,
      threeStarCount: get<int>(['threeStarCount']) ?? 0,
      twoStarCount: get<int>(['twoStarCount']) ?? 0,
      oneStarCount: get<int>(['oneStarCount']) ?? 0,
      likes: get<int>(['likes']) ?? 0,
      barcode: get<String>(['barcode', 'Barcode']),
      vatRate: get<dynamic>(['vatRate', 'VatRate'])?.toString(),
      weight: getNum(['weight', 'Weight']),
      weightNet: getNum(['weightNet', 'WeightNet']),
      weightGross: getNum(['weightGross', 'WeightGross']),
      width: getNum(['width', 'Width']),
      height: getNum(['height', 'Height']),
      depth: getNum(['depth', 'Depth']),
      volume: getNum(['volume', 'Volume']),
      unitsPerBox: getNum(['unitsPerBox', 'UnitsPerBox'])?.toInt(),
      createdBy: get<String>(['createdBy']),
      createdAt: DateTime.tryParse(
          (get<String>(['createdAt', 'createdat', 'CreatedAt']) ?? '')),
      updatedBy: get<String>(['updatedBy']),
      updatedAt: DateTime.tryParse(
          (get<String>(['updatedAt', 'updatedat', 'UpdatedAt']) ?? '')),
    );
  }

  static ProductModel empty() => ProductModel(id: '', title: '', lowerTitle: '', price: 0, thumbnail: '', stock: 0);
}
