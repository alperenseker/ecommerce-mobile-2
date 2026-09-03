/// Sipariş istatistikleri özeti.
class OrderStatsModel {
  final String id;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double paidRevenue;
  final double averageOrderValue;

  OrderStatsModel({
    required this.id,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.processingOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.totalRevenue = 0.0,
    this.paidRevenue = 0.0,
    this.averageOrderValue = 0.0,
  });

  factory OrderStatsModel.fromJson(String id, Map<String, dynamic> json) {
    return OrderStatsModel(
      id: id,
      totalOrders: json['totalOrders'] ?? json['TotalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? json['PendingOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? json['ProcessingOrders'] ?? 0,
      shippedOrders: json['shippedOrders'] ?? json['ShippedOrders'] ?? 0,
      deliveredOrders: json['deliveredOrders'] ?? json['DeliveredOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? json['CancelledOrders'] ?? 0,
      totalRevenue: _parseDouble(json['totalRevenue'] ?? json['TotalRevenue']),
      paidRevenue: _parseDouble(json['paidRevenue'] ?? json['PaidRevenue']),
      averageOrderValue: _parseDouble(json['averageOrderValue'] ?? json['AverageOrderValue']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'processingOrders': processingOrders,
        'shippedOrders': shippedOrders,
        'deliveredOrders': deliveredOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'paidRevenue': paidRevenue,
        'averageOrderValue': averageOrderValue,
      };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
