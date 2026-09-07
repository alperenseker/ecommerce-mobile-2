// FAZ 08 — alışveriş (grup) çözümlenmesi ve sepetin şirket kırılımı.
//
// Referans projedeki `test/order_group_split_test.dart` dosyasının hedefe
// taşınmış hâlidir. JSON parçaları **canlı API'den** (2026-08-26,
// `ecom.aycom.kz:5006`) birebir alınmıştır; alan adları ve büyük/küçük harf
// düzeni uydurma değildir. Testlerin ikinci amacı, eski API yanıtıyla da
// çökmemeyi kanıtlamak: kabul kriteri "savunmacı fromJson".
//
// İki beklenti hedefin kararlarına göre DEĞİŞTİ (yerinde işaretli):
//   • grup sırası: alfabetik değil, sepetteki sıra (FAZ 06),
//   • ara toplam: `salePrice` değil `price` (FAZ 05).
import 'package:flutter_test/flutter_test.dart';
import 'package:t_utils/utils/constants/enums.dart';
import 'package:tstore_ecommerce_app/features/shop/models/cart_item_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/order_group_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/order_model.dart';
import 'package:tstore_ecommerce_app/utils/helpers/erp_source_helper.dart';

/// Canlı `GET /api/order/groups/user/{userId}` yanıtındaki ilk grubun kısaltılmış
/// hâli (iki şirketli alışveriş).
Map<String, dynamic> liveGroupJson() => {
      'GroupId': '2240d5bc-2468-4e62-93a1-b1e3ebb1a5be',
      'GroupNumber': 'ORD-20260826-00001',
      'UserId': 'user_00e05f87d7c3',
      'Subtotal': 30967.0,
      'TotalVat': 5574.06,
      'ShippingCost': 0.0,
      'DiscountAmount': 0.0,
      'TotalAmount': 30967.0,
      'PaymentMethod': 'pending_approval',
      'PaymentStatus': 'pending',
      'CouponCode': '',
      'CustomerNote': 'CanBypassPayment aktif - Admin onayı gerekli',
      'CreatedAt': '2026-08-26T06:28:52.386269Z',
      'UpdatedAt': '2026-08-26T06:28:52.386269Z',
      // Sunucu group_seq sırasıyla gönderiyor; test bilerek TERS veriyor ki
      // sıralamayı istemcinin yaptığı doğrulansın.
      'Orders': [
        {
          'OrderId': 'order-2',
          'UserId': 'user_00e05f87d7c3',
          'OrderNumber': 'ORD-20260826-00001-2',
          'Subtotal': 3463.0,
          'TotalVat': 623.34,
          'ShippingCost': 0.0,
          'DiscountAmount': 0.0,
          'TotalAmount': 3463.0,
          'PaymentMethod': 'pending_approval',
          'PaymentStatus': 'pending',
          'OrderStatus': 'pending',
          'CreatedAt': '2026-08-26T06:28:52.386269Z',
          'UpdatedAt': '2026-08-26T06:28:52.386269Z',
          'GroupId': '2240d5bc-2468-4e62-93a1-b1e3ebb1a5be',
          'GroupNumber': 'ORD-20260826-00001',
          'GroupSeq': 2,
          'ErpSourceId': 'erp-fores',
          'ErpSourceCode': 'fores',
          'ErpSourceName': 'Fores',
          'Items': <dynamic>[],
        },
        {
          'OrderId': 'fd3fbabd-e463-4896-b810-2db486e32f1c',
          'UserId': 'user_00e05f87d7c3',
          'OrderNumber': 'ORD-20260826-00001-1',
          'Subtotal': 27504.0,
          'TotalVat': 4950.72,
          'ShippingCost': 0.0,
          'DiscountAmount': 0.0,
          'TotalAmount': 27504.0,
          'PaymentMethod': 'pending_approval',
          'PaymentStatus': 'pending',
          'OrderStatus': 'pending',
          'CreatedAt': '2026-08-26T06:28:52.386269Z',
          'UpdatedAt': '2026-08-26T06:28:52.386269Z',
          'GroupId': '2240d5bc-2468-4e62-93a1-b1e3ebb1a5be',
          'GroupNumber': 'ORD-20260826-00001',
          'GroupSeq': 1,
          'ErpSourceId': 'erp-foral',
          'ErpSourceCode': 'foral',
          'ErpSourceName': 'Foral',
          'Items': <dynamic>[],
        },
      ],
    };

/// Faz 15 öncesi (grubu olmayan) sipariş — canlıda hâlâ üç tane var.
Map<String, dynamic> legacyOrderJson() => {
      'OrderId': 'legacy-1',
      'UserId': 'user_00e05f87d7c3',
      'OrderNumber': 'ORD-20260601-00007',
      'Subtotal': 1000.0,
      'TotalAmount': 1000.0,
      'PaymentMethod': 'card',
      'PaymentStatus': 'paid',
      'OrderStatus': 'delivered',
      'CreatedAt': '2026-06-01T10:00:00Z',
      'UpdatedAt': '2026-06-01T10:00:00Z',
      'Items': <dynamic>[],
    };

void main() {
  group('OrderModel — grup ve şirket alanları', () {
    test('canlı yanıttaki PascalCase alanları okur', () {
      final json = (liveGroupJson()['Orders'] as List)[1] as Map<String, dynamic>;
      final order = OrderModel.fromJson('', json);

      expect(order.id, 'fd3fbabd-e463-4896-b810-2db486e32f1c');
      expect(order.orderNumber, 'ORD-20260826-00001-1');
      expect(order.groupId, '2240d5bc-2468-4e62-93a1-b1e3ebb1a5be');
      expect(order.groupNumber, 'ORD-20260826-00001');
      expect(order.groupSeq, 1);
      expect(order.erpSourceCode, 'foral');
      expect(order.erpSourceName, 'Foral');
      expect(order.companyLabel, 'Foral');
      expect(order.hasCompany, isTrue);
      expect(order.purchaseNumber, 'ORD-20260826-00001');
    });

    test('grup alanları YOKSA çökmez, varsayılana düşer (eski API)', () {
      final order = OrderModel.fromJson('', legacyOrderJson());

      expect(order.groupId, '');
      expect(order.groupNumber, '');
      expect(order.groupSeq, isNull);
      expect(order.erpSourceCode, '');
      expect(order.companyLabel, '');
      expect(order.hasCompany, isFalse, reason: 'şirketi olmayan siparişte ad UYDURULMAZ');
      expect(order.groupOrderCount, isNull);
      expect(order.isPartOfSplitPurchase, isFalse);
      // Grubu yoksa alışveriş numarası sipariş numarasına düşer.
      expect(order.purchaseNumber, 'ORD-20260601-00007');
    });

    test('GroupSeq / GroupOrderCount metin gelirse de okunur', () {
      final order = OrderModel.fromJson('', {
        ...legacyOrderJson(),
        'GroupSeq': '3',
        'GroupOrderCount': '2',
      });

      expect(order.groupSeq, 3);
      expect(order.groupOrderCount, 2);
      expect(order.isPartOfSplitPurchase, isTrue);
    });

    test("enum'da olmayan 'confirmed' durumu gösterimde korunur", () {
      final order = OrderModel.fromJson('', {
        ...legacyOrderJson(),
        'OrderStatus': 'confirmed',
      });

      // Enum karşılığı olmadığı için mantıkta pending'e düşer...
      expect(order.orderStatus, OrderStatus.pending);
      // ...ama ekranda ham değer gösterilir (ödenmiş sipariş "Pending" görünmesin).
      expect(order.statusKey, 'confirmed');
    });

    test("'cancelled' (İngiliz yazımı) enum'a çevrilir", () {
      final order = OrderModel.fromJson('', {
        ...legacyOrderJson(),
        'OrderStatus': 'cancelled',
      });
      expect(order.orderStatus, OrderStatus.canceled);
    });
  });

  group('OrderGroupModel.fromJson', () {
    test('canlı grubu okur ve siparişleri group_seq sırasına dizer', () {
      final group = OrderGroupModel.fromJson(liveGroupJson());

      expect(group.groupNumber, 'ORD-20260826-00001');
      expect(group.totalAmount, 30967.0);
      expect(group.orderCount, 2);
      expect(group.isSplit, isTrue);
      expect(group.hasGroupNumber, isTrue);
      expect(group.displayNumber, 'ORD-20260826-00001');
      // Sunucu 'pending' gönderiyor → Flutter enum'unda 'unpaid'.
      expect(group.paymentStatus, PaymentStatus.unpaid);
      expect(group.isUnpaid, isTrue);
      // Ters sırayla verilmişti; seq'e göre düzeltilmeli.
      expect(group.orders.map((o) => o.groupSeq), [1, 2]);
      expect(group.orders.map((o) => o.companyLabel), ['Foral', 'Fores']);
      // Grubun toplamı, siparişlerin toplamına eşit olmalı (canlı veri).
      expect(group.orders.fold<double>(0, (s, o) => s + o.totalAmount), 30967.0);
    });

    test('Orders alanı yoksa boş listeye düşer, çökmez', () {
      final json = liveGroupJson()..remove('Orders');
      final group = OrderGroupModel.fromJson(json);

      expect(group.orders, isEmpty);
      expect(group.isSplit, isFalse);
      expect(group.displayNumber, 'ORD-20260826-00001');
    });

    test('bomboş nesneden bile kurulur', () {
      final group = OrderGroupModel.fromJson(<String, dynamic>{});
      expect(group.groupId, '');
      expect(group.totalAmount, 0.0);
      expect(group.orders, isEmpty);
      expect(group.paymentStatus, PaymentStatus.unpaid);
      expect(group.hasGroupNumber, isFalse);
    });
  });

  group('OrderGroupModel.fromFlatOrders — grup ucu okunamadığında yedek yol', () {
    test('karışık liste: bölünmüş grup + grubu olmayan eski sipariş', () {
      final orders = [
        OrderModel.fromJson('', (liveGroupJson()['Orders'] as List)[0] as Map<String, dynamic>),
        OrderModel.fromJson('', (liveGroupJson()['Orders'] as List)[1] as Map<String, dynamic>),
        OrderModel.fromJson('', legacyOrderJson()),
      ];

      final groups = OrderGroupModel.fromFlatOrders(orders);

      expect(groups.length, 2, reason: 'bir gerçek grup + bir tek siparişlik eski kayıt');
      // En yeni önce.
      expect(groups.first.groupNumber, 'ORD-20260826-00001');
      expect(groups.first.orderCount, 2);
      expect(groups.first.orders.map((o) => o.groupSeq), [1, 2]);
      expect(groups.first.totalAmount, 30967.0);
      expect(groups.first.paymentStatus, PaymentStatus.unpaid, reason: 'ikisi de ödenmemiş');

      final legacy = groups.last;
      expect(legacy.orderCount, 1);
      expect(legacy.hasGroupNumber, isFalse, reason: 'başlık çizilmemeli');
      expect(legacy.displayNumber, 'ORD-20260601-00007');
      expect(legacy.paymentStatus, PaymentStatus.paid);
    });

    test('grubun tamamı ödendiyse grup da ödenmiş sayılır', () {
      final json = liveGroupJson();
      final orders = (json['Orders'] as List)
          .map((e) => OrderModel.fromJson('', {...e as Map<String, dynamic>, 'PaymentStatus': 'paid'}))
          .toList();

      final groups = OrderGroupModel.fromFlatOrders(orders);
      expect(groups.single.paymentStatus, PaymentStatus.paid);
      expect(groups.single.isUnpaid, isFalse);
    });

    test('kısmi ödeme grubu ödenmiş yapmaz', () {
      final raw = liveGroupJson()['Orders'] as List;
      final orders = [
        OrderModel.fromJson('', {...raw[0] as Map<String, dynamic>, 'PaymentStatus': 'paid'}),
        OrderModel.fromJson('', raw[1] as Map<String, dynamic>),
      ];

      final groups = OrderGroupModel.fromFlatOrders(orders);
      expect(groups.single.paymentStatus, PaymentStatus.unpaid);
    });

    test('boş liste boş sonuç verir', () {
      expect(OrderGroupModel.fromFlatOrders(const []), isEmpty);
    });
  });

  group('CreateOrderResultModel', () {
    test('yeni API: grup + şirket başına sipariş', () {
      final result = CreateOrderResultModel.fromJson({
        'OrderId': 'fd3fbabd-e463-4896-b810-2db486e32f1c',
        'OrderNumber': 'ORD-20260826-00001',
        'GroupId': '2240d5bc-2468-4e62-93a1-b1e3ebb1a5be',
        'GroupNumber': 'ORD-20260826-00001',
        'TotalAmount': 30967.0,
        'Orders': liveGroupJson()['Orders'],
      });

      expect(result.orderCount, 2);
      expect(result.isSplit, isTrue);
      expect(result.purchaseNumber, 'ORD-20260826-00001');
      expect(result.totalAmount, 30967.0);
      expect(result.orders.map((o) => o.displayId),
          ['ORD-20260826-00001-1', 'ORD-20260826-00001-2']);
      // Ödeme doğrulaması grubun ilk siparişinden yapılır.
      expect(result.pollOrderId, 'fd3fbabd-e463-4896-b810-2db486e32f1c');
    });

    test('K7: yalnız eski alanlar gelirse tek siparişlik alışverişe düşer', () {
      final result = CreateOrderResultModel.fromJson({
        'OrderId': 'old-order-id',
        'OrderNumber': 'ORD-20260601-00007',
        'TotalAmount': 1000.0,
      });

      expect(result.groupId, '');
      expect(result.orders, isEmpty);
      expect(result.orderCount, 1);
      expect(result.isSplit, isFalse);
      expect(result.purchaseNumber, 'ORD-20260601-00007');
      expect(result.pollOrderId, 'old-order-id');
    });
  });

  group('TErpSource — şirket adı çözümü', () {
    test('sunucudan gelen ad her şeyin önündedir', () {
      expect(TErpSource.label('fores', 'Fores KZ'), 'Fores KZ');
    });

    test('ad yoksa yerel eşleme kullanılır', () {
      expect(TErpSource.label('fores'), 'Fores');
      expect(TErpSource.label('FORAL'), 'Foral');
      expect(TErpSource.label('  foral  '), 'Foral');
    });

    test('bilinmeyen kod (3. şirket) baş harfi büyütülerek gösterilir', () {
      expect(TErpSource.label('xyz'), 'Xyz');
    });

    test('kod da ad da yoksa BOŞ döner — ad uydurulmaz', () {
      expect(TErpSource.label(null), '');
      expect(TErpSource.label(''), '');
      expect(TErpSource.label('   ', '   '), '');
    });
  });

  group('TErpSource.groupCartItems — sepetin şirket kırılımı', () {
    CartItemModel item(String id, String erpSource, double price, int qty, {double sale = 0}) =>
        CartItemModel(
          productId: id,
          quantity: qty,
          price: price,
          salePrice: sale,
          erpSource: erpSource,
        );

    // 🔴 FAZ 06 kararı: grup sırası ALFABETİK DEĞİL, **sepetteki sıra**
    // (web `data/product-model.js` → `groupByErp`: "ilk görülen şirket önce").
    // Referans testi ada göre sıralamayı bekliyordu; beklenti hedefin
    // kararına göre güncellendi.
    test('şirkete göre kümeler, ara toplamları hesaplar, SEPETTEKİ sırayı korur', () {
      final groups = TErpSource.groupCartItems([
        item('p1', 'fores', 100, 2),
        item('p2', 'foral', 50, 1),
        item('p3', 'FORES', 10, 3),
      ]);

      expect(groups.map((g) => g.name), ['Fores', 'Foral']);
      expect(groups.last.subtotal, 50.0);
      expect(groups.first.subtotal, 100 * 2 + 10 * 3);
      expect(groups.first.items.length, 2, reason: 'büyük/küçük harf aynı kümeye düşmeli');
      expect(groups.first.quantity, 5);
    });

    // 🔴 FAZ 05 kararı: tutar hesabı **daima `price`** üzerinden. Sunucuda
    // `Price` GÜNCEL, `OldPrice` (→ `salePrice`) indirimden ÖNCEKİ fiyattır;
    // referanstaki "salePrice varsa onu kullan" kuralı indirimli üründe
    // müşteriye eski, YÜKSEK fiyatı ödetiyordu.
    test('ara toplam salePrice DEĞİL price üzerinden hesaplanır', () {
      final groups = TErpSource.groupCartItems([item('p1', 'fores', 100, 2, sale: 80)]);
      expect(groups.single.subtotal, 200.0);
    });

    // 🔴 FAZ 06 kararı: şirketi çözülemeyen kalem "Diğer" başlığı altında ve
    // **sırasını koruyarak** görünür. Referans bu kümeyi zorla sona atıyordu;
    // sıra artık sepettekiyle aynı olduğu için küme ilk görüldüğü yerde kalır.
    test('şirketi çözülemeyen kalemler TEK kümede toplanır ve sırasını korur', () {
      final groups = TErpSource.groupCartItems([
        item('p1', '', 10, 1),
        item('p2', 'fores', 20, 1),
        item('p3', '   ', 30, 1),
      ]);

      expect(groups.length, 2);
      expect(groups.first.code, '', reason: 'bilinmeyen küme sepetteki yerinde kalır');
      expect(groups.last.code, 'fores');
      expect(groups.first.items.length, 2, reason: 'boş ve boşluklu kod aynı kümeye düşer');
      expect(groups.first.subtotal, 40.0);
    });

    test('boş sepet boş liste verir', () {
      expect(TErpSource.groupCartItems(const []), isEmpty);
    });
  });

  group('CartItemModel — şirket kodu taşıma', () {
    test('sipariş kaleminin snapshot metninden erpSource okunur', () {
      final item = CartItemModel.fromOrderItem({
        'OrderItemId': 'oi-1',
        'ProductId': 'p-1',
        'Quantity': 2,
        'UnitPrice': 718,
        // Canlı `order_items.productsnapshot` biçimi.
        'ProductSnapshot':
            '{"name": "СО Угловая передача", "slug": "so-uglovaya", "price": 718, '
                '"currency": "KZT", "erpSource": "fores", "mainImage": "https://x/y.jpg"}',
      });

      expect(item.erpSource, 'fores');
      expect(item.title, 'СО Угловая передача');
      expect(item.quantity, 2);
    });

    test('snapshot bozuksa/yoksa erpSource boş kalır, kalem yine okunur', () {
      final broken = CartItemModel.fromOrderItem({
        'ProductId': 'p-1',
        'Quantity': 1,
        'UnitPrice': 100,
        'ProductSnapshot': '{bozuk json',
      });
      expect(broken.erpSource, '');
      expect(broken.productId, 'p-1');

      final missing = CartItemModel.fromOrderItem({
        'ProductId': 'p-2',
        'Quantity': 1,
        'UnitPrice': 100,
      });
      expect(missing.erpSource, '');
    });

    test('yerel depodaki eski sepet kaydında anahtar yoksa boş kalır', () {
      final item = CartItemModel.fromJson({
        'productId': 'p-1',
        'title': 'X',
        'price': 10.0,
        'salePrice': 0.0,
        'quantity': 1,
      });
      expect(item.erpSource, '');
    });

    test('erpSource yerel depoya yazılıp geri okunur', () {
      final original = CartItemModel(productId: 'p-1', quantity: 1, erpSource: 'foral');
      final restored = CartItemModel.fromJson(original.toJson());
      expect(restored.erpSource, 'foral');
    });
  });
}
