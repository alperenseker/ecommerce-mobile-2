import 'package:t_utils/t_utils.dart';
import 'category_model.dart';

/// Marka modeli.
class BrandModel {
  String id;
  String name;
  String imageURL;
  bool isFeatured;
  bool isActive;
  int? productsCount;
  int? viewCount;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<CategoryModel>? categories;

  BrandModel({
    required this.id,
    required this.imageURL,
    required this.name,
    this.isFeatured = false,
    this.isActive = true,
    this.productsCount,
    this.viewCount = 0,
    this.categories,
    this.createdAt,
    this.updatedAt,
  });

  /// Empty Helper Function
  static BrandModel empty() => BrandModel(id: '', imageURL: '', name: '');

  String get formattedDate => TFormatter.formatDateAndTime(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDateAndTime(updatedAt);

  /// Convert model to Json structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageURL': imageURL,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'productsCount': productsCount ?? 0,
      'viewCount': viewCount ?? 0,
      'categories': categories?.map((category) => category.toJson()).toList() ?? [], // Ensure it's an empty list if null
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  /// Map JSON data from the REST API to BrandModel
  factory BrandModel.fromJson(String id, Map<String, dynamic> data) {
    if (data.isEmpty) return BrandModel.empty();
    return BrandModel(
      id: id,
      name: data['name'] ?? '',
      imageURL: data['imageURL'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      isActive: data.containsKey('isActive') ? data['isActive'] ?? true : true,
      productsCount: int.parse((data['productsCount'] ?? 0).toString()),
      viewCount: int.parse((data['viewCount'] ?? 0).toString()),
      categories: data.containsKey('categories') ? (data['categories'] as List).map((item) => CategoryModel.fromJson(item['id'], item)).toList() : [],
      createdAt: data.containsKey('createdAt') && data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      updatedAt: data.containsKey('updatedAt') && data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
    );
  }
}
