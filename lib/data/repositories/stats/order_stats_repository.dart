import '../../../features/shop/models/order_stats_model.dart';
import '../../../features/shop/models/order_stats_by_status_model.dart';

/// Sipariş istatistiği repository sözleşmesi.
abstract class OrderStatsRepository {
  Future<OrderStatsModel> fetchOrderStats();
  Future<OrderStatsByStatusModel> fetchOrderStatsByStatus();
  Future<OrderStatsModel> fetchDailyStats(DateTime date);
}
