import '../../../features/shop/models/category_model.dart';

/// Kategori repository sözleşmesi.
abstract class CategoryRepository {
  Future<List<CategoryModel>> fetchAllItems();
  Future<CategoryModel> fetchSingleItem(String id);
  Future<String> addItem(CategoryModel item);
  Future<void> updateItem(CategoryModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(CategoryModel item);
  Future<List<CategoryModel>> fetchPaginatedItems(int limit);
  Future<String> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> saveCategoryTree(CategoryModel category);
  Future<List<CategoryModel>> searchProducts(String query);
}
