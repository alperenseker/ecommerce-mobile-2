/// Alışveriş grubu: tek ödemeyle kapanan, şirket (1C `erpSource`) başına
/// bölünmüş siparişlerin bütünü.
library;

import 'package:t_utils/utils/constants/enums.dart';

import 'order_model.dart';

/// Bir **alışveriş** (checkout). FAZ 26 / karar K1.
///
/// Müşterinin verdiği tek sipariş, şirket başına bir `orders` satırına
/// bölünüyor; müşterinin gördüğü bütün ise bu gruptur. Tutarlar grubun
/// TOPLAMIDIR, ödeme tek çekimdir (K3).
///
/// Bütün `fromJson` yolları savunmacıdır: alan yoksa varsayılana düşer,
/// hiçbir eksik alan çökmeye yol açmaz (eski API ile de açılır).
class OrderGroupModel {
  const OrderGroupModel({
    required this.groupId,
    required this.groupNumber,
    required this.userId,
    required this.subtotal,
    required this.totalVat,
    required this.shippingCost,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.invoiceId,
    required this.createdAt,
    required this.orders,
  });

  final String groupId;
  final String groupNumber;
  final String userId;

  final double subtotal;
  final double totalVat;
  final double shippingCost;
  final double discountAmount;
  final double totalAmount;

  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final String invoiceId;
  final DateTime createdAt;

  /// Gruba bağlı siparişler, `group_seq` sırasıyla.
  final List<OrderModel> orders;

  int get orderCount => orders.length;

  /// Alışveriş birden çok siparişe bölündü mü.
  bool get isSplit => orders.length > 1;

  /// Sunucudan gerçek bir grup numarası geldi mi. Gelmediyse (eski, grubu
  /// olmayan sipariş) ekranda grup başlığı çizilmez.
  bool get hasGroupNumber => groupNumber.isNotEmpty;

  /// Ekranda gösterilecek alışveriş numarası.
  String get displayNumber =>
      groupNumber.isNotEmpty ? groupNumber : (orders.isNotEmpty ? orders.first.displayId : groupId);

  /// Grupta ödenmemiş sipariş var mı — "ödemeyi tamamla" akışının koşulu.
  bool get isUnpaid => paymentStatus != PaymentStatus.paid;

  // ─── Serialization ────────────────────────────────────────────────────────

  static OrderGroupModel fromJson(Map<String, dynamic> data) {
    final orders = _parseOrders(data);

    return OrderGroupModel(
      groupId: _pickString(data, ['GroupId', 'groupId', 'groupid']),
      groupNumber: _pickString(data, ['GroupNumber', 'groupNumber', 'groupnumber']),
      userId: _pickString(data, ['UserId', 'userId', 'userid']),
      subtotal: _parseDouble(_pickRaw(data, ['Subtotal', 'subtotal', 'SubTotal', 'subTotal'])),
      totalVat: _parseDouble(_pickRaw(data, ['TotalVat', 'totalVat', 'totalvat'])),
      shippingCost: _parseDouble(_pickRaw(data, ['ShippingCost', 'shippingCost', 'shippingcost'])),
      discountAmount: _parseDouble(_pickRaw(data, ['DiscountAmount', 'discountAmount', 'discountamount'])),
      totalAmount: _parseDouble(_pickRaw(data, ['TotalAmount', 'totalAmount', 'totalamount'])),
      paymentMethod: _pickString(data, ['PaymentMethod', 'paymentMethod', 'paymentmethod']),
      paymentStatus: _parsePaymentStatus(_pickRaw(data, ['PaymentStatus', 'paymentStatus', 'paymentstatus'])),
      invoiceId: _pickString(data, ['InvoiceId', 'invoiceId', 'invoiceid']),
      createdAt: _parseDateTime(_pickRaw(data, ['CreatedAt', 'createdAt', 'createdat'])),
      orders: orders,
    );
  }

  /// Tek bir siparişten tek siparişlik alışveriş kurar (grubu olmayan eski
  /// kayıtlar ve tek şirketli sipariş için).
  static OrderGroupModel fromOrder(OrderModel order) => OrderGroupModel(
        groupId: order.groupId,
        groupNumber: order.groupNumber,
        userId: order.userId,
        subtotal: order.subTotal,
        totalVat: order.taxAmount,
        shippingCost: order.shippingAmount,
        discountAmount: order.totalDiscountAmount,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        invoiceId: '',
        createdAt: order.createdAt,
        orders: [order],
      );

  /// **Yedek yol:** grup ucu okunamadığında düz sipariş listesinden grupları
  /// kurar. `GET /order/user/{userId}` her satırda `GroupId`/`GroupNumber`
  /// taşıyor (Faz 16'dan beri); grubu olmayan eski sipariş kendi başına tek
  /// siparişlik bir alışveriş sayılır.
  ///
  /// Toplamlar siparişlerin toplanmasıyla bulunur; ödeme durumu **hepsi
  /// ödendiyse** `paid`, biri bile başarısızsa `failed`, aksi hâlde `unpaid`.
  static List<OrderGroupModel> fromFlatOrders(List<OrderModel> orders) {
    final buckets = <String, List<OrderModel>>{};
    for (final order in orders) {
      // Grubu olmayan sipariş kendi kimliğiyle tekil bir kovaya düşer.
      final key = order.groupId.isNotEmpty ? order.groupId : 'order:${order.id}';
      buckets.putIfAbsent(key, () => <OrderModel>[]).add(order);
    }

    final groups = buckets.values.map((list) {
      list.sort((a, b) => (a.groupSeq ?? 0).compareTo(b.groupSeq ?? 0));
      final first = list.first;

      final allPaid = list.every((o) => o.paymentStatus == PaymentStatus.paid);
      final anyFailed = list.any((o) => o.paymentStatus == PaymentStatus.failed);

      return OrderGroupModel(
        groupId: first.groupId,
        groupNumber: first.groupNumber,
        userId: first.userId,
        subtotal: list.fold(0.0, (sum, o) => sum + o.subTotal),
        totalVat: list.fold(0.0, (sum, o) => sum + o.taxAmount),
        shippingCost: list.fold(0.0, (sum, o) => sum + o.shippingAmount),
        discountAmount: list.fold(0.0, (sum, o) => sum + o.totalDiscountAmount),
        totalAmount: list.fold(0.0, (sum, o) => sum + o.totalAmount),
        paymentMethod: first.paymentMethod,
        paymentStatus: allPaid
            ? PaymentStatus.paid
            : anyFailed
                ? PaymentStatus.failed
                : PaymentStatus.unpaid,
        invoiceId: '',
        createdAt: first.createdAt,
        orders: list,
      );
    }).toList();

    groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }
}

/// `POST /api/order/create` yanıtı (karar K7).
///
/// `OrderId` / `OrderNumber` eski anlamlarını korur — `OrderId` grubun İLK
/// siparişi, `OrderNumber` ise artık GRUP numarasıdır. Yeni alanlar
/// (`GroupId`, `GroupNumber`, `Orders[]`) yoksa uygulama eski tek siparişlik
/// davranışa düşer; **hiçbir alanın yokluğu çökmeye yol açmaz.**
class CreateOrderResultModel {
  const CreateOrderResultModel({
    required this.orderId,
    required this.orderNumber,
    required this.groupId,
    required this.groupNumber,
    required this.totalAmount,
    required this.orders,
  });

  final String orderId;
  final String orderNumber;
  final String groupId;
  final String groupNumber;
  final double totalAmount;
  final List<OrderModel> orders;

  /// Bu alışverişte doğan sipariş sayısı. `Orders[]` gelmediyse (eski API)
  /// tek sipariş varsayılır.
  int get orderCount => orders.isNotEmpty ? orders.length : 1;

  bool get isSplit => orders.length > 1;

  /// Müşteriye gösterilecek alışveriş numarası.
  String get purchaseNumber =>
      groupNumber.isNotEmpty ? groupNumber : (orderNumber.isNotEmpty ? orderNumber : orderId);

  /// Ödeme doğrulaması için yoklanacak sipariş: grubun ilk siparişi.
  /// Postlink grubun TÜM siparişlerini birden `paid` yapar (K3), o yüzden
  /// tek siparişi yoklamak yeterlidir.
  String get pollOrderId => orders.isNotEmpty ? orders.first.id : orderId;

  static CreateOrderResultModel fromJson(Map<String, dynamic> data) {
    final orders = _parseOrders(data);

    return CreateOrderResultModel(
      orderId: _pickString(data, ['OrderId', 'orderId', 'orderid', 'Id', 'id']),
      orderNumber: _pickString(data, ['OrderNumber', 'orderNumber', 'ordernumber']),
      groupId: _pickString(data, ['GroupId', 'groupId', 'groupid']),
      groupNumber: _pickString(data, ['GroupNumber', 'groupNumber', 'groupnumber']),
      totalAmount: _parseDouble(_pickRaw(data, ['TotalAmount', 'totalAmount', 'totalamount'])),
      orders: orders,
    );
  }
}

// ─── Ortak, savunmacı çözümleyiciler ────────────────────────────────────────

/// `Orders[]` alanını okur. Alan yoksa, liste değilse ya da içinde nesne
/// olmayan öğeler varsa boş/eksik liste döner — asla fırlatmaz.
List<OrderModel> _parseOrders(Map<String, dynamic> data) {
  final raw = _pickRaw(data, ['Orders', 'orders']);
  if (raw is! List) return <OrderModel>[];

  final orders = raw
      .whereType<Map>()
      .map((e) => OrderModel.fromJson('', Map<String, dynamic>.from(e)))
      .toList();

  orders.sort((a, b) => (a.groupSeq ?? 0).compareTo(b.groupSeq ?? 0));
  return orders;
}

dynamic _pickRaw(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key) && data[key] != null) return data[key];
  }
  return null;
}

String _pickString(Map<String, dynamic> data, List<String> keys) {
  final value = _pickRaw(data, keys);
  return value == null ? '' : value.toString();
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

/// Backend ödenmemiş grup için `pending` gönderiyor; Flutter enum'unda karşılığı
/// `unpaid`. Bilinmeyen değer `unpaid` sayılır ("ödendi" varsayımı asla yapılmaz).
PaymentStatus _parsePaymentStatus(dynamic value) {
  if (value == null) return PaymentStatus.unpaid;
  var s = value.toString();
  if (s == 'pending') s = 'unpaid';
  return PaymentStatus.values.firstWhere((e) => e.name == s, orElse: () => PaymentStatus.unpaid);
}
