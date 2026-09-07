/// Sipariş repository'sinin arayüzü.
library;

import '../../../features/shop/models/order_group_model.dart';
import '../../../features/shop/models/order_model.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

abstract class OrderRepository {
  Future<PaginatedOrderResponse> fetchAllOrders({
    int page,
    int pageSize,
    String? status,
    String? paymentStatus,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<OrderStatistics> fetchStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<OrderModel>> fetchUserOrders({required String userId});

  /// FAZ 26 — kullanıcının alışverişleri (sipariş grupları).
  Future<List<OrderGroupModel>> fetchUserOrderGroups({required String userId});

  Future<OrderModel> fetchSingleOrder({required String orderId});

  /// FAZ 26 — bir checkout artık bir grup + şirket başına bir sipariş doğurur.
  Future<CreateOrderResultModel> createOrder({
    required String userId,
    required String shippingAddressId,
    required String billingAddressId,
    required String paymentMethod,
    String? customerNote,
    String? couponCode,
    bool canOrderWithoutStock = false,
  });

  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  });

  Future<OrderModel> updateOrderStatusOnly({
    required String orderId,
    required String orderStatus,
  });

  Future<OrderModel> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
  });

  Future<OrderModel> updateTrackingInfo({
    required String orderId,
    required String shippingCompany,
    required String trackingNumber,
  });

  Future<void> deleteOrder({required String orderId});

  Future<List<OrderModel>> searchOrders(String query);
  Future<List<OrderModel>> fetchOrdersByStatus(String status);

  Future<List<OrderModel>> fetchOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> addOrderActivity({
    required String orderId,
    required String note,
    String? changedBy,
  });

  Future<List<OrderStatusHistory>> fetchOrderHistory({required String orderId});

  Future<OrderModel> updateOrderStatusWithUser({
    required String orderId,
    required String newStatus,
    required String changedByUserId,
    String? note,
  });

  Future<List<OrderStatusHistoryDetailed>> fetchOrderHistoryDetailed({required String orderId});

  Future<OrderModel> updateOrderFull({
    required String orderId,
    required double subtotal,
    required double totalVat,
    required double shippingCost,
    required double discountAmount,
    required double totalAmount,
    required String updatedByUserId,
    String? customerNote,
    String? adminNote,
    List<UpdateOrderItemRequest>? items,
  });

  Future<OrderModel> freeEditOrder({
    required String orderId,
    required String updatedByUserId,
    String? adminNote,
    double? subtotal,
    double? totalVat,
    double? shippingCost,
    double? discountAmount,
    double? totalAmount,
    bool autoRecalculate,
    List<FreeEditOrderItem>? items,
  });
}

class PaginatedOrderResponse {
  final List<OrderModel> orders;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PaginatedOrderResponse({
    required this.orders,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginatedOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedOrderResponse(
      orders: (json['Orders'] as List?)?.map((o) => OrderModel.fromJson('', o as Map<String, dynamic>)).toList() ?? [],
      currentPage: json['CurrentPage'] ?? 1,
      pageSize: json['PageSize'] ?? 20,
      totalCount: json['TotalCount'] ?? 0,
      totalPages: json['TotalPages'] ?? 0,
      hasPreviousPage: _parseBool(json['HasPreviousPage']),
      hasNextPage: _parseBool(json['HasNextPage']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

class OrderStatistics {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double paidRevenue;
  final double averageOrderValue;

  OrderStatistics({
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.paidRevenue,
    required this.averageOrderValue,
  });

  factory OrderStatistics.fromJson(Map<String, dynamic> json) {
    return OrderStatistics(
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      shippedOrders: json['shippedOrders'] ?? 0,
      deliveredOrders: json['deliveredOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      totalRevenue: _parseDouble(json['totalRevenue']),
      paidRevenue: _parseDouble(json['paidRevenue']),
      averageOrderValue: _parseDouble(json['averageOrderValue']),
    );
  }
}

class OrderStatusHistory {
  final String historyId;
  final String orderId;
  final String? oldStatus;
  final String newStatus;
  final String? changedBy;
  final String? note;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.historyId,
    required this.orderId,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      historyId: json['historyId'] ?? json['historyid'] ?? '',
      orderId: json['orderId'] ?? json['orderid'] ?? '',
      oldStatus: json['oldStatus'] ?? json['oldstatus'],
      newStatus: json['newStatus'] ?? json['newstatus'] ?? '',
      changedBy: json['changedBy'] ?? json['changedby'],
      note: json['note'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class OrderStatusHistoryDetailed {
  final String historyId;
  final String orderId;
  final String? oldStatus;
  final String newStatus;
  final String? changedBy;
  final String? note;
  final DateTime createdAt;
  final UserBasicInfo? changedByUser;

  OrderStatusHistoryDetailed({
    required this.historyId,
    required this.orderId,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    this.note,
    required this.createdAt,
    this.changedByUser,
  });

  factory OrderStatusHistoryDetailed.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryDetailed(
      historyId: json['historyId'] ?? json['HistoryId'] ?? '',
      orderId: json['orderId'] ?? json['OrderId'] ?? '',
      oldStatus: json['oldStatus'] ?? json['OldStatus'],
      newStatus: json['newStatus'] ?? json['NewStatus'] ?? '',
      changedBy: json['changedBy'] ?? json['ChangedBy'],
      note: json['note'] ?? json['Note'],
      createdAt: json['createdAt'] != null || json['CreatedAt'] != null
          ? DateTime.parse(json['createdAt'] ?? json['CreatedAt'])
          : DateTime.now(),
      changedByUser: json['changedByUser'] != null || json['ChangedByUser'] != null
          ? UserBasicInfo.fromJson(json['changedByUser'] ?? json['ChangedByUser'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'historyId': historyId,
        'orderId': orderId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'changedByUser': changedByUser?.toJson(),
      };
}

class UserBasicInfo {
  final String userId;
  final String name;
  final String surname;
  final String email;

  UserBasicInfo({
    required this.userId,
    required this.name,
    required this.surname,
    required this.email,
  });

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      userId: json['userId'] ?? json['UserId'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
      surname: json['surname'] ?? json['Surname'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'surname': surname,
        'email': email,
      };

  String get fullName => '$name $surname';
}

class UpdateOrderItemRequest {
  final String productId;
  final String productSnapshot;
  final int quantity;
  final double unitPrice;
  final String vatRate;
  final double totalPrice;
  final double totalVat;

  UpdateOrderItemRequest({
    required this.productId,
    required this.productSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.totalPrice,
    required this.totalVat,
  });

  factory UpdateOrderItemRequest.fromJson(Map<String, dynamic> json) {
    return UpdateOrderItemRequest(
      productId: json['productId'] ?? json['ProductId'] ?? '',
      productSnapshot: json['productSnapshot'] ?? json['ProductSnapshot'] ?? '{}',
      quantity: json['quantity'] ?? json['Quantity'] ?? 0,
      unitPrice: _parseDouble(json['unitPrice'] ?? json['UnitPrice']),
      vatRate: json['vatRate'] ?? json['VatRate'] ?? '16',
      totalPrice: _parseDouble(json['totalPrice'] ?? json['TotalPrice']),
      totalVat: _parseDouble(json['totalVat'] ?? json['TotalVat']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productSnapshot': productSnapshot,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'vatRate': vatRate,
        'totalPrice': totalPrice,
        'totalVat': totalVat,
      };
}

class FreeEditOrderItem {
  final String? productId;
  final String? erpProductId;
  final String productSnapshot;
  final int quantity;
  final double unitPrice;
  final String vatRate;
  final double totalPrice;
  final double totalVat;

  FreeEditOrderItem({
    this.productId,
    this.erpProductId,
    required this.productSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.totalPrice,
    required this.totalVat,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId ?? '',
        'erpProductId': erpProductId,
        'productSnapshot': productSnapshot,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'vatRate': vatRate,
        'totalPrice': totalPrice,
        'totalVat': totalVat,
      };
}
