// FAZ 12 — fiyatı gizli ürünlerin CANLI API yanıtıyla doğrulanması.
//
// Referans projedeki `test/price_hidden_test.dart` dosyasının hedefe taşınmış
// hâlidir (FAZ 04 + 05'ten devreden borç, DURUM.md).
//
// Veri: `test/fixtures/live_products.json` =
// `GET /api/products?pageSize=20000&isActive=true` (misafir) yanıtının aynısı.
// Sunucu fiyatı gizli üründe `Price: 0` gönderiyor; ham karşılaştırma bunları
// "ucuzdan pahalıya" sıralamasında en BAŞA yığar ve katalog sıfır fiyatlı
// ürünlerle açılır. Kural: **yön ne olursa olsun fiyatsızlar sona gider.**
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_model.dart';

void main() {
  final raw = File('test/fixtures/live_products.json').readAsStringSync();
  final rows = (jsonDecode(raw)['Data'] as List).cast<Map<String, dynamic>>();
  final products =
      rows.map((j) => ProductModel.fromJson(j['ProductId'].toString(), j)).toList();

  test('canlı yanıt ProductModel e sorunsuz çözülüyor', () {
    expect(products.length, rows.length);
    expect(products.length, greaterThan(0));
  });

  test('fiyatı gizli ürünler doğru işaretleniyor', () {
    final hidden = products.where((p) => p.isPriceHidden).toList();
    final shown = products.where((p) => !p.isPriceHidden).toList();

    // Gizli olanların hepsi Price 0 taşımalı (sunucu böyle gönderiyor).
    expect(hidden.every((p) => p.price == 0), isTrue);
    // Fiyatlıların hiçbiri 0 olmamalı.
    expect(shown.every((p) => p.price > 0), isTrue);
    expect(hidden, isNotEmpty);
  });

  test('fiyata göre sıralamada fiyatsızlar HER ZAMAN sona gider', () {
    // Uygulamadaki karşılaştırıcının aynısı:
    // `StoreController._comparePrice` ve `AllProductsController` içinde.
    // Kural değişirse üç yer birlikte değişmeli.
    int comparePrice(ProductModel a, ProductModel b, {required bool ascending}) {
      if (a.isPriceHidden != b.isPriceHidden) return a.isPriceHidden ? 1 : -1;
      if (a.isPriceHidden) return 0;
      return ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price);
    }

    for (final asc in [true, false]) {
      final sorted = [...products]..sort((a, b) => comparePrice(a, b, ascending: asc));
      final firstHidden = sorted.indexWhere((p) => p.isPriceHidden);
      final shownCount = products.where((p) => !p.isPriceHidden).length;

      // İlk gizli ürün, tüm fiyatlılardan SONRA gelmeli.
      expect(firstHidden, shownCount,
          reason: asc ? 'ucuzdan pahalıya' : 'pahalıdan ucuza');
      // Ondan sonrasının tamamı gizli olmalı.
      expect(sorted.sublist(firstHidden).every((p) => p.isPriceHidden), isTrue);
    }
  });
}
