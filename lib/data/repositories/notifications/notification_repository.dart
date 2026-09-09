import '../../services/notifications/notification_model.dart';

/// Bildirim repository sözleşmesi.
abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchAllItems();
  Future<NotificationModel> fetchSingleItem(String id);
  Future<String> addItem(NotificationModel item);
  Future<void> updateItem(NotificationModel item);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
  Future<void> deleteItem(NotificationModel item);
  Future<List<NotificationModel>> fetchPaginatedItems(int limit);
}
