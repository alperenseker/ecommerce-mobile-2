import '../../../utils/constants/enums.dart';

/// Kargo bilgisi (taşıyıcı, takip numarası, durum, tahmini teslim).
class ShippingInfo {
  final String carrier; // Shipping carrier (e.g., 'DHL', 'FedEx')
  final String trackingNumber; // Tracking number provided by the carrier
  final ShippingStatus shippingStatus; // Enum: Status of shipping
  final ShippingMethod shippingMethod; // Enum: Shipping method
  final DateTime? estimatedDelivery; // Estimated delivery date
  final DateTime? deliveredAt; // When the order was delivered

  ShippingInfo({
    required this.carrier,
    required this.trackingNumber,
    required this.shippingStatus,
    required this.shippingMethod,
    this.estimatedDelivery,
    this.deliveredAt,
  });

  // Convert ShippingInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'carrier': carrier,
      'trackingNumber': trackingNumber,
      'shippingStatus': shippingStatus.name,
      'shippingMethod': shippingMethod.name,
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  /// Retrieve ShippingInfo from JSON
  static ShippingInfo fromJson(Map<String, dynamic> data) {
    return ShippingInfo(
      carrier: data.containsKey('carrier') ? data['carrier']  ?? '' : '',
      trackingNumber: data.containsKey('trackingNumber') ? data['trackingNumber']  ?? '' : '',
      shippingStatus: data.containsKey('shippingStatus')
          ? ShippingStatus.values.firstWhere((e) => e.name == data['shippingStatus'], orElse: () => ShippingStatus.pending)
          : ShippingStatus.pending,
      shippingMethod: data.containsKey('shippingMethod')
          ? ShippingMethod.values.firstWhere((e) => e.name == data['shippingMethod'], orElse: () => ShippingMethod.standard)
          : ShippingMethod.standard,
      estimatedDelivery:
      data.containsKey('estimatedDelivery') && data['estimatedDelivery'] != null ? DateTime.tryParse(data['estimatedDelivery']) : null,
      deliveredAt: data.containsKey('deliveredAt') && data['deliveredAt'] != null ? DateTime.tryParse(data['deliveredAt']) : null,
    );
  }

  // Check if ShippingInfo is empty
  bool isEmpty() {
    return carrier.isEmpty && trackingNumber.isEmpty;
  }

  static ShippingInfo empty() =>
      ShippingInfo(carrier: '', trackingNumber: '', shippingStatus: ShippingStatus.pending, shippingMethod: ShippingMethod.express);
}
