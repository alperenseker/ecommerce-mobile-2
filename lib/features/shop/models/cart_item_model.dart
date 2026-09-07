/// Sepetteki tek kalem.
library;

import 'dart:convert';

class CartItemModel {
  String productId;
  String title;
  double price;
  double salePrice;
  String? image;
  int quantity;
  String variationId;
  String retailerId;
  String? brandName;
  Map<String, String>? selectedVariation;
  String? cartItemId; // Backend cart item ID (sync için)

  /// FAZ 26 — kalemin şirketi (`products.erpsource`, ör. `fores` / `foral`).
  ///
  /// Sepet uçları bu alanı ayrı bir kolonda DÖNDÜRMÜYOR; kaynağı
  /// `ProductSnapshot.erpSource` (backend M1'den beri yazıyor). Çözülemezse
  /// boş kalır ve kalem sepette "Diğer" başlığı altında toplanır — siparişin
  /// bölünmesini yine sunucu yapar, bu alan yalnız GÖSTERİM içindir.
  String erpSource;

  /// Constructor
  CartItemModel({
    required this.productId,
    required this.quantity,
    this.variationId = '',
    this.retailerId = '',
    this.image,
    this.price = 0.0,
    this.salePrice = 0.0,
    this.title = '',
    this.brandName,
    this.selectedVariation,
    this.cartItemId,
    this.erpSource = '',
  });

  /// Kalemin birim fiyatı — **daima `price`**.
  ///
  /// 🔴 FAZ 05'te ortaya çıkan fiyat semantiği: sunucuda `Price` GÜNCEL,
  /// `OldPrice` indirimden ÖNCEKİ fiyattır ve `ProductModel` `OldPrice`ı
  /// `salePrice` alanına ayrıştırıyor (alan adı referanstan geliyor,
  /// değiştirilmedi). Eski kod "salePrice varsa indirimli fiyat odur" diyordu;
  /// indirimli bir üründe müşteriye **eski, yüksek** fiyatı ödetirdi.
  /// Sunucu sepeti zaten `UnitPrice`ı `price`e yazıyor, `salePrice`ı 0
  /// bırakıyor — yani tek doğru kaynak `price`.
  double get unitPrice => price;

  /// Satır tutarı.
  double get totalAmount => unitPrice * quantity;

  /// İndirim gösterimi için eski alanlar. `salePrice` bugün "indirimden önceki
  /// fiyat" anlamında ve canlıda 433/433 üründe 0; tutar hesabında
  /// KULLANILMAZ (bkz. [unitPrice]).
  double get discount => ((salePrice - price) * quantity);

  double get totalAmountWithoutSale => (salePrice > 0 ? salePrice : price) * quantity;

  double get salePercentage => salePrice > price && salePrice > 0 ? (100 - ((price / salePrice) * 100)) : 0;

  /// Empty Cart
  static CartItemModel empty() => CartItemModel(productId: '', quantity: 0);

  /// Convert a CartItem to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'salePrice': salePrice,
      'image': image,
      'quantity': quantity,
      'variationId': variationId,
      'retailerId': retailerId,
      'brandName': brandName,
      'selectedVariation': selectedVariation,
      'cartItemId': cartItemId,
      'erpSource': erpSource,
    };
  }

  /// Create a CartItemModel from a backend order item (has ProductSnapshot field).
  /// Supports PascalCase (ASP.NET default), camelCase, and lowercase keys.
  factory CartItemModel.fromOrderItem(Map<String, dynamic> json) {
    // Snapshot is stored as a JSON string — try all casing variants of the key.
    Map<String, dynamic> snapshot = {};
    final raw = json['ProductSnapshot'] ?? json['productSnapshot'] ?? json['productsnapshot'] ?? '{}';
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) snapshot = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final unitPrice = ((json['UnitPrice'] ?? json['unitPrice'] ?? json['unitprice'] ?? 0) as num).toDouble();

    return CartItemModel(
      productId: json['ProductId']?.toString() ?? json['productId']?.toString() ?? json['productid']?.toString() ?? snapshot['productId']?.toString() ?? '',
      title: snapshot['title']?.toString() ?? snapshot['name']?.toString() ?? snapshot['productName']?.toString() ?? '',
      price: (snapshot['price'] as num?)?.toDouble() ?? unitPrice,
      salePrice: (snapshot['salePrice'] as num?)?.toDouble() ?? unitPrice,
      // Backend snapshot uses 'mainImage'; fallback to 'image' / 'thumbnail'.
      image: snapshot['mainImage']?.toString() ?? snapshot['image']?.toString() ?? snapshot['thumbnail']?.toString(),
      quantity: (json['Quantity'] ?? json['quantity'] ?? 1) as int,
      brandName: snapshot['brandName']?.toString(),
      cartItemId: json['OrderItemId']?.toString() ?? json['orderItemId']?.toString() ?? json['orderitemid']?.toString(),
      // Kalemin şirketi snapshot'ta taşınıyor (FAZ 26). Eski snapshot'larda yok
      // olabilir — o zaman boş kalır, ekran "Diğer" başlığı gösterir.
      erpSource: snapshot['erpSource']?.toString() ?? snapshot['ErpSource']?.toString() ?? '',
    );
  }

  /// Create a CartItemModel from a JSON Map
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json.containsKey('productId') ? json['productId'] ?? '' : '',
      title: json.containsKey('title') ? json['title'] ?? '' : '',
      price: json.containsKey('price') ? json['price']?.toDouble() : 0.0,
      salePrice: json.containsKey('salePrice') ? json['salePrice']?.toDouble() : 0.0,
      image: json.containsKey('image') ? json['image'] ?? '' : '',
      quantity: json.containsKey('quantity') ? json['quantity'] : 1,
      variationId: json.containsKey('variationId') ? json['variationId'] ?? '' : '',
      retailerId: json.containsKey('retailerId') ? json['retailerId'] ?? '' : '',
      brandName: json.containsKey('brandName') ? json['brandName'] ?? '' : '',
      selectedVariation: json.containsKey('selectedVariation')
          ? Map<String, String>.from(json['selectedVariation'] ?? {})
          : {},
      cartItemId: json.containsKey('cartItemId') ? json['cartItemId'] : null,
      // Eski cihazlarda kaydedilmiş sepette bu anahtar YOKTUR; boş kalması
      // normaldir ve ilk backend senkronunda dolar.
      erpSource: json['erpSource']?.toString() ?? '',
    );
  }
}
