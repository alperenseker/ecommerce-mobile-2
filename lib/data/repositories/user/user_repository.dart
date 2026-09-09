import '../../../features/personalization/models/user_model.dart';
import '../../../features/shop/models/order_model.dart';

/// Kullanıcı repository sözleşmesi.
abstract class UserRepository {
  Future<List<UserModel>> fetchAllItems();
  Future<UserModel> fetchSingleItem(String id);
  Future<String> addItem(UserModel item);
  Future<void> updateItem(UserModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(UserModel item);
  Future<List<UserModel>> fetchPaginatedItems(int limit);
  Future<List<OrderModel>> fetchUserOrders(String userId);
  Future<void> registerAdmin(UserModel user);
  Future<void> updateUserPoints(String userId, int pointsToAdd);
  Future<List<UserModel>> fetchFilteredPaginatedItems({
    required int limit,
    Map<String, dynamic>? isEqualTo,
    Map<String, dynamic>? isNotEqualTo,
    Map<String, Iterable<Object?>?>? arrayContainsAny,
    Map<String, Iterable<Object?>?>? whereIn,
    Map<String, bool>? isNull,
  });
  Future<void> removeUserRecord(String userId);
}
