import '../../../features/shop/models/banner_model.dart';

/// Afiş repository sözleşmesi.
abstract class BannerRepository {
  Future<List<BannerModel>> fetchAllItems();
  Future<BannerModel> fetchSingleItem(String id);
  Future<String> addItem(BannerModel item);
  Future<void> updateItem(BannerModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(BannerModel item);
  Future<List<BannerModel>> fetchPaginatedItems(int limit);
}
