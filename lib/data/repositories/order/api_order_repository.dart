import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/order_group_model.dart';
import '../../../features/shop/models/order_model.dart';
import 'order_repository.dart';

/// Sipariş uçları (`order`).
///
/// 🔴 **Bir ödeme = bir GRUP + şirket başına bir sipariş.** Sepette iki şirketin
/// (1C kaynağının) ürünü varsa sunucu siparişi böler, ikisi de aynı `GroupId`
/// altında toplanır ve tek çekimle ödenir. Müşterinin "siparişim" dediği bütün
/// gruptur, tek satır değil.
///
/// Ana yol `order/groups/user/{id}`; o uç yoksa ya da erişilemezse düz
/// `order/user/{id}` listesinden **istemcide** grup kurulur (her satır
/// `GroupId`/`GroupNumber` taşıyor), böylece ekran her koşulda dolar.
class ApiOrderRepository extends TApiRepositoryController<OrderModel>
    implements OrderRepository {

  static ApiOrderRepository get instance => Get.find();

  ApiOrderRepository() : super(
    fromJson: (json) => OrderModel.fromJson('', json),
    toJson: (order) => order.toJson(),
    getId: (order) => order.id,
  );

  @override
  String getEndpoint() => 'order';

  /// Admin: Tüm siparişleri getir (sayfalama ve filtreleme ile)
  @override
  Future<PaginatedOrderResponse> fetchAllOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? paymentStatus,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (status != null) queryParams['status'] = status;
      if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
      if (searchTerm != null) queryParams['searchTerm'] = searchTerm;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await dio.get(
        '${getEndpoint()}/admin/all',
        queryParameters: queryParams,
      );

      if (response.data['Success'] == true) {
        return PaginatedOrderResponse.fromJson(response.data['Data']);
      } else {
        throw response.data['Message'] ?? 'Failed to fetch orders';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Admin: Sipariş istatistiklerini getir
  @override
  Future<OrderStatistics> fetchStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await dio.get(
        '${getEndpoint()}/admin/statistics',
        queryParameters: queryParams,
      );

      if (response.data['Success'] == true) {
        return OrderStatistics.fromJson(response.data['Data']);
      } else {
        throw response.data['Message'] ?? 'Failed to fetch statistics';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kullanıcının siparişlerini getir
  @override
  Future<List<OrderModel>> fetchUserOrders({required String userId}) async {
    try {
      final response = await dio.get('${getEndpoint()}/user/$userId');

      if (response.data['Success'] == true) {
        final List<dynamic> ordersJson = response.data['Data'] ?? [];
        return ordersJson
            .map((json) => OrderModel.fromJson('', json as Map<String, dynamic>))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch user orders';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// FAZ 26 — kullanıcının **alışverişlerini** (sipariş gruplarını) getirir.
  ///
  /// Uç yoksa/erişilemezse (eski API ya da geçici hata) **düz sipariş
  /// listesinden** gruplar kurulur: `GET /order/user/{id}` her satırda
  /// `GroupId`/`GroupNumber` taşıyor. Böylece ekran her koşulda dolar.
  @override
  Future<List<OrderGroupModel>> fetchUserOrderGroups({required String userId}) async {
    try {
      final response = await dio.get('${getEndpoint()}/groups/user/$userId');

      if (response.data['Success'] == true) {
        final List<dynamic> groupsJson = response.data['Data'] ?? [];
        return groupsJson
            .whereType<Map>()
            .map((json) => OrderGroupModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      // Uç "başarısız" dedi — yedek yola düş.
      return OrderGroupModel.fromFlatOrders(await fetchUserOrders(userId: userId));
    } catch (_) {
      // 404 (uç yok) / ağ hatası: düz listeden grup kur. Bu da patlarsa
      // hatayı yukarı taşı, çağıran boş liste gösterir.
      return OrderGroupModel.fromFlatOrders(await fetchUserOrders(userId: userId));
    }
  }

  /// Tek bir siparişi getir
  @override
  Future<OrderModel> fetchSingleOrder({required String orderId}) async {
    try {
      final response = await dio.get('${getEndpoint()}/$orderId');

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to fetch order';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Yeni sipariş oluştur.
  ///
  /// FAZ 26 — yanıt artık bir **alışveriş**tir: grubun kimliği/numarası ve
  /// şirket başına doğan siparişler (`Orders[]`). K7 gereği eski `OrderId` /
  /// `OrderNumber` alanları da yerinde duruyor, bu yüzden yanıt eski API'den
  /// geliyorsa (yeni alanlar yoksa) sonuç tek siparişlik bir alışveriş olur.
  @override
  Future<CreateOrderResultModel> createOrder({
    required String userId,
    required String shippingAddressId,
    required String billingAddressId,
    required String paymentMethod,
    String? customerNote,
    String? couponCode,
    // 🔴 FAZ 07 — stoksuz sipariş yetkisi olan bayi stok bitse de sipariş
    // verebiliyor; sunucu stok kapısını bu bayrağa göre gevşetiyor
    // (web `services/order.service.js` → `CanOrderWithoutStock`).
    // Referans mobilde YOK; alan olmadan o bayinin siparişi stok kapısına
    // takılıyor.
    bool canOrderWithoutStock = false,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'shippingAddressId': shippingAddressId,
        'billingAddressId': billingAddressId,
        'paymentMethod': paymentMethod,
        // Sunucu bu alanları zorunlu tutuyor (null'ı 400 ile reddediyor);
        // not/kupon yoksa boş dize gönderilir.
        'customerNote': customerNote ?? '',
        'couponCode': couponCode ?? '',
        'canOrderWithoutStock': canOrderWithoutStock,
      };

      // debugPrint('🛒 [ApiOrderRepository.createOrder] POST ${getEndpoint()}/create body=$requestBody');

      final response = await dio.post(
        '${getEndpoint()}/create',
        data: requestBody,
      );

      // debugPrint('🛒 [ApiOrderRepository.createOrder] response status=${response.statusCode} data=${response.data}');

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return CreateOrderResultModel.fromJson(d);
      } else {
        // debugPrint('🛒 [ApiOrderRepository.createOrder] backend reported failure: ${response.data['Message']}');
        throw response.data['Message'] ?? 'Failed to create order';
      }
    } catch (e) {
      // debugPrint('🛒 [ApiOrderRepository.createOrder] EXCEPTION: $e');
      throw handleException(e);
    }
  }

  /// Sipariş durumunu güncelle (status + note ile)
  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/update-status',
        data: {
          'orderId': orderId,
          'newStatus': newStatus,
          'note': note,
        },
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['message'] ?? 'Failed to update order status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Sadece sipariş durumunu güncelle (Flutter uyumlu - PATCH)
  @override
  Future<OrderModel> updateOrderStatusOnly({
    required String orderId,
    required String orderStatus,
  }) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$orderId/status',
        data: {'orderStatus': orderStatus},
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update order status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Sadece ödeme durumunu güncelle (Flutter uyumlu - PATCH)
  @override
  Future<OrderModel> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
  }) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$orderId/payment-status',
        data: {'paymentStatus': paymentStatus},
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update payment status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kargo bilgilerini güncelle
  @override
  Future<OrderModel> updateTrackingInfo({
    required String orderId,
    required String shippingCompany,
    required String trackingNumber,
  }) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/$orderId/tracking',
        data: {
          'shippingCompany': shippingCompany,
          'trackingNumber': trackingNumber,
        },
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update tracking info';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Siparişi sil (soft delete - cancelled olarak işaretler)
  @override
  Future<void> deleteOrder({required String orderId}) async {
    try {
      final response = await dio.delete('${getEndpoint()}/$orderId');

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to delete order';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Sipariş ara
  @override
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/search',
        queryParameters: {'query': query, 'limit': 20},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> ordersJson = response.data['Data'] ?? [];
        return ordersJson
            .map((json) => OrderModel.fromJson('', json as Map<String, dynamic>))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to search orders';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Duruma göre siparişleri getir
  @override
  Future<List<OrderModel>> fetchOrdersByStatus(String status) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/by-status',
        queryParameters: {'status': status, 'limit': 20},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> ordersJson = response.data['Data'] ?? [];
        return ordersJson
            .map((json) => OrderModel.fromJson('', json as Map<String, dynamic>))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch orders by status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Tarih aralığına göre siparişleri getir
  @override
  Future<List<OrderModel>> fetchOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/by-date-range',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.data['Success'] == true) {
        final List<dynamic> ordersJson = response.data['Data'] ?? [];
        return ordersJson
            .map((json) => OrderModel.fromJson('', json as Map<String, dynamic>))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch orders by date range';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Siparişe aktivite ekle
  @override
  Future<void> addOrderActivity({
    required String orderId,
    required String note,
    String? changedBy,
  }) async {
    try {
      final response = await dio.post(
        '${getEndpoint()}/$orderId/activity',
        data: {
          'note': note,
          'changedBy': changedBy ?? 'system',
        },
      );

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to add activity';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Sipariş geçmişini getir
  @override
  Future<List<OrderStatusHistory>> fetchOrderHistory({
    required String orderId,
  }) async {
    try {
      final response = await dio.get('${getEndpoint()}/$orderId/history');

      if (response.data['Success'] == true) {
        final List<dynamic> historyJson = response.data['Data'] ?? [];
        return historyJson
            .map((json) => OrderStatusHistory.fromJson(json))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch order history';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // Sipariş durumunu güncelle (userId ile)
  @override
  Future<OrderModel> updateOrderStatusWithUser({
    required String orderId,
    required String newStatus,
    required String changedByUserId,
    String? note,
  }) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/$orderId/status-with-user',
        data: {
          'newStatus': newStatus,
          'changedByUserId': changedByUserId,
          'note': note,
        },
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update order status';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Detaylı sipariş geçmişini getir (kullanıcı bilgileriyle)
  @override
  Future<List<OrderStatusHistoryDetailed>> fetchOrderHistoryDetailed({
    required String orderId,
  }) async {
    try {
      final response = await dio.get('${getEndpoint()}/$orderId/history-detailed');

      if (response.data['Success'] == true) {
        final List<dynamic> historyJson = response.data['Data'] ?? [];
        return historyJson
            .map((json) => OrderStatusHistoryDetailed.fromJson(json))
            .toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch detailed order history';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Siparişi tamamen güncelle (ürünler, fiyatlar vs.)
  @override
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
  }) async {
    try {
      final requestBody = {
        'subtotal': subtotal,
        'totalVat': totalVat,
        'shippingCost': shippingCost,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'updatedByUserId': updatedByUserId,
        'customerNote': customerNote,
        'adminNote': adminNote,
        'items': items?.map((item) => item.toJson()).toList(),
      };

      final response = await dio.put(
        '${getEndpoint()}/$orderId/update-full',
        data: requestBody,
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update order';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<OrderModel> freeEditOrder({
    required String orderId,
    required String updatedByUserId,
    String? adminNote,
    double? subtotal,
    double? totalVat,
    double? shippingCost,
    double? discountAmount,
    double? totalAmount,
    bool autoRecalculate = false,
    List<FreeEditOrderItem>? items,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'updatedByUserId': updatedByUserId,
        'autoRecalculate': autoRecalculate,
        if (adminNote != null) 'adminNote': adminNote,
        if (subtotal != null) 'subtotal': subtotal,
        if (totalVat != null) 'totalVat': totalVat,
        if (shippingCost != null) 'shippingCost': shippingCost,
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (items != null) 'items': items.map((item) => item.toJson()).toList(),
      };

      final response = await dio.put(
        '${getEndpoint()}/$orderId/edit-free',
        data: requestBody,
      );

      if (response.data['Success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return OrderModel.fromJson(d['orderId']?.toString() ?? orderId, d);
      } else {
        throw response.data['Message'] ?? 'Failed to update order';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
