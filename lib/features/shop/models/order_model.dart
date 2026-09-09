import 'dart:convert';

import 'package:t_utils/utils/constants/enums.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/erp_source_helper.dart';
import '../../personalization/models/address_model.dart';
import 'cart_item_model.dart';
import 'coupon_model.dart';
import 'order_activity.dart';
import 'shipping_model.dart';

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  try {
    return value.toDate();
  } catch (_) {
    return DateTime.now();
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Tek bir sipariş satırı.
///
/// 🔴 Bir alışveriş şirket (1C kaynağı) başına birden çok siparişe bölünebilir;
/// hepsi aynı `GroupId` altında toplanır. Müşteriye gösterilen bütün
/// [OrderGroupModel]'dir, bu model onun bir parçasıdır.
class OrderModel {
  String docId;
  final String id;
  final String orderNumber; // e.g. "ORD-20240618-00001"
  final String userId;
  final String userName;
  final String userEmail;
  final String userDeviceToken;
  final List<CartItemModel> products;

  // Pricing
  final double subTotal;
  final double shippingAmount;
  final double taxRate;
  final double taxAmount;
  final CouponModel? coupon;
  final double couponDiscountAmount;
  final int pointsUsed;
  final double pointsDiscountAmount;
  final double totalDiscountAmount;
  final double totalAmount;

  // Other
  OrderStatus orderStatus;
  final DateTime orderDate;
  final DateTime? shippingDate;
  final AddressModel shippingAddress;
  final AddressModel? billingAddress;
  final bool billingAddressSameAsShipping;
  final String shippingAddressId;   // raw ID from backend, used when address object is absent
  final String billingAddressId;
  final ShippingInfo shippingInfo;
  final List<OrderActivity> activities;
  final int itemCount;
  final DateTime createdAt;
  DateTime updatedAt;
  final String adminNote;

  // Payment
  final PaymentMethods paymentMethodType;
  final String paymentMethod;
  final String? paymentIntentId;
  final String? paymentMethodId;
  final double amountCaptured;
  final PaymentStatus paymentStatus;
  final String currency;
  String? lastPaymentError;
  String? paymentErrorCode;

  // ─── FAZ 26: sipariş grubu ve şirket ──────────────────────────────────────
  // Bir checkout artık bir GRUP + şirket başına bir SİPARİŞtir (karar K1/K2).
  // Aşağıdaki alanların hepsi opsiyoneldir: eski API yanıtında yokturlar ve
  // yoklukları hiçbir ekranı çökertmez (savunmacı fromJson).

  /// `orders.group_id` — siparişin ait olduğu alışveriş (checkout).
  final String groupId;

  /// `order_groups.group_number` — alışveriş numarası (ör. `ORD-20260826-00001`).
  final String groupNumber;

  /// `orders.group_seq` — grup içindeki sıra (1..N).
  final int? groupSeq;

  /// Siparişin şirketi (`erp_sources.id`). Eski siparişlerde boş.
  final String erpSourceId;

  /// Siparişin şirket kodu (`fores` / `foral` / ...). Eski siparişlerde boş.
  final String erpSourceCode;

  /// Şirketin sunucudan gelen görünen adı. Boşsa yerel eşlemeye düşülür.
  final String erpSourceName;

  /// Grupta kaç sipariş var. Kardeş siparişlerin TEK bilgisi budur —
  /// numaraları/tutarları/ürünleri sunucu göndermez (izolasyon matrisi).
  /// Yalnız `GET /order/{id}` bu alanı dolduruyor; liste uçlarında boş gelir.
  final int? groupOrderCount;

  /// Sunucunun gönderdiği HAM sipariş durumu.
  ///
  /// [orderStatus] enum'unda (`t_utils`) `confirmed` değeri YOK; ödeme sonrası
  /// backend siparişi bu duruma geçiriyor ve enum'a çevrilirken `pending`e
  /// düşüyordu — ekranda ödenmiş sipariş "Pending" görünüyordu. Gösterimde ham
  /// değer kullanılır, mantıkta enum.
  final String orderStatusRaw;

  // ─── FAZ 08: kargo bilgisi (sipariş kökünden) ─────────────────────────────
  // Web (`pages/order.js` → `trackingHtml`) kargo bilgisini siparişin KÖK
  // alanlarından okuyor: `ShippingCompany`, `TrackingNumber`, `ShippedAt`,
  // `DeliveredAt`. Referans mobilde yalnız `ShippingInfo` nesnesi vardı ve
  // sunucu onu doldurmuyor — bu yüzden kök alanlar da ayrıştırılıyor.
  // Hepsi opsiyoneldir; **yalnız sunucu doldurduysa** ekrana çizilirler.

  /// Kargo firması (`orders.shipping_company`).
  final String shippingCompany;

  /// Kargo takip numarası (`orders.tracking_number`).
  final String trackingNumber;

  /// Teslim tarihi (`orders.delivered_at`). Gönderim tarihi [shippingDate].
  final DateTime? deliveredAt;

  OrderModel({
    required this.docId,
    required this.id,
    this.orderNumber = '',
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    this.userDeviceToken = '',
    required this.products,
    required this.subTotal,
    required this.shippingAmount,
    required this.taxRate,
    required this.taxAmount,
    this.coupon,
    required this.couponDiscountAmount,
    required this.pointsUsed,
    required this.pointsDiscountAmount,
    required this.totalDiscountAmount,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.orderDate,
    this.shippingDate,
    required this.shippingAddress,
    this.billingAddress,
    required this.shippingInfo,
    required this.activities,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
    this.adminNote = '',
    this.billingAddressSameAsShipping = true,
    this.shippingAddressId = '',
    this.billingAddressId = '',
    this.currency = '',
    this.paymentIntentId,
    this.paymentMethodId,
    this.paymentMethod = '',
    this.paymentMethodType = PaymentMethods.cash,
    this.amountCaptured = 0.0,
    this.groupId = '',
    this.groupNumber = '',
    this.groupSeq,
    this.erpSourceId = '',
    this.erpSourceCode = '',
    this.erpSourceName = '',
    this.groupOrderCount,
    this.orderStatusRaw = '',
    this.shippingCompany = '',
    this.trackingNumber = '',
    this.deliveredAt,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);
  String get formattedOrderDate => TFormatter.formatDate(orderDate);
  String get formattedOrderDateTime => TFormatter.formatDateAndTime(orderDate);
  String get formattedUpdatedAtDate => TFormatter.formatDate(updatedAt);

  /// Display ID: prefer orderNumber, fall back to id.
  String get displayId => orderNumber.isNotEmpty ? orderNumber : id;

  // ─── FAZ 26 yardımcıları ──────────────────────────────────────────────────

  /// Ekranda gösterilecek şirket adı. Şirketi olmayan (eski) siparişte **boş** —
  /// ad uydurulmaz, ilgili satır hiç çizilmez.
  String get companyLabel => TErpSource.label(erpSourceCode, erpSourceName);

  /// Siparişin bir şirketi var mı (eski `erp_source_id IS NULL` kayıtları hariç).
  bool get hasCompany => companyLabel.isNotEmpty;

  /// Müşterinin gördüğü "alışveriş numarası". Grubu yoksa sipariş numarasına düşer.
  String get purchaseNumber => groupNumber.isNotEmpty ? groupNumber : displayId;

  /// Sipariş, birden çok siparişe bölünmüş bir alışverişin parçası mı.
  /// (`GroupOrderCount` yalnız tek sipariş ucundan gelir; gelmezse `false`.)
  bool get isPartOfSplitPurchase => (groupOrderCount ?? 0) > 1;

  /// Gösterim için sipariş durumu anahtarı: enum'da karşılığı olmayan
  /// `confirmed` gibi ham değerler korunur.
  String get statusKey => orderStatusRaw.isNotEmpty ? orderStatusRaw : orderStatus.name;

  /// Sunucu kargo bilgisinin HERHANGİ bir alanını doldurdu mu. Hiçbiri yoksa
  /// sipariş detayında kargo kutusu **hiç çizilmez** (boş kutu gösterilmez).
  bool get hasShippingInfo =>
      shippingCompany.isNotEmpty ||
      trackingNumber.isNotEmpty ||
      shippingDate != null ||
      deliveredAt != null;

  double calculateSubTotal() => products.fold(0.0, (prev, p) => prev + (p.salePrice * p.quantity));
  double calculateTotalDiscount() => couponDiscountAmount + pointsDiscountAmount;
  double calculateTaxAfterDiscount() {
    final adjusted = calculateSubTotal() - calculateTotalDiscount();
    return (adjusted > 0 ? adjusted : 0.0) * taxRate;
  }

  double calculateGrandTotal() {
    final adjusted = calculateSubTotal() - calculateTotalDiscount();
    return (adjusted > 0 ? adjusted : 0.0) + calculateTaxAfterDiscount() + shippingAmount;
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userDeviceToken': userDeviceToken,
        'products': products.map((p) => p.toJson()).toList(),
        'subTotal': subTotal,
        'shippingAmount': shippingAmount,
        'taxRate': taxRate,
        'taxAmount': taxAmount,
        'coupon': coupon?.toJson(),
        'couponDiscountAmount': couponDiscountAmount,
        'pointsUsed': pointsUsed,
        'pointsDiscountAmount': pointsDiscountAmount,
        'totalDiscountAmount': totalDiscountAmount,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus.name,
        'orderStatus': orderStatus.name,
        'orderDate': orderDate.toIso8601String(),
        'shippingDate': shippingDate?.toIso8601String(),
        'billingAddressSameAsShipping': billingAddressSameAsShipping,
        'shippingAddressId': shippingAddressId,
        'billingAddressId': billingAddressId,
        'shippingAddress': shippingAddress.toJson(),
        'billingAddress': billingAddress?.toJson(),
        'shippingInfo': shippingInfo.toJson(),
        'activities': activities.map((a) => a.toJson()).toList(),
        'itemCount': itemCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'adminNote': adminNote,
        'currency': currency,
        'paymentIntentId': paymentIntentId,
        'paymentMethodId': paymentMethodId,
        'paymentMethod': paymentMethod,
        'paymentMethodType': paymentMethodType.name,
        'amountCaptured': amountCaptured,
        'groupId': groupId,
        'groupNumber': groupNumber,
        'groupSeq': groupSeq,
        'erpSourceId': erpSourceId,
        'erpSourceCode': erpSourceCode,
        'erpSourceName': erpSourceName,
        'groupOrderCount': groupOrderCount,
        'orderStatusRaw': orderStatusRaw,
        'shippingCompany': shippingCompany,
        'trackingNumber': trackingNumber,
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  // ─── fromJson ─────────────────────────────────────────────────────────────

  static OrderModel fromJson(String id, Map<String, dynamic> data) {
    try {
      final products = _parseProducts(data);

      // Try PascalCase (ASP.NET default) → camelCase → lowercase, in that order.
      final resolvedId = _pick(data, ['id', 'OrderId', 'orderId', 'orderid']) ?? id;
      final resolvedDocId = id.isNotEmpty ? id : resolvedId;
      final createdAt = _parseDateTime(_pick(data, ['CreatedAt', 'createdAt', 'createdat']));

      return OrderModel(
        docId: resolvedDocId,
        id: resolvedId,
        orderNumber: _pick(data, ['OrderNumber', 'orderNumber', 'ordernumber']) ?? '',
        userId: _pick(data, ['UserId', 'userId', 'userid']) ?? '',
        userName: _pick(data, ['UserName', 'userName', 'username']) ?? '',
        userEmail: _pick(data, ['UserEmail', 'userEmail', 'useremail']) ?? '',
        userDeviceToken: _pick(data, ['UserDeviceToken', 'userDeviceToken']) ?? '',
        products: products,
        subTotal: _parseDouble(_pick(data, ['Subtotal', 'SubTotal', 'subTotal', 'subtotal'])),
        shippingAmount: _parseDouble(_pick(data, ['ShippingCost', 'shippingCost', 'shippingcost', 'ShippingAmount', 'shippingAmount'])),
        taxRate: _parseDouble(_pick(data, ['TaxRate', 'taxRate', 'taxrate'])),
        taxAmount: _parseDouble(_pick(data, ['TaxAmount', 'taxAmount', 'TotalVat', 'totalVat', 'totalvat'])),
        coupon: _pickRaw(data, ['coupon', 'Coupon']) is Map
            ? CouponModel.fromJson(
                (_pickRaw(data, ['coupon', 'Coupon']) as Map)['id']?.toString() ?? '',
                _pickRaw(data, ['coupon', 'Coupon']) as Map<String, dynamic>)
            : null,
        couponDiscountAmount: _parseDouble(_pick(data, ['CouponDiscountAmount', 'couponDiscountAmount', 'DiscountAmount', 'discountAmount', 'discountamount'])),
        pointsUsed: (_pickRaw(data, ['PointsUsed', 'pointsUsed']) as int?) ?? 0,
        pointsDiscountAmount: _parseDouble(_pick(data, ['PointsDiscountAmount', 'pointsDiscountAmount'])),
        totalDiscountAmount: _parseDouble(_pick(data, ['TotalDiscountAmount', 'totalDiscountAmount', 'DiscountAmount', 'discountAmount', 'discountamount'])),
        totalAmount: _parseDouble(_pick(data, ['TotalAmount', 'totalAmount', 'totalamount'])),
        paymentStatus: _parsePaymentStatus(_pick(data, ['PaymentStatus', 'paymentStatus', 'paymentstatus'])),
        orderStatus: _parseOrderStatus(_pick(data, ['OrderStatus', 'orderStatus', 'orderstatus'])),
        orderDate: _parseDateTime(_pick(data, ['OrderDate', 'orderDate', 'CreatedAt', 'createdAt', 'createdat'])),
        shippingDate: _parseDateTimeOrNull(_pick(data, ['ShippedAt', 'shippedAt', 'shippedat', 'ShippingDate', 'shippingDate'])),
        shippingAddress: _parseAddress(data, ['ShippingAddress', 'shippingAddress'], ['ShippingAddressSnapshot', 'shippingAddressSnapshot']),
        billingAddress: _parseAddress(data, ['BillingAddress', 'billingAddress'], ['BillingAddressSnapshot', 'billingAddressSnapshot']),
        billingAddressSameAsShipping: (_pickRaw(data, ['BillingAddressSameAsShipping', 'billingAddressSameAsShipping']) as bool?) ?? true,
        shippingAddressId: _pick(data, ['ShippingAddressId', 'shippingAddressId']) ?? '',
        billingAddressId: _pick(data, ['BillingAddressId', 'billingAddressId']) ?? '',
        shippingInfo: _pickRaw(data, ['ShippingInfo', 'shippingInfo']) is Map
            ? ShippingInfo.fromJson(_pickRaw(data, ['ShippingInfo', 'shippingInfo']) as Map<String, dynamic>)
            : ShippingInfo.empty(),
        activities: _pickRaw(data, ['Activities', 'activities']) is List
            ? (_pickRaw(data, ['Activities', 'activities']) as List)
                .map((e) => OrderActivity.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        itemCount: (_pickRaw(data, ['ItemCount', 'itemCount', 'itemcount']) as int?) ?? products.length,
        createdAt: createdAt,
        updatedAt: _parseDateTime(_pick(data, ['UpdatedAt', 'updatedAt', 'updatedat', 'CreatedAt', 'createdAt', 'createdat'])),
        adminNote: _pick(data, ['AdminNote', 'adminNote', 'adminnote']) ?? '',
        currency: _pick(data, ['Currency', 'currency']) ?? '',
        paymentIntentId: _pick(data, ['PaymentIntentId', 'paymentIntentId']),
        paymentMethodId: _pick(data, ['PaymentMethodId', 'paymentMethodId']),
        paymentMethod: _pick(data, ['PaymentMethod', 'paymentMethod', 'paymentmethod']) ?? '',
        paymentMethodType: _pick(data, ['PaymentMethodType', 'paymentMethodType']) != null
            ? PaymentMethods.values.firstWhere(
                (e) => e.name == _pick(data, ['PaymentMethodType', 'paymentMethodType']),
                orElse: () => PaymentMethods.cash,
              )
            : PaymentMethods.cash,
        amountCaptured: _parseDouble(_pick(data, ['AmountCaptured', 'amountCaptured'])),
        // FAZ 26 — grup/şirket alanları. Hepsi opsiyonel: eski API yanıtında
        // yoklar ve yoklukları çökmeye yol açmaz.
        groupId: _pick(data, ['GroupId', 'groupId', 'groupid']) ?? '',
        groupNumber: _pick(data, ['GroupNumber', 'groupNumber', 'groupnumber']) ?? '',
        groupSeq: _parseIntOrNull(_pickRaw(data, ['GroupSeq', 'groupSeq', 'groupseq'])),
        erpSourceId: _pick(data, ['ErpSourceId', 'erpSourceId', 'erpsourceid']) ?? '',
        erpSourceCode: _pick(data, ['ErpSourceCode', 'erpSourceCode', 'erpsourcecode', 'ErpSource', 'erpSource']) ?? '',
        erpSourceName: _pick(data, ['ErpSourceName', 'erpSourceName', 'erpsourcename']) ?? '',
        groupOrderCount: _parseIntOrNull(_pickRaw(data, ['GroupOrderCount', 'groupOrderCount', 'grouporcount', 'groupordercount'])),
        orderStatusRaw: _pick(data, ['OrderStatus', 'orderStatus', 'orderstatus']) ?? '',
        // FAZ 08 — kargo bilgisi sipariş kökünde; sunucu doldurmadıysa boş kalır.
        shippingCompany: _pick(data, ['ShippingCompany', 'shippingCompany', 'shippingcompany']) ?? '',
        trackingNumber: _pick(data, ['TrackingNumber', 'trackingNumber', 'trackingnumber']) ?? '',
        deliveredAt: _parseDateTimeOrNull(_pick(data, ['DeliveredAt', 'deliveredAt', 'deliveredat'])),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Returns the first non-null string value found among [keys].
  static String? _pick(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /// Returns the first non-null raw value found among [keys].
  static dynamic _pickRaw(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) return data[key];
    }
    return null;
  }

  /// Sayı alanları backend'den bazen `int`, bazen metin gelebiliyor; ikisini de
  /// kabul eder, çözülemezse `null` döner (asla fırlatmaz).
  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static DateTime? _parseDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    try {
      return value.toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }

  /// Normalize backend status strings to Flutter enum names.
  static OrderStatus _parseOrderStatus(dynamic value) {
    if (value == null) return OrderStatus.pending;
    // Backend may send 'cancelled' (British). Flutter enum uses 'canceled'.
    String s = value.toString();
    if (s == 'cancelled') s = 'canceled';
    return OrderStatus.values.firstWhere((e) => e.name == s, orElse: () => OrderStatus.pending);
  }

  /// Backend sends 'pending' for new/unpaid orders; Flutter enum uses 'unpaid'.
  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value == null) return PaymentStatus.unpaid;
    String s = value.toString();
    if (s == 'pending') s = 'unpaid';
    return PaymentStatus.values.firstWhere((e) => e.name == s, orElse: () => PaymentStatus.unpaid);
  }

  /// Parse products from 'Items'/'items' (REST API) or 'products' (legacy local).
  static List<CartItemModel> _parseProducts(Map<String, dynamic> data) {
    // REST API order items — try PascalCase first, then camelCase/lowercase.
    final rawItems = _pickRaw(data, ['Items', 'items']);
    if (rawItems is List && rawItems.isNotEmpty) {
      return rawItems
          .map((e) => CartItemModel.fromOrderItem(e as Map<String, dynamic>))
          .toList();
    }
    // Legacy / local 'products' list (CartItemModel JSON).
    final rawProducts = _pickRaw(data, ['products', 'Products']);
    if (rawProducts is List && rawProducts.isNotEmpty) {
      return rawProducts
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Parse address from a nested object or a JSON snapshot string.
  static AddressModel _parseAddress(
    Map<String, dynamic> data,
    List<String> objectKeys,
    List<String> snapshotKeys,
  ) {
    final obj = _pickRaw(data, objectKeys);
    if (obj is Map<String, dynamic> && obj.isNotEmpty) {
      final addrId = _pick(obj, ['AddressId', 'addressId', 'id']) ?? '';
      return AddressModel.fromJson(addrId, obj);
    }
    final snapshot = _pickRaw(data, snapshotKeys);
    if (snapshot is String && snapshot.isNotEmpty) {
      try {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map<String, dynamic>) {
          final addrId = _pick(decoded, ['AddressId', 'addressId', 'id']) ?? '';
          return AddressModel.fromJson(addrId, decoded);
        }
      } catch (_) {}
    }
    return AddressModel.empty();
  }

  // ─── Empty factory ────────────────────────────────────────────────────────

  static OrderModel empty() => OrderModel(
        docId: '',
        id: '',
        orderNumber: '',
        userId: '',
        userDeviceToken: '',
        subTotal: 0.0,
        shippingAmount: 0.0,
        taxRate: 0.0,
        taxAmount: 0.0,
        couponDiscountAmount: 0.0,
        pointsUsed: 0,
        pointsDiscountAmount: 0.0,
        totalDiscountAmount: 0.0,
        totalAmount: 0.0,
        paymentStatus: PaymentStatus.unpaid,
        orderStatus: OrderStatus.pending,
        orderDate: DateTime.now(),
        shippingAddress: AddressModel.empty(),
        shippingInfo: ShippingInfo.empty(),
        activities: [],
        itemCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        products: [],
      );
}
