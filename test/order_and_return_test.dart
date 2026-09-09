// FAZ 08 — sipariş listesi/detayı ve iade ekranlarının kuralları.
//
// Referans projede `test/` klasörü VAR (4 dosya); bu dosya FAZ 08 kapsamının
// kurallarını kalıcı olarak sabitler. Kalanlar için bkz. DURUM.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_utils/utils/constants/enums.dart';

import 'package:tstore_ecommerce_app/features/shop/models/order_group_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/order_model.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/order/order_detail/widgets/delivery_status.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/order/order_detail/widgets/payment_details.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/order/widgets/order_badges.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/order/widgets/order_payment_gate.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/return_request/widgets/return_status_badge.dart';
import 'package:tstore_ecommerce_app/utils/constants/enums.dart' as app_enums;

Map<String, dynamic> orderJson({
  required String id,
  String groupId = 'G1',
  String groupNumber = 'ORD-20260904-00001',
  int groupSeq = 1,
  String status = 'pending',
  String paymentStatus = 'pending',
  String paymentMethod = 'card',
  double total = 1000,
  String erp = 'fores',
  Map<String, dynamic> extra = const {},
}) =>
    {
      'OrderId': id,
      'OrderNumber': 'ORD-$id',
      'UserId': 'U1',
      'GroupId': groupId,
      'GroupNumber': groupNumber,
      'GroupSeq': groupSeq,
      'ErpSourceCode': erp,
      'OrderStatus': status,
      'PaymentStatus': paymentStatus,
      'PaymentMethod': paymentMethod,
      'TotalAmount': total,
      'Subtotal': total,
      'CreatedAt': '2026-09-04T10:00:00Z',
      ...extra,
    };

Widget wrap(Widget child) => GetMaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('Ödeme kapısı — "ödemeyi tamamla"', () {
    test('transfer_only modunda ASLA çizilmez (uç 409 döner)', () {
      expect(
        canCompleteCardPayment(
          transferOnly: true,
          paymentMethod: 'card',
          paymentStatus: PaymentStatus.unpaid,
          amount: 1000,
        ),
        isFalse,
      );
    });

    test('gateway + kart + ödenmemiş → çizilir', () {
      expect(
        canCompleteCardPayment(
          transferOnly: false,
          paymentMethod: 'card',
          paymentStatus: PaymentStatus.unpaid,
          amount: 1000,
        ),
        isTrue,
      );
    });

    test('ödenmiş / iade edilmiş siparişte çizilmez', () {
      for (final s in [PaymentStatus.paid, PaymentStatus.refunded]) {
        expect(
          canCompleteCardPayment(
            transferOnly: false,
            paymentMethod: 'card',
            paymentStatus: s,
            amount: 1000,
          ),
          isFalse,
          reason: '$s',
        );
      }
    });

    test('havale / boş yöntemde çizilmez, credit_card kabul edilir', () {
      expect(
        canCompleteCardPayment(
            transferOnly: false, paymentMethod: 'bank_transfer', paymentStatus: PaymentStatus.unpaid, amount: 10),
        isFalse,
      );
      expect(
        canCompleteCardPayment(
            transferOnly: false, paymentMethod: '', paymentStatus: PaymentStatus.unpaid, amount: 10),
        isFalse,
      );
      expect(
        canCompleteCardPayment(
            transferOnly: false, paymentMethod: 'credit_card', paymentStatus: PaymentStatus.unpaid, amount: 10),
        isTrue,
      );
    });

    test('tutar 0 ya da sipariş iptal ise çizilmez', () {
      expect(
        canCompleteCardPayment(
            transferOnly: false, paymentMethod: 'card', paymentStatus: PaymentStatus.unpaid, amount: 0),
        isFalse,
      );
      expect(
        canCompleteCardPayment(
          transferOnly: false,
          paymentMethod: 'card',
          paymentStatus: PaymentStatus.unpaid,
          amount: 100,
          isCanceled: true,
        ),
        isFalse,
      );
    });
  });

  group('Havale rekvizitleri kapısı', () {
    test('transfer_only modunda kart siparişinde bile gösterilir', () {
      expect(
        shouldShowBankDetails(
            transferOnly: true, paymentMethod: 'card', paymentStatus: PaymentStatus.unpaid),
        isTrue,
      );
    });

    test('havale ve kredili (pending_approval) siparişte gösterilir', () {
      for (final m in ['bank_transfer', 'pending_approval']) {
        expect(
          shouldShowBankDetails(
              transferOnly: false, paymentMethod: m, paymentStatus: PaymentStatus.unpaid),
          isTrue,
          reason: m,
        );
      }
    });

    test('ödenmiş, iade edilmiş ya da iptal siparişte gösterilmez', () {
      expect(
        shouldShowBankDetails(
            transferOnly: true, paymentMethod: 'bank_transfer', paymentStatus: PaymentStatus.paid),
        isFalse,
      );
      expect(
        shouldShowBankDetails(
            transferOnly: true, paymentMethod: 'bank_transfer', paymentStatus: PaymentStatus.refunded),
        isFalse,
      );
      expect(
        shouldShowBankDetails(
          transferOnly: true,
          paymentMethod: 'bank_transfer',
          paymentStatus: PaymentStatus.unpaid,
          isCanceled: true,
        ),
        isFalse,
      );
    });
  });

  group('Grup kurma (yedek yol: düz listeden)', () {
    test('aynı GroupId iki sipariş TEK gruba toplanır, tutarlar toplanır', () {
      final orders = [
        OrderModel.fromJson('', orderJson(id: 'b', groupSeq: 2, total: 1000, erp: 'foral')),
        OrderModel.fromJson('', orderJson(id: 'a', groupSeq: 1, total: 1250, erp: 'fores')),
      ];
      final groups = OrderGroupModel.fromFlatOrders(orders);

      expect(groups.length, 1);
      expect(groups.first.orderCount, 2);
      expect(groups.first.isSplit, isTrue);
      expect(groups.first.totalAmount, 2250);
      // group_seq sırası korunur
      expect(groups.first.orders.map((o) => o.erpSourceCode).toList(), ['fores', 'foral']);
    });

    test('grup ödeme durumu: HEPSİ ödendiyse paid', () {
      final groups = OrderGroupModel.fromFlatOrders([
        OrderModel.fromJson('', orderJson(id: 'a', groupSeq: 1, paymentStatus: 'paid')),
        OrderModel.fromJson('', orderJson(id: 'b', groupSeq: 2, paymentStatus: 'paid')),
      ]);
      expect(groups.first.paymentStatus, PaymentStatus.paid);
    });

    test('biri ödenmemişse grup ödenmemiş sayılır', () {
      final groups = OrderGroupModel.fromFlatOrders([
        OrderModel.fromJson('', orderJson(id: 'a', groupSeq: 1, paymentStatus: 'paid')),
        OrderModel.fromJson('', orderJson(id: 'b', groupSeq: 2, paymentStatus: 'pending')),
      ]);
      expect(groups.first.paymentStatus, PaymentStatus.unpaid);
      expect(groups.first.isUnpaid, isTrue);
    });

    test('alışverişin TAMAMI iptalse grup iptal sayılır, biri ayaktaysa sayılmaz', () {
      final hepsiIptal = OrderGroupModel.fromFlatOrders([
        OrderModel.fromJson('', orderJson(id: 'a', groupSeq: 1, status: 'cancelled')),
        OrderModel.fromJson('', orderJson(id: 'b', groupSeq: 2, status: 'cancelled')),
      ]).first;
      expect(hepsiIptal.isCanceled, isTrue);
      // 🔴 gateway modunda bile iptal edilmiş KART alışverişinde düğme yok.
      expect(canCompleteCardPayment(
        transferOnly: false,
        paymentMethod: hepsiIptal.paymentMethod,
        paymentStatus: hepsiIptal.paymentStatus,
        amount: hepsiIptal.totalAmount,
        isCanceled: hepsiIptal.isCanceled,
      ), isFalse);
      // İptal alışverişte rekvizitler de çizilmez.
      expect(shouldShowBankDetails(
        transferOnly: true,
        paymentMethod: hepsiIptal.paymentMethod,
        paymentStatus: hepsiIptal.paymentStatus,
        isCanceled: hepsiIptal.isCanceled,
      ), isFalse);

      final biriAyakta = OrderGroupModel.fromFlatOrders([
        OrderModel.fromJson('', orderJson(id: 'a', groupSeq: 1, status: 'cancelled')),
        OrderModel.fromJson('', orderJson(id: 'b', groupSeq: 2, status: 'pending')),
      ]).first;
      expect(biriAyakta.isCanceled, isFalse);
      expect(canCompleteCardPayment(
        transferOnly: false,
        paymentMethod: biriAyakta.paymentMethod,
        paymentStatus: biriAyakta.paymentStatus,
        amount: biriAyakta.totalAmount,
        isCanceled: biriAyakta.isCanceled,
      ), isTrue);
    });

    test('grubu olmayan eski sipariş kendi başına tek siparişlik alışveriş olur', () {
      final groups = OrderGroupModel.fromFlatOrders([
        OrderModel.fromJson('', orderJson(id: 'a', groupId: '', groupNumber: '')),
        OrderModel.fromJson('', orderJson(id: 'b', groupId: '', groupNumber: '')),
      ]);
      expect(groups.length, 2);
      expect(groups.every((g) => !g.isSplit), isTrue);
      expect(groups.first.hasGroupNumber, isFalse);
    });
  });

  group('Sipariş modeli — kargo bilgisi (FAZ 08 eklentisi)', () {
    test('sunucu doldurmadıysa hasShippingInfo false', () {
      final order = OrderModel.fromJson('', orderJson(id: 'a'));
      expect(order.hasShippingInfo, isFalse);
      expect(order.shippingCompany, '');
      expect(order.trackingNumber, '');
      expect(order.deliveredAt, isNull);
    });

    test('kök alanlar ayrıştırılır', () {
      final order = OrderModel.fromJson(
        '',
        orderJson(id: 'a', extra: {
          'ShippingCompany': 'KazPost',
          'TrackingNumber': 'KZ123456789',
          'ShippedAt': '2026-09-05T08:00:00Z',
          'DeliveredAt': '2026-09-07T14:30:00Z',
        }),
      );
      expect(order.hasShippingInfo, isTrue);
      expect(order.shippingCompany, 'KazPost');
      expect(order.trackingNumber, 'KZ123456789');
      expect(order.shippingDate, isNotNull);
      expect(order.deliveredAt, isNotNull);
    });
  });

  group('Durum sözlüğü', () {
    test('confirmed enum\'da yok ama HAM durum korunur', () {
      final order = OrderModel.fromJson('', orderJson(id: 'a', status: 'confirmed'));
      // Enum'a çevrilince pending'e düşüyor…
      expect(order.orderStatus, OrderStatus.pending);
      // …ama gösterimde ham değer kullanılıyor.
      expect(order.statusKey, 'confirmed');
      expect(kOrderFlow.contains(order.statusKey), isTrue);
    });

    test('bilinmeyen durum uydurulmaz, ham hâliyle döner', () {
      expect(orderStatusLabel('weird_status'), 'weird_status');
    });

    test('iade talebi kısa kimliği 8 karakterden kısa kimlikte ÇÖKMEZ', () {
      expect(returnRequestShortId('abc'), 'abc');
      expect(returnRequestShortId('0123456789'), '01234567');
    });
  });

  group('Durum çubuğu', () {
    testWidgets('akıştaki durumda beş adım da çizilir', (tester) async {
      await tester.pumpWidget(wrap(const TOrderFlowBar(status: 'shipped')));
      await tester.pump();

      for (final step in kOrderFlow) {
        expect(find.text(orderStatusLabel(step)), findsOneWidget, reason: step);
      }
      // Tek durum satırı (iptal/iade görünümü) çizilmemeli
      expect(find.byType(OrderStatusTile), findsNothing);
    });

    testWidgets('iptal/iade durumunda çubuk ÇİZİLMEZ', (tester) async {
      for (final status in ['cancelled', 'refunded', 'returned']) {
        await tester.pumpWidget(wrap(TOrderFlowBar(status: status)));
        await tester.pump();

        expect(find.byType(OrderStatusTile), findsOneWidget, reason: status);
        // Akış etiketlerinden hiçbiri görünmemeli
        expect(find.text(orderStatusLabel('processing')), findsNothing, reason: status);
      }
    });
  });

  group('Ödeme özeti', () {
    testWidgets('kargo bedeli 0 iken "ücretsiz" yazar, vergi satırı çizilmez', (tester) async {
      final order = OrderModel.fromJson('', orderJson(id: 'a', total: 1250));
      await tester.pumpWidget(wrap(PaymentDetail(order: order)));
      await tester.pump();

      expect(find.text('free'), findsOneWidget);
      expect(find.text('taxAmount'), findsNothing);
      // Yöntem etiketi kart olarak çözülüyor
      expect(find.text('creditCard'), findsOneWidget);
    });

    testWidgets('indirim varsa satır çizilir', (tester) async {
      final order = OrderModel.fromJson(
        '',
        orderJson(id: 'a', total: 900, extra: {'DiscountAmount': 100, 'ShippingCost': 500}),
      );
      await tester.pumpWidget(wrap(PaymentDetail(order: order)));
      await tester.pump();

      expect(find.text('discount'), findsOneWidget);
      expect(find.text('free'), findsNothing);
    });
  });

  group('İade sözlüğü', () {
    test('her durum/tür/sebep için etiket var ve boş değil', () {
      for (final s in app_enums.ReturnStatus.values) {
        expect(returnStatusLabel(s).isNotEmpty, isTrue, reason: '$s');
      }
      for (final t in app_enums.ReturnType.values) {
        expect(returnTypeLabel(t).isNotEmpty, isTrue, reason: '$t');
      }
      for (final r in app_enums.ReturnReason.values) {
        expect(returnReasonLabel(r).isNotEmpty, isTrue, reason: '$r');
      }
    });
  });
}
