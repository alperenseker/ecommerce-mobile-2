// GEÇİCİ: FAZ 06 doğrulaması — sepet · favori · karşılaştırma uçları GERÇEK
// HESAPLA denenir. Faz sonunda silinecek.
//
// 🔴 Bu test canlı sunucuyu DEĞİŞTİRİR (sepete kalem ekler, favori/karşılaştırma
// listesine ürün koyar). Bu yüzden her adım kendi temizliğini yapar: test
// başındaki sepet/favori/karşılaştırma durumu kaydedilir ve sonunda YALNIZ bu
// testin eklediği kayıtlar geri alınır. Sipariş oluşturulmaz.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/cart/api_cart_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/compare/api_compare_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/product/api_products_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/wishlist/api_wishlist_repository.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_model.dart';
import 'package:tstore_ecommerce_app/utils/helpers/erp_source_helper.dart';

// ignore_for_file: avoid_print

late String userId;
List<ProductModel> catalog = <ProductModel>[];

/// Bu testin sunucuya eklediği kayıtlar; sonunda tek tek geri alınır.
///
/// 🔴 Sepet için kalem kimliği DEĞİL **ürün kimliği** tutuluyor: "boşalt +
/// yedekten geri koy" adımı kalemleri yeniden yaratıyor ve kalem kimlikleri
/// değişiyor; kimliğe bakan bir temizlik, testin eklediği kalemi kullanıcının
/// sepetinde bırakırdı.
final addedCartProductIds = <String>{};
final addedCartItemIds = <String>{};
final addedWishlistItemIds = <String>{};
final addedCompareItemIds = <String>{};

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

    // Dio interceptor jetonu repository'den okuyor.
    final repo = Get.put(AuthenticationRepository());
    repo.customAuthToken.value = res['token'];
    repo.customUserId.value = userId;
    repo.isCustomAuthUser.value = true;

    Get.put(ApiProductRepository());
    Get.put(ApiCartRepository());
    Get.put(ApiWishlistRepository());
    Get.put(ApiCompareRepository());

    catalog = await ApiProductRepository.instance.fetchAllItems();
    print('LOGIN userId=$userId · katalog=${catalog.length} ürün');
  });

  tearDownAll(() async {
    // --- TEMİZLİK: yalnız bu testin eklediklerini geri al ---
    // Sepette kalem kimlikleri değişmiş olabilir; ürün kimliğinden bul.
    final cart = await ApiCartRepository.instance.fetchUserCart(userId) ?? [];
    var removed = 0;
    for (final item in cart) {
      if (addedCartProductIds.contains(item.productId) && item.cartItemId != null) {
        await ApiCartRepository.instance.removeItem(item.cartItemId!);
        removed++;
      }
    }
    for (final id in addedWishlistItemIds) {
      await ApiWishlistRepository.instance.removeFromWishlist(id);
    }
    for (final id in addedCompareItemIds) {
      await ApiCompareRepository.instance.removeFromCompare(id);
    }
    print('TEMIZLIK sepet=$removed favori=${addedWishlistItemIds.length} karsilastirma=${addedCompareItemIds.length} kayıt geri alındı');
    final son = await ApiCartRepository.instance.fetchUserCart(userId) ?? [];
    print('TEMIZLIK_SONRASI_SEPET ${son.length} kalem: ${son.map((i) => "${i.title}×${i.quantity}").join(" · ")}');
  });

  test('katalogda iki farklı şirketin (erpSource) ürünü var', () {
    final bySource = <String, List<ProductModel>>{};
    for (final p in catalog) {
      bySource.putIfAbsent(TErpSource.normalizeCode(p.erpSource), () => []).add(p);
    }
    print('ERPSOURCE ${bySource.map((k, v) => MapEntry(k.isEmpty ? '(boş)' : k, v.length))}');
    expect(bySource.keys.where((k) => k.isNotEmpty).length, greaterThanOrEqualTo(2));
  });

  test('Cart/user/{id} — gerçek jetonla okunuyor (401 DEĞİL)', () async {
    final items = await ApiCartRepository.instance.fetchUserCart(userId);
    expect(items, isNotNull, reason: 'sepet okunamadı (jeton/uç sorunu)');
    print('CART_GET kalem=${items!.length}');
    for (final i in items) {
      print('  · ${i.title} ×${i.quantity} · ₸${i.price} · erp=${i.erpSource} · id=${i.cartItemId}');
    }
  });

  test('Cart/add · update-quantity · remove — iki şirketten birer ürün', () async {
    // Farklı iki şirketten, fiyatı görünen ve stokta olan birer ürün seç.
    final bySource = <String, ProductModel>{};
    for (final p in catalog) {
      final code = TErpSource.normalizeCode(p.erpSource);
      if (code.isEmpty || bySource.containsKey(code)) continue;
      if (p.isPriceHidden || !p.isInStock) continue;
      bySource[code] = p;
    }
    expect(bySource.length, greaterThanOrEqualTo(2), reason: 'iki şirketten uygun ürün bulunamadı');

    final picks = bySource.entries.take(2).toList();
    final beforeIds = ((await ApiCartRepository.instance.fetchUserCart(userId)) ?? [])
        .map((e) => e.cartItemId)
        .whereType<String>()
        .toSet();

    for (final pick in picks) {
      final items = await ApiCartRepository.instance.addToCart(
        userId: userId,
        productId: pick.value.id,
        quantity: 1,
      );
      expect(items, isNotEmpty, reason: '${pick.key} ürünü sepete eklenemedi');
      addedCartProductIds.add(pick.value.id);
      print('CART_ADD ${pick.key} · ${pick.value.title} → sepet ${items.length} kalem');
      for (final i in items) {
        if (i.cartItemId != null && !beforeIds.contains(i.cartItemId)) {
          addedCartItemIds.add(i.cartItemId!);
        }
      }
    }

    // --- Miktar değiştirme ---
    final cart = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    final mine = cart.firstWhere((i) => addedCartItemIds.contains(i.cartItemId));
    final updated = await ApiCartRepository.instance.updateQuantity(cartItemId: mine.cartItemId!, quantity: 3);
    expect(updated, isNotEmpty);
    final after = (await ApiCartRepository.instance.fetchUserCart(userId))!
        .firstWhere((i) => i.cartItemId == mine.cartItemId);
    print('CART_QTY ${mine.title}: ${mine.quantity} → ${after.quantity}');
    expect(after.quantity, 3);

    // --- Şirkete göre gruplama, GERÇEK sepet kalemleriyle ---
    final groups = TErpSource.groupCartItems(after.erpSource.isEmpty ? cart : (await ApiCartRepository.instance.fetchUserCart(userId))!);
    print('GRUPLAMA ${groups.length} grup:');
    for (final g in groups) {
      print('  · ${g.name} (${g.code.isEmpty ? "çözülemedi" : g.code}) · ${g.items.length} kalem · ara toplam ₸${g.subtotal.toStringAsFixed(2)}');
    }
    expect(groups.length, greaterThanOrEqualTo(2), reason: 'iki şirketin ürünü tek grupta toplanmış');

    // Grup sırası SEPETTEKİ sıra olmalı (alfabetik değil).
    final serverCart = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    final firstSeen = <String>[];
    for (final item in serverCart) {
      final code = TErpSource.normalizeCode(item.erpSource);
      if (!firstSeen.contains(code)) firstSeen.add(code);
    }
    expect(groups.map((g) => g.code).toList(), firstSeen, reason: 'grup sırası sepetteki sıra değil');

    // Ara toplam `price` üzerinden (salePrice DEĞİL).
    for (final g in groups) {
      final expected = g.items.fold(0.0, (s, i) => s + i.price * i.quantity);
      expect(g.subtotal, closeTo(expected, 0.001));
    }

    // --- Kaldırma ---
    final removeId = addedCartItemIds.first;
    await ApiCartRepository.instance.removeItem(removeId);
    final afterRemove = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    expect(afterRemove.any((i) => i.cartItemId == removeId), isFalse);
    addedCartItemIds.remove(removeId);
    print('CART_REMOVE kalem silindi → sepet ${afterRemove.length} kalem');
  });

  test('Wishlist — ekle · listele · kaldır', () async {
    final product = catalog.firstWhere((p) => p.isInStock && !p.isPriceHidden);
    final before = await ApiWishlistRepository.instance.fetchDefaultWishlistItems(userId);
    print('WISHLIST_GET ${before.length} ürün');

    if (before.containsKey(product.id)) {
      print('WISHLIST ürün zaten listede, ekleme atlandı');
      return;
    }

    final itemId = await ApiWishlistRepository.instance.addToWishlist(userId: userId, productId: product.id);
    expect(itemId, isNotNull, reason: 'favoriye eklenemedi');
    addedWishlistItemIds.add(itemId!);
    final after = await ApiWishlistRepository.instance.fetchDefaultWishlistItems(userId);
    print('WISHLIST_ADD ${product.title} → ${after.length} ürün');
    expect(after.containsKey(product.id), isTrue);

    final ok = await ApiWishlistRepository.instance.removeFromWishlist(itemId);
    expect(ok, isTrue);
    addedWishlistItemIds.remove(itemId);
    final afterRemove = await ApiWishlistRepository.instance.fetchDefaultWishlistItems(userId);
    print('WISHLIST_REMOVE → ${afterRemove.length} ürün');
    expect(afterRemove.containsKey(product.id), isFalse);
  });

  test('Compare — 4 ürün kabul, 5. ürün REDDEDİLİYOR (ignoreCategory: true)', () async {
    var state = await ApiCompareRepository.instance.fetchUserComparison(userId);
    print('COMPARE_GET id=${state.comparisonId} · ${state.items.length} ürün');

    // Listede yer kalsın diye önce mevcut durumu okuyup boş yer sayısını bul.
    final candidates = catalog.where((p) => !state.items.any((i) => i.productId == p.id)).toList();
    var comparisonId = state.comparisonId ?? '';

    // Sunucu sınırına DAYANANA kadar ekle; hepsi bu testin eklediği kayıt.
    String? lastMessage;
    var accepted = 0;
    for (final product in candidates.take(6)) {
      final res = await ApiCompareRepository.instance.addToCompare(
        userId: userId,
        productId: product.id,
        comparisonId: comparisonId,
        categoryId: product.categoryId,
      );
      if (res.success) {
        accepted++;
        state = await ApiCompareRepository.instance.fetchUserComparison(userId);
        comparisonId = state.comparisonId ?? comparisonId;
        final added = state.items.firstWhereOrNull((i) => i.productId == product.id);
        if (added != null) addedCompareItemIds.add(added.comparisonItemId);
        print('COMPARE_ADD ✓ ${product.title} → liste ${state.items.length}');
      } else {
        lastMessage = res.message;
        print('COMPARE_ADD ✗ ${product.title} → "${res.message}"');
        break;
      }
    }

    print('COMPARE sonuç: $accepted kabul · liste ${state.items.length} · red mesajı: $lastMessage');
    expect(state.items.length, lessThanOrEqualTo(4), reason: 'sunucu 4 üründen fazlasını kabul etti');
    expect(lastMessage, isNotNull, reason: 'sunucu 5. ürünü reddetmedi');

    // Reddin nedeni istemcide anlaşılır uyarıya çevriliyor mu (web ile aynı
    // eşleme): mesajda "limit"/"4" ya da "category" geçmeli.
    final msg = lastMessage!.toLowerCase();
    expect(msg.contains('limit') || msg.contains('4') || msg.contains('category') || msg.contains('maximum'), isTrue,
        reason: 'red mesajı bilinen bir kalıba uymuyor: $lastMessage');
  });

  // 🔴 EN SONDA: sepeti boşaltma. Kullanıcının gerçek sepetini siliyor, bu
  // yüzden önce kalemler yedekleniyor ve test sonunda ürün + adet birebir
  // geri konuyor.
  test('Cart/clear — sepet boşaltılıyor ve yedekten geri konuyor', () async {
    final before = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    print('CLEAR_ONCE ${before.length} kalem: ${before.map((i) => "${i.title}×${i.quantity}").join(" · ")}');

    final ok = await ApiCartRepository.instance.clearCart(userId);
    expect(ok, isTrue, reason: 'Cart/clear başarısız');
    final afterClear = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    print('CLEAR_SONRA ${afterClear.length} kalem');
    expect(afterClear, isEmpty);

    // --- Yedekten geri yükle ---
    for (final item in before) {
      final res = await ApiCartRepository.instance.addToCart(
        userId: userId,
        productId: item.productId,
        quantity: item.quantity,
      );
      expect(res, isNotEmpty, reason: '"${item.title}" geri konulamadı');
    }
    final restored = (await ApiCartRepository.instance.fetchUserCart(userId))!;
    print('CLEAR_GERI ${restored.length} kalem: ${restored.map((i) => "${i.title}×${i.quantity}").join(" · ")}');
    expect(restored.length, before.length);
    for (final item in before) {
      final back = restored.firstWhereOrNull((i) => i.productId == item.productId);
      expect(back, isNotNull, reason: '"${item.title}" sepete geri dönmedi');
      expect(back!.quantity, item.quantity, reason: '"${item.title}" adedi değişti');
    }

    // Geri konan kalemler kullanıcının kendi kalemleri; temizlik listesine
    // EKLENMEZ, yoksa tearDown onları siler.
  });
}
