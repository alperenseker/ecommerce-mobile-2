import '../../../features/shop/models/attribute_model.dart';

/// Öznitelik repository sözleşmesi.
abstract class AttributeRepository {
  Future<List<AttributeModel>> fetchAllItems();
  Future<AttributeModel> fetchSingleItem(String id);
  Future<String> addItem(AttributeModel item);
  Future<void> updateItem(AttributeModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(AttributeModel item);
  Future<List<AttributeModel>> fetchPaginatedItems(int limit);
}
