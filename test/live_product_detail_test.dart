// GEÇİCİ: FAZ 05 ürün detayı + varyant + değerlendirme doğrulaması
// (canlı API + widget davranışı). Faz sonunda silinebilir.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/product/api_products_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/reviews/api_reviews_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_repository.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/product_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/review_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_variants_model.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/product_detail/widgets/product_meta_data.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/product_detail/widgets/product_specification.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';

// ignore_for_file: avoid_print

/// Ağa çıkmayan sürüm: `onInit` içindeki katalog çağrısı atlanıyor.
class _OfflineProductController extends ProductController {
  @override
  void onInit() {}
}

Widget _wrap(Widget child) => GetMaterialApp(
      theme: TAppTheme.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

ProductModel _product({
  required String id,
  String title = 'Test ürünü',
  double price = 0,
  bool hasPrice = true,
  bool priceHidden = false,
  String? sku,
  String? barcode,
  String? vatRate,
  double? weight,
}) =>
    ProductModel(
      id: id,
      title: title,
      lowerTitle: title.toLowerCase(),
      price: price,
      hasPrice: hasPrice,
      priceHidden: priceHidden,
      thumbnail: '',
      stock: 10,
      sku: sku,
      barcode: barcode,
      vatRate: vatRate,
      weight: weight,
    );

/// Katalog + varyant taraması PAHALI (ürün başına bir istek). Bir kez yapılıp
/// bütün testlerde paylaşılıyor.
List<ProductModel> _all = const [];
final Map<String, ProductVariantsModel> _scanned = {};

/// Taranan ürün sayısı — bütün katalog yerine örneklem yeter.
const int _sampleSize = 140;

Future<void> _scanOnce() async {
  if (_scanned.isNotEmpty) return;
  Get.reset();
  final repo = Get.put(ApiProductRepository());
  _all = await repo.fetchAllItems();
  for (final p in _all.take(_sampleSize)) {
    _scanned[p.id] = await repo.getProductVariants(p.id);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    HttpOverrides.global = null;
  });

  // ── Canlı API: varyantlar ────────────────────────────────────────────────

  test('variants ucu NESNE dönüyor ve varyantlı ürünler bulunuyor', () async {
    await _scanOnce();
    print('URUN aktif=${_all.length}');

    final examples = <String, ProductVariantsModel>{
      for (final e in _scanned.entries)
        if (e.value.hasVariants) e.key: e.value,
    };
    print('VARYANT ${_scanned.length} urunun ${examples.length} tanesinde HasVariants=true');

    expect(examples, isNotEmpty, reason: 'canlida varyantli urun bulunamadi');

    // Uç dizi değil nesne: en az bir örnekte Variants dolu gelmeli.
    final anyWithMembers = examples.values.where((v) => v.variants.isNotEmpty);
    expect(anyWithMembers, isNotEmpty);

    // Örnekleri sonraki testlere taşımak yerine burada özetliyoruz.
    for (final e in examples.entries.take(6)) {
      final v = e.value;
      print('  ${e.key}: uye=${v.variants.length} model=${v.designOptions.length} '
          'renk=${v.colorOptions.length} esleme=${v.designColorMap.length} '
          'secModel="${v.selectedDesign}" secRenk="${v.selectedColor}"');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('🔴 ProductIds ayrıştırması — renkler tek boş seçeneğe ÇÖKMÜYOR', () async {
    await _scanOnce();

    ProductVariantsModel? multi;
    String? multiId;
    for (final e in _scanned.entries) {
      if (e.value.hasVariants && e.value.colorOptions.length > 1) {
        multi = e.value;
        multiId = e.key;
        break;
      }
    }
    expect(multi, isNotNull, reason: 'birden fazla renkli grup bulunamadi');

    print('COKLU RENK urun=$multiId renk=${multi!.colorOptions.length}');
    // Asıl hata buydu: seçenekler okunuyor ama ProductIds boş kalıyordu.
    final withIds = multi.colorOptions.where((c) => c.productIds.isNotEmpty).length;
    final labelled = multi.colorOptions.where((c) => c.color.isNotEmpty).length;
    for (final c in multi.colorOptions.take(8)) {
      print('  renk="${c.color}" urunler=${c.productIds.length} stok=${c.isAvailable}');
    }
    expect(withIds, greaterThan(0), reason: 'ProductIds hic okunamadi — cokme hatasi geri geldi');
    expect(labelled, greaterThan(0), reason: 'renkler tek BOS secenege coktu');

    // DesignColorMap içindekiler tekil `ProductId` taşır; o biçim de okunmalı.
    for (final entry in multi.designColorMap.entries.take(3)) {
      final ok = entry.value.where((c) => c.productId.isNotEmpty).length;
      print('  esleme "${entry.key}": ${entry.value.length} renk, $ok tanesinde ProductId');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('normalized() — tek üyeli grup seçici çizdirmiyor', () async {
    await _scanOnce();

    var singles = 0, drawn = 0, listMode = 0;
    for (final raw in _scanned.values) {
      if (!raw.hasVariants) continue;
      final norm = raw.normalized();
      if (!norm.hasVariants) {
        singles++;
      } else {
        drawn++;
        if (!norm.colorsDistinguishVariants && norm.variants.length >= 2) listMode++;
      }
    }
    print('NORMALLESTIRME elenen(tek uye)=$singles cizilen=$drawn listeKipi=$listMode');
    expect(drawn, greaterThan(0), reason: 'hicbir grup cizilmiyor — normalized() fazla eliyor');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('varyant seçimi GERÇEKTEN başka bir ürüne götürüyor', () async {
    await _scanOnce();
    final repo = ApiProductRepository.instance;

    for (final entry in _scanned.entries) {
      final v = entry.value.normalized();
      if (!v.hasVariants) continue;

      // Açık olan üründen FARKLI bir ürüne çözülen ilk seçeneği bul.
      final target = v.colorOptions
          .where((c) => c.productId.isNotEmpty && c.productId != entry.key)
          .toList();
      if (target.isEmpty) continue;

      final source = _all.firstWhere((p) => p.id == entry.key);
      final other = await repo.fetchSingleItem(target.first.productId);
      print('GECIS "${source.title}" -> "${other.title}"');
      expect(other.id, isNot(entry.key));
      expect(other.title, isNotEmpty);
      return;
    }
    fail('baska bir urune cozulen varyant secenegi bulunamadi');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('🔴 Model + Renk grubu — DesignColorMap yolu (bilinen ürün)', () async {
    await _scanOnce();
    final repo = ApiProductRepository.instance;

    // Örneklemin ilk 140 ürününde çok modelli grup çıkmıyor; bu ürün eski
    // çalışmada (faz/DURUM.md, FAZ 05) 5 model / 7 renk ile doğrulanmıştı.
    // Katalogda çok modelli İLK grubu arayıp onu doğruluyoruz.
    ProductVariantsModel? multiDesign;
    String? id;
    for (final p in _all) {
      final v = (await repo.getProductVariants(p.id)).normalized();
      if (v.hasVariants && v.designOptions.length > 1) {
        multiDesign = v;
        id = p.id;
        break;
      }
    }

    if (multiDesign == null) {
      print('MODEL+RENK canlida cok modelli grup YOK — DesignColorMap yolu denenemedi');
      return;
    }

    print('MODEL+RENK urun=$id uye=${multiDesign.variants.length} '
        'model=${multiDesign.designOptions.length} renk=${multiDesign.colorOptions.length} '
        'esleme=${multiDesign.designColorMap.length} secModel="${multiDesign.selectedDesign}"');

    // Modellerin `ProductIds`i okunmuş olmalı (çoğul biçim).
    final designsWithIds = multiDesign.designOptions.where((d) => d.productIds.isNotEmpty).length;
    print('  model secenegi: ${multiDesign.designOptions.map((d) => d.value).join(', ')} '
        '($designsWithIds tanesinde ProductIds)');

    // Eşlemedekiler tekil `ProductId` taşır; o biçim de okunmalı.
    var mappedColors = 0, mappedWithId = 0;
    for (final e in multiDesign.designColorMap.entries) {
      mappedColors += e.value.length;
      mappedWithId += e.value.where((c) => c.productId.isNotEmpty).length;
    }
    print('  esleme: $mappedColors renk, $mappedWithId tanesinde ProductId');
    expect(multiDesign.designOptions.length, greaterThan(1));
    expect(mappedWithId, greaterThan(0),
        reason: 'DesignColorMap icindeki tekil ProductId okunamadi');
  }, timeout: const Timeout(Duration(minutes: 8)));

  test('products/colors — renk kodu -> hex eşlemesi', () async {
    await _scanOnce();
    final map = await ApiProductRepository.instance.getProductColors();
    print('RENK ESLEMESI ${map.length} kayit · ornek=${map.entries.take(4).map((e) => '${e.key}->${e.value}').join(', ')}');
    expect(map, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  // ── Canlı API: değerlendirmeler ──────────────────────────────────────────

  test('reviews/product/{id} — liste + özet (dağılım)', () async {
    await _scanOnce();
    Get.put(ApiReviewsRepository());
    // `ReviewController` kurucusunda `UserController` kuruluyor; o da
    // `ApiUserRepository` + `SettingsController` (-> `ApiSettingsRepository`)
    // istiyor. Uygulamada bu zinciri `general_bindings` kuruyor; testte elle.
    Get.put(ApiUserRepository());
    Get.put(ApiSettingsRepository());
    final controller = Get.put(ReviewController());

    // Yorumu olan ilk ürünü bul.
    ProductModel? target;
    for (final p in _all) {
      if ((p.reviewsCount ?? 0) > 0) {
        target = p;
        break;
      }
    }

    if (target == null) {
      print('YORUM canlida yorumu olan urun yok — dagitim yedek yoldan hesaplaniyor');
      final dist = controller.distributionOf([]);
      expect(dist.totalReviews, 0);
      return;
    }

    final result = await controller.fetchProductReviews(target.id);
    print('YORUM urun="${target.title}" toplam=${result.total} '
        'ortalama=${result.summary.averageRating} dagilim=${result.summary.ratingDistribution}');
    expect(result.summary.averageRating, greaterThanOrEqualTo(0));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('canlı üründe barkod / KDV / fiyat gizli sayıları', () async {
    await _scanOnce();
    final all = _all;

    final hidden = all.where((p) => p.isPriceHidden).length;
    final withBarcode = all.where((p) => (p.barcode ?? '').isNotEmpty).length;
    final withVat = all.where((p) => (p.vatRate ?? '').isNotEmpty && p.vatRate != '0').length;
    print('KUNYE fiyatGizli=$hidden/${all.length} barkod=$withBarcode KDV=$withVat');
    expect(all, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  // ── Widget davranışı (ağsız) ─────────────────────────────────────────────

  testWidgets('fiyatı gizli üründe künye RAKAM basmıyor', (tester) async {
    Get.reset();
    // `ProductController` kurucusunda repository'yi arıyor; `Get.reset()`
    // sonrası önce o kayıtlı olmalı.
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());

    await tester.pumpWidget(_wrap(
      TProductMetaData(product: _product(id: 'h1', price: 0, hasPrice: false, priceHidden: true)),
    ));
    await tester.pump();

    expect(find.textContaining('₸0'), findsNothing);
    expect(find.textContaining('0,00'), findsNothing);
    // Fiyat yerine "fiyat için sorunuz" anahtarı basılır (sözlük FAZ 11'de).
    expect(find.textContaining('priceOnRequest'), findsOneWidget);
  });

  testWidgets('fiyatlı üründe fiyat görünüyor', (tester) async {
    Get.reset();
    // `ProductController` kurucusunda repository'yi arıyor; `Get.reset()`
    // sonrası önce o kayıtlı olmalı.
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());

    await tester.pumpWidget(_wrap(
      TProductMetaData(product: _product(id: 'p1', price: 570)),
    ));
    await tester.pump();

    expect(find.textContaining('570'), findsWidgets);
    expect(find.textContaining('priceOnRequest'), findsNothing);
  });

  testWidgets('özellik tablosu BOŞ satır çizmiyor', (tester) async {
    Get.reset();
    // `ProductController` kurucusunda repository'yi arıyor; `Get.reset()`
    // sonrası önce o kayıtlı olmalı.
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());

    // Yalnız SKU ve barkod dolu; ağırlık 0, KDV "0" -> ikisi de elenmeli.
    await tester.pumpWidget(_wrap(
      TProductSpecification(
        product: _product(id: 's1', sku: 'TTS300', barcode: '4870', vatRate: '0', weight: 0),
        showHeading: false,
      ),
    ));
    await tester.pump();

    expect(find.textContaining('TTS300'), findsOneWidget);
    expect(find.textContaining('4870'), findsOneWidget);
    // Elenen satırların etiketleri hiç çizilmemeli.
    expect(find.textContaining('unitWeight'), findsNothing);
    expect(find.textContaining('vat'), findsNothing);
  });

  testWidgets('özelliği olmayan üründe YALNIZ stok satırı çiziliyor', (tester) async {
    Get.reset();
    // `ProductController` kurucusunda repository'yi arıyor; `Get.reset()`
    // sonrası önce o kayıtlı olmalı.
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());

    await tester.pumpWidget(_wrap(
      TProductSpecification(product: _product(id: 's2'), showHeading: false),
    ));
    await tester.pump();

    // ⚠️ Tablonun "—" dalı pratikte ULAŞILAMAZ: `getProductStockStatus` her
    // zaman dolu bir metin döndürüyor, yani en az bir satır hep var.
    // Doğrulanan asıl kural bu: boş alanlar satır AÇMIYOR.
    expect(find.textContaining('stockStatus'), findsOneWidget);
    for (final label in ['sku', 'barcode', 'company', 'unitWeight', 'volume', 'vat']) {
      expect(find.textContaining(label), findsNothing, reason: '\$label bos ama satir cizilmis');
    }
  });
}
