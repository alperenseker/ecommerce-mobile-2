import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../features/shop/models/order_stats_model.dart';
import '../../../features/shop/models/order_stats_by_status_model.dart';
import 'order_stats_repository.dart';

/// Sipariş istatistiği uçları (`order-stats`).
class ApiOrderStatsRepository extends TApiRepositoryController<OrderStatsModel>
    implements OrderStatsRepository {

  static ApiOrderStatsRepository get instance => Get.find();

  ApiOrderStatsRepository() : super(
    fromJson: (json) => OrderStatsModel.fromJson(json['id'] ?? 'stats', json),
    toJson: (stats) => stats.toJson(),
    getId: (stats) => stats.id,
  );

  @override
  String getEndpoint() => 'order-stats';

  // ==================== READ OPERATIONS ====================

  /// Get overall order statistics
  @override
  Future<OrderStatsModel> fetchOrderStats() async {
    try {
      final response = await dio.get(getEndpoint());

      if (response.data['success'] == true) {
        return OrderStatsModel.fromJson(
          response.data['data']['id'] ?? 'stats',
          response.data['data'],
        );
      } else {
        throw response.data['message'] ?? 'Failed to fetch order stats';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Get order statistics by status
  @override
  Future<OrderStatsByStatusModel> fetchOrderStatsByStatus() async {
    try {
      final response = await dio.get('${getEndpoint()}/by-status');

      if (response.data['success'] == true) {
        return OrderStatsByStatusModel.fromJson(
          response.data['data']['id'] ?? 'stats-by-status',
          response.data['data'],
        );
      } else {
        throw response.data['message'] ?? 'Failed to fetch order stats by status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<OrderStatsModel> fetchDailyStats(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await dio.get('${getEndpoint()}/daily/$dateStr');

      if (response.data['success'] == true) {
        return OrderStatsModel.fromJson(
          response.data['data']['id'] ?? 'daily_stats',
          response.data['data'],
        );
      } else {
        throw response.data['message'] ?? 'Failed to fetch daily stats';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ==================== UNSUPPORTED CRUD OPERATIONS ====================

  @override
  Future<String> addItem(OrderStatsModel item) async {
    throw UnsupportedError('Stats are calculated dynamically from orders');
  }

  @override
  Future<List<OrderStatsModel>> fetchAllItems() async {
    final stats = await fetchOrderStats();
    return [stats];
  }

  @override
  Future<OrderStatsModel> fetchSingleItem(String id) async {
    return await fetchOrderStats();
  }

  @override
  Future<void> updateItem(OrderStatsModel item) async {
    throw UnsupportedError('Stats are calculated dynamically from orders');
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    throw UnsupportedError('Stats are calculated dynamically from orders');
  }

  @override
  Future<void> deleteItem(OrderStatsModel item) async {
    throw UnsupportedError('Stats are calculated dynamically from orders');
  }
}
