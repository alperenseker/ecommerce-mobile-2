import '../../../features/shop/models/product_model.dart';

/// Ürün repository sözleşmesi.
abstract class ProductRepository {
  Future<List<ProductModel>> fetchAllItems();
  Future<ProductModel> fetchSingleItem(String id);
  Future<String> addItem(ProductModel item);
  Future<void> updateItem(ProductModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(ProductModel item);
  Future<List<ProductModel>> fetchPaginatedItems(int limit);
  Future<List<ProductModel>> fetchPaginatedItemsWithPageAndLimit(int page, int limit);
  Future<List<ProductModel>> getAllRetailerProducts(String retailerId);
  Future<List<ProductModel>> searchProducts(String query);
}
