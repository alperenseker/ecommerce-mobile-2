/// Duruma göre sipariş sayıları.
class OrderStatsByStatusModel {
  final String id;
  final Map<String, int> countByStatus;
  final Map<String, double> revenueByStatus;

  OrderStatsByStatusModel({
    required this.id,
    this.countByStatus = const {},
    this.revenueByStatus = const {},
  });

  factory OrderStatsByStatusModel.fromJson(String id, Map<String, dynamic> json) {
    final countByStatus = <String, int>{};
    final revenueByStatus = <String, double>{};

    if (json['countByStatus'] != null) {
      (json['countByStatus'] as Map<String, dynamic>).forEach((key, value) {
        countByStatus[key] = (value as num).toInt();
      });
    }
    if (json['revenueByStatus'] != null) {
      (json['revenueByStatus'] as Map<String, dynamic>).forEach((key, value) {
        revenueByStatus[key] = (value as num).toDouble();
      });
    }

    return OrderStatsByStatusModel(
      id: id,
      countByStatus: countByStatus,
      revenueByStatus: revenueByStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'countByStatus': countByStatus,
        'revenueByStatus': revenueByStatus,
      };
}
