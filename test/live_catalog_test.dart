// GEÇİCİ: FAZ 04 katalog doğrulaması (canlı API + kart davranışı).
// Faz sonunda silinecek.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/common/widgets/products/product_cards/product_card_horizontal.dart';
import 'package:tstore_ecommerce_app/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:tstore_ecommerce_app/data/repositories/categories/api_category_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/product/api_products_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/cart/api_cart_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/compare/api_compare_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/wishlist/api_wishlist_repository.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/cart_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/compare_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/favourites_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/variation_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/categories_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/product_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/models/category_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_model.dart';
import 'package:tstore_ecommerce_app/utils/constants/sizes.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';

// ignore_for_file: avoid_print

/// Ağa çıkmayan sürüm: `onInit` içindeki katalog çağrısı atlanıyor, kart
/// testleri yalnız fiyat/indirim yardımcılarını kullanıyor.
class _OfflineProductController extends ProductController {
  @override
  void onInit() {}
}

/// `onReady()` açılış ekranını kapatıp yönlendirme yapıyor; widget testinde
/// gezinme istemiyoruz.
class _OfflineAuthRepository extends AuthenticationRepository {
  @override
  void onReady() {}
}

/// Kart üstündeki kalp · karşılaştır · sepete ekle düğmeleri FAZ 06'da gerçek
/// denetleyicilere bağlandı, yani kart çizen her test bu üçünü de kurmalı.
/// Ağa çıkmazlar: test deposunda kullanıcı MİSAFİR olduğu için üçü de
/// açılışta yükleme yapmıyor (sepet/favori/karşılaştırma kullanıcıya bağlıdır).
void _putCardControllers() {
  Get.put<AuthenticationRepository>(_OfflineAuthRepository());
  Get.put(VariationController());
  Get.put(ApiCartRepository());
  Get.put(ApiWishlistRepository());
  Get.put(ApiCompareRepository());
  Get.put(CartController());
  Get.put(FavouriteController());
  Get.put(CompareController());
}

Widget _wrap(Widget child) => GetMaterialApp(
      theme: TAppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );

ProductModel _product({
  required String id,
  String title = 'Test ürünü',
  double price = 0,
  bool hasPrice = true,
  bool priceHidden = false,
  int stock = 10,
  bool outOfStock = false,
}) =>
    ProductModel(
      id: id,
      title: title,
      lowerTitle: title.toLowerCase(),
      price: price,
      hasPrice: hasPrice,
      priceHidden: priceHidden,
      thumbnail: '',
      stock: stock,
      isOutOfStock: outOfStock,
    );

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

  // ── Canlı API ────────────────────────────────────────────────────────────

  test('categories — kök sayısı ve ağacın derinliği', () async {
    Get.reset();
    Get.put(ApiCategoryRepository());
    final controller = Get.put(CategoryController());
    await controller.fetchCategories();

    final roots = controller.rootCategories;
    print('KATEGORI duz liste=${controller.allCategories.length} kok=${roots.length}');

    int depthOf(CategoryModel c) {
      final children = controller.getChildren(c.id);
      if (children.isEmpty) return 1;
      return 1 + children.map(depthOf).reduce((a, b) => a > b ? a : b);
    }

    int leavesOf(CategoryModel c) {
      final children = controller.getChildren(c.id);
      if (children.isEmpty) return 1;
      return children.map(leavesOf).fold<int>(0, (a, b) => a + b);
    }

    for (final r in roots) {
      print('  KOK ${r.name}: dal=${controller.descendantIds(r.id).length - 1} '
          'derinlik=${depthOf(r)} yaprak=${leavesOf(r)}');
    }
    expect(roots, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('products — ana sayfa blokları, fiyat ve stok dagilimi', () async {
    Get.reset();
    Get.put(ApiCategoryRepository());
    Get.put(ApiProductRepository());
    final categories = Get.put(CategoryController());
    final products = Get.put(ProductController());
    await categories.fetchCategories();
    await products.fetchHomeProducts();

    final all = products.allProducts;
    print('URUN toplam(aktif)=${all.length} '
        'yeniGelenler=${products.newArrivalProducts.length} '
        'oneCikanlar=${products.featuredProducts.length}');

    final hidden = all.where((p) => p.isPriceHidden).length;
    final inStock = all.where((p) => p.stock > 0 && !(p.isOutOfStock ?? false)).length;
    print('FIYAT gizli/yok=$hidden / ${all.length} · STOK var=$inStock / ${all.length}');

    for (final root in categories.rootCategories) {
      final ids = categories.descendantIds(root.id).toSet();
      print('  BLOK ${root.name}: ${all.where((p) => ids.contains(p.categoryId)).length} urun');
    }
    expect(all, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('coklu kategori VEYA — iki kok secilince sonuc birlesim', () async {
    Get.reset();
    Get.put(ApiCategoryRepository());
    Get.put(ApiProductRepository());
    final categories = Get.put(CategoryController());
    await categories.fetchCategories();

    final roots = categories.rootCategories;
    // Ürünü olan ilk iki kökü seç.
    final counts = <CategoryModel, int>{};
    for (final r in roots) {
      final ids = categories.descendantIds(r.id);
      final lists = await Future.wait(
        ids.map((id) => ApiProductRepository.instance.fetchProductsByCategory(id)),
      );
      counts[r] = {for (final l in lists) for (final p in l) p.id}.length;
    }
    final ordered = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final a = ordered[0], b = ordered[1];

    final unionIds = <String>{};
    for (final root in [a.key, b.key]) {
      for (final id in categories.descendantIds(root.id)) {
        final list = await ApiProductRepository.instance.fetchProductsByCategory(id);
        unionIds.addAll(list.map((p) => p.id));
      }
    }
    print('VEYA ${a.key.name}(${a.value}) + ${b.key.name}(${b.value}) = ${unionIds.length}');
    // Birleşim, en büyük kümeden küçük olamaz ve iki kümenin toplamını aşamaz.
    expect(unionIds.length, greaterThanOrEqualTo(a.value));
    expect(unionIds.length, lessThanOrEqualTo(a.value + b.value));
  }, timeout: const Timeout(Duration(minutes: 5)));

  // ── Kart davranışı (ağa çıkmaz) ─────────────────────────────────────────

  testWidgets('fiyati gizli uruncte "0" basilmaz', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    await tester.pumpWidget(_wrap(SizedBox(
      width: 170,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(id: '1', price: 0, hasPrice: false),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();

    expect(find.textContaining('0,00'), findsNothing);
    expect(find.textContaining('₸0'), findsNothing);
    expect(find.text('priceOnRequest'), findsOneWidget);
  });

  testWidgets('fiyati olan uruncte fiyat gorunur', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    await tester.pumpWidget(_wrap(SizedBox(
      width: 170,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(id: '2', price: 1250),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();
    expect(find.textContaining('1250'), findsOneWidget);
  });

  testWidgets('stok yok + yetki yok -> sepete ekle KAPALI', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    await tester.pumpWidget(_wrap(SizedBox(
      width: 170,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(id: '3', price: 10, stock: 0),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(find.text('outOfStock'), findsWidgets);
  });

  testWidgets('StockStatus out_of_stock ise miktar>0 olsa da stokta degil', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    await tester.pumpWidget(_wrap(SizedBox(
      width: 170,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(id: '4', price: 10, stock: 25, outOfStock: true),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();
    expect(find.text('inStock'), findsNothing);
    expect(find.text('outOfStock'), findsWidgets);
  });

  testWidgets('stokta olan uruncte dugme acik', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    await tester.pumpWidget(_wrap(SizedBox(
      width: 170,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(id: '5', price: 10, stock: 4),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('inStock'), findsOneWidget);
  });

  testWidgets('320px genislikte izgara karti tasmaz', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(SizedBox(
      width: (320 - 3 * TSizes.gridViewSpacing) / 2,
      height: TSizes.productCardHeight,
      child: TProductCardVertical(
        product: _product(
          id: '6',
          title: 'Çok uzun bir ürün adı — kartın taşıp taşmadığını sınamak için',
          price: 0,
          hasPrice: false,
        ),
        isNetworkImage: false,
      ),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('yatay kart tasmaz', (tester) async {
    Get.reset();
    Get.put(ApiProductRepository());
    Get.put<ProductController>(_OfflineProductController());
    _putCardControllers();
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(TProductCardHorizontal(
      product: _product(
        id: '7',
        title: 'Uzun adlı ürün — yatay kart taşma sınaması',
        price: 0,
        hasPrice: false,
        stock: 0,
      ),
      isNetworkImage: false,
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
