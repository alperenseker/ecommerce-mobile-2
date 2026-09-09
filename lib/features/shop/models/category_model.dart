import '../../../utils/formatters/formatter.dart';
import 'brand_model.dart';

/// Kategori modeli.
///
/// `subCategories` özyinelemelidir ve derinlik sabit değildir (canlıda 1–4
/// seviye). Ağaç çizen her yer değişken derinliği desteklemeli.
class CategoryModel {
  String id;
  String name;
  String imageURL;
  String parentId;
  String parentName;
  String slug;
  String description;
  int displayOrder;
  bool isActive;
  bool isFeatured;
  int priority;
  DateTime? createdAt;
  DateTime? updatedAt;
  int numberOfProducts;
  int viewCount;
  String createdBy;
  String updatedBy;
  List<BrandModel>? brands;
  List<CategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageURL,
    required this.isActive,
    this.isFeatured = false,
    this.parentId = '',
    this.parentName = '',
    this.slug = '',
    this.description = '',
    this.displayOrder = 0,
    this.priority = 1,
    this.createdAt,
    this.updatedAt,
    this.numberOfProducts = 0,
    this.viewCount = 0,
    this.brands,
    this.createdBy = '',
    this.updatedBy = '',
    this.subCategories = const [],
  });

  /// Convert model to JSON structure to store in Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageURL': imageURL,
      'parentId': parentId,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'priority': priority,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
      'numberOfProducts': numberOfProducts,
      'viewCount': viewCount,
      'brands': brands?.map((brand) => brand.toJson()).toList() ?? [],
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  String get formattedDate => TFormatter.formatDateAndTime(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDateAndTime(updatedAt);

  /// Map JSON data to the CategoryModel. Tolerant of both the .NET backend's
  /// PascalCase response (Id, Name, Slug, ParentId, SubCategories, ...) and
  /// legacy camelCase fields, so both the live API and older callers work.
  factory CategoryModel.fromJson(String id, Map<String, dynamic> data) {
    dynamic field(String pascal, String camel) => data.containsKey(pascal) ? data[pascal] : data[camel];

    final subCategoriesJson = field('SubCategories', 'subCategories') as List<dynamic>?;

    return CategoryModel(
      id: id.isNotEmpty ? id : (field('Id', 'id')?.toString() ?? ''),
      name: field('Name', 'name') ?? '',
      slug: field('Slug', 'slug') ?? '',
      description: field('Description', 'description') ?? '',
      imageURL: field('ImageURL', 'imageURL') ?? '',
      parentId: field('ParentId', 'parentId')?.toString() ?? '',
      parentName: field('ParentName', 'parentName') ?? '',
      displayOrder: field('DisplayOrder', 'displayOrder') ?? 0,
      isFeatured: field('IsFeatured', 'isFeatured') ?? false,
      isActive: field('IsActive', 'isActive') ?? true,
      priority: field('Priority', 'priority') ?? 2,
      // Default to medium priority
      createdAt: field('CreatedAt', 'createdAt') != null ? DateTime.tryParse(field('CreatedAt', 'createdAt').toString()) : null,
      updatedAt: field('UpdatedAt', 'updatedAt') != null ? DateTime.tryParse(field('UpdatedAt', 'updatedAt').toString()) : null,
      numberOfProducts: field('NumberOfProducts', 'numberOfProducts') ?? 0,
      viewCount: field('ViewCount', 'viewCount') ?? 0,
      brands: data.containsKey('brands') ? (data['brands'] as List).map((item) => BrandModel.fromJson(item['id'], item)).toList() : [],
      createdBy: field('CreatedBy', 'createdBy') ?? '',
      updatedBy: field('UpdatedBy', 'updatedBy') ?? '',
      subCategories: subCategoriesJson == null
          ? const []
          : subCategoriesJson
              .map((sub) => CategoryModel.fromJson((sub as Map<String, dynamic>)['Id']?.toString() ?? '', sub))
              .toList(),
    );
  }

  /// Helper function to return an empty CategoryModel
  static CategoryModel empty() =>
      CategoryModel(id: '', imageURL: '', name: '', isFeatured: false, isActive: false, createdBy: '', updatedBy: '');
}
