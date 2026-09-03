/// Ürünün tek bir varyasyonu (öznitelik kombinasyonu + kendi fiyatı/stoğu).
library;

import 'package:get/get_rx/src/rx_types/rx_types.dart';

class ProductVariationModel {
  final String id;
  String sku;
  Rx<String> image;
  String? description;
  double price;
  double salePrice;
  int stock;
  int soldQuantity;
  Map<String, String> attributeValues;

  ProductVariationModel({
    required this.id,
    this.sku = '',
    String image = '',
    this.description = '',
    this.price = 0.0,
    this.salePrice = 0.0,
    this.stock = 0,
    this.soldQuantity = 0,
    required this.attributeValues,
  }) : image = image.obs;

  /// Create an empty instance for clean initialization
  static ProductVariationModel empty() => ProductVariationModel(id: '', attributeValues: {});

  /// Convert object to JSON format with camelCase keys
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'image': image.value,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'soldQuantity': soldQuantity,
      'attributeValues': attributeValues,
    };
  }

  /// Factory method to map JSON data to model
  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return ProductVariationModel.empty();

    return ProductVariationModel(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      price: _safeParseDouble(json['price']),
      salePrice: _safeParseDouble(json['salePrice']),
      stock: json['stock'] ?? 0,
      soldQuantity: json['soldQuantity'] ?? 0,
      attributeValues: Map<String, String>.from(json['attributeValues'] ?? {}),
    );
  }

  /// Helper method to safely parse double values
  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
