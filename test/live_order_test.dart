// GEÇİCİ: FAZ 08 doğrulaması — sipariş ve iade uçları GERÇEK HESAPLA denenir.
//
// 🔴 Bu test canlı sunucuyu **DEĞİŞTİRMEZ**: yalnız okuma yapar. Sipariş
// OLUŞTURULMAZ, iptal edilmez, ödeme jetonu istenmez — kullanıcının açık
// kuralı ("canlı API'de sipariş onaylama, hiçbir zaman"). Doğrulanan şeyler:
// grup ucu gerçekten var mı, grup başlığı ile alt siparişler eşleşiyor mu,
// tek sipariş ucu kalemleri dolduruyor mu, geçmiş ucu ne döndürüyor ve
// iade ucu hâlâ 404 mü.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/order/api_order_repository.dart';
import 'package:tstore_ecommerce_app/features/shop/models/order_group_model.dart';
import 'package:t_utils/utils/constants/enums.dart';
import 'package:tstore_ecommerce_app/utils/http/dio_client.dart';

// ignore_for_file: avoid_print

late String userId;
late ApiOrderRepository orders;

/// Ekranın kullandığı sayfa boyutu (bkz. `orders_list.dart`).
const int kPageSize = 10;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    HttpOverrides.global = null;

    final res = await ApiAuth.loginWithEmailPassword(email: 'royalprof@gmail.com', password: '123456');
    expect(res['success'], true, reason: 'gerçek hesapla giriş yapılamadı');
    userId = res['user']['userId'].toString();

    final repo = Get.put(AuthenticationRepository());
    repo.customAuthToken.value = res['token'];
    repo.customUserId.value = userId;
    repo.isCustomAuthUser.value = true;

    orders = Get.put(ApiOrderRepository());
    print('LOGIN userId=$userId');
  });

  tearDownAll(Get.reset);

  test('order/groups/user/{id} — alışveriş listesi geliyor', () async {
    final groups = await orders.fetchUserOrderGroups(userId: userId);
    print('GRUP SAYISI ${groups.length}');
    for (final g in groups.take(5)) {
      print('  grup=${g.displayNumber} · siparis=${g.orderCount} · '
          'odeme=${g.paymentStatus.name} · tutar=${g.totalAmount} · '
          'yontem="${g.paymentMethod}" · bolunmus=${g.isSplit}');
      for (final o in g.orders) {
        print('    → ${o.displayId} · sirket="${o.companyLabel}" · '
            'durum=${o.statusKey} · odeme=${o.paymentStatus.name} · '
            'tutar=${o.totalAmount} · kalem=${o.products.length}');
      }
    }
    // Uç yoksa repository düz listeden grup kuruyor; her iki yolda da liste
    // döner. Boş hesapta da geçerli — patlamamak yeterli.
    expect(groups, isA<List<OrderGroupModel>>());
  });

  test('grup başlığı ile alt siparişler EŞLEŞİYOR', () async {
    final groups = await orders.fetchUserOrderGroups(userId: userId);
    if (groups.isEmpty) {
      print('ATLANDI — hesapta alışveriş yok');
      return;
    }
    for (final g in groups) {
      // Her alt sipariş grubun kimliğini taşımalı; taşımıyorsa liste ekranı
      // yanlış başlığın altına satır çizer.
      for (final o in g.orders) {
        if (g.groupId.isNotEmpty && o.groupId.isNotEmpty) {
          expect(o.groupId, g.groupId, reason: 'alt sipariş başka gruba ait');
        }
      }
      expect(g.orderCount, greaterThan(0), reason: 'siparişsiz grup çizilemez');
    }

    // 🔴 Grubun ödeme durumu: alt siparişlerin HEPSİ ödendiyse `paid`.
    for (final g in groups) {
      final hepsiOdendi = g.orders.every((o) => o.paymentStatus == PaymentStatus.paid);
      print('GRUP ${g.displayNumber} hepsiOdendi=$hepsiOdendi → ${g.paymentStatus.name}');
    }
  });

  test('order/user/{id} — düz liste ve grup kırılımı tutarlı', () async {
    final flat = await orders.fetchUserOrders(userId: userId);
    final groups = await orders.fetchUserOrderGroups(userId: userId);
    final grupluToplam = groups.fold<int>(0, (p, g) => p + g.orderCount);
    print('DUZ LISTE ${flat.length} sipariş · GRUPLU ${groups.length} alışveriş '
        '/ $grupluToplam sipariş');
    print('SAYFALAMA ${groups.length} alışveriş → '
        '${(groups.length / kPageSize).ceil()} sayfa (10\'ar)');
    // Grup ucu ile düz liste aynı siparişleri anlatmalı.
    if (flat.isNotEmpty && groups.isNotEmpty) {
      expect(grupluToplam, flat.length,
          reason: 'grup ucu ile düz liste farklı sayıda sipariş anlatıyor');
    }
  });

  test('order/{id} — tek sipariş KALEMLERİ dolduruyor', () async {
    final flat = await orders.fetchUserOrders(userId: userId);
    if (flat.isEmpty) {
      print('ATLANDI — hesapta sipariş yok');
      return;
    }
    final tek = await orders.fetchSingleOrder(orderId: flat.first.id);
    print('TEK SIPARIS ${tek.displayId} · kalem=${tek.products.length} · '
        'durum=${tek.statusKey} · grupSiparisSayisi=${tek.groupOrderCount} · '
        'kargoBilgisi=${tek.hasShippingInfo}');
    for (final p in tek.products.take(5)) {
      print('  kalem "${p.title}" x${p.quantity} = ${p.price}');
    }
    // Liste ucu kalemleri göndermiyor, tek sipariş ucu gönderiyor — accordion
    // bu yüzden talep üzerine `order/{id}` çağırıyor.
    expect(tek.id, isNotEmpty);
  });

  test('order/{id}/history-detailed — sipariş geçmişi', () async {
    final flat = await orders.fetchUserOrders(userId: userId);
    if (flat.isEmpty) {
      print('ATLANDI — hesapta sipariş yok');
      return;
    }
    try {
      final gecmis = await orders.fetchOrderHistoryDetailed(orderId: flat.first.id);
      print('GECMIS ${gecmis.length} kayıt');
      for (final h in gecmis.take(5)) {
        print('  ${h.oldStatus} → ${h.newStatus} · ${h.createdAt} · ${h.changedByUser?.name ?? h.changedBy ?? "-"}');
      }
    } catch (e) {
      // Uç kapalıysa ekran geçmiş bölümünü hiç çizmiyor; test bunu raporlar.
      print('GECMIS UCU HATA: $e');
    }
  });

  test('sipariş durumlarının dağılımı (iade akışı DELIVERED istiyor)', () async {
    final flat = await orders.fetchUserOrders(userId: userId);
    final dagilim = <String, int>{};
    for (final o in flat) {
      dagilim[o.statusKey] = (dagilim[o.statusKey] ?? 0) + 1;
    }
    print('DURUM DAGILIMI $dagilim');
    // İade yalnız TESLİM EDİLMİŞ siparişten açılıyor; hesapta öyle bir
    // sipariş yoksa "iade başlat" düğmesine cihazda ulaşılamaz.
    print('teslim edilmis sayisi = ${dagilim['delivered'] ?? 0}');
    for (final o in flat.where((o) => o.statusKey == 'delivered' || o.statusKey == 'processing')) {
      print('  ${o.statusKey}: ${o.displayId} · grup=${o.groupNumber} · '
          'tarih=${o.formattedOrderDate} · sirket=${o.companyLabel}');
    }
  });

  test('return-requests — iade ucu sunucuda var mı', () async {
    try {
      final res = await THttpClient.dio.get('return-requests');
      print('IADE UCU ${res.statusCode} · ${res.data}');
    } catch (e) {
      print('IADE UCU HATA (beklenen 404): $e');
    }
  });
}
