// FAZ 06 — sepet · favori · karşılaştırma ekran davranışları (ağa çıkmaz).
//
// Canlı uç doğrulaması `live_cart_test.dart` içinde; burada yalnız istem
// dosyasındaki görünüm/iş kuralı maddeleri sınanıyor:
//   · girişsiz kullanıcıya BOŞ SEPET değil "önce giriş yapın"
//   · iki şirket → iki başlık + bölme notu, tek şirkette not YOK
//   · grup sırası sepetteki sıra (alfabetik değil), ara toplam `price` ile
//   · miktar değişimi sunucu reddedince GERİ ALINIYOR
//   · karşılaştırmada sütunlar eşit, uzun ad kırpılmıyor, boş satır çizilmiyor
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/common/widgets/loaders/t_empty_state.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/cart/api_cart_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/compare/api_compare_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/product/api_products_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/wishlist/api_wishlist_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_repository.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/user_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/cart_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/compare_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/favourites_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/product_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/product/variation_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/models/cart_item_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/compare_item_model.dart';
import 'package:tstore_ecommerce_app/features/shop/models/product_model.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/cart/cart.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/compare/compare.dart';
import 'package:tstore_ecommerce_app/utils/constants/text_strings.dart';
import 'package:tstore_ecommerce_app/utils/helpers/erp_source_helper.dart';
import 'package:tstore_ecommerce_app/utils/local_storage/storage_utility.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';

// ignore_for_file: avoid_print

/// `onReady()` yönlendirme yapıyor; widget testinde gezinme istemiyoruz.
class _OfflineAuthRepository extends AuthenticationRepository {
  _OfflineAuthRepository({required this.guest});

  final bool guest;

  @override
  bool get isGuestUser => guest;

  @override
  String get getUserID => guest ? '' : 'test-user';

  @override
  void onReady() {}
}

/// Ağa çıkmayan ürün controller'ı (katalog çağrısı atlanır).
class _OfflineProductController extends ProductController {
  @override
  void onInit() {}
}

class _OfflineSettingsController extends SettingsController {
  @override
  Future<void> onInit() async {}
}

/// Başlıktaki profil avatarı `UserController`i okuyor; testte kullanıcı
/// kaydını sunucudan çekmesini istemiyoruz.
class _OfflineUserController extends UserController {
  @override
  void onInit() {}
}

/// Favori ve karşılaştırma controller'ları açılışta sunucuya gidiyor; widget
/// testinde ağ yok, listeler elle dolduruluyor.
class _OfflineFavouriteController extends FavouriteController {
  @override
  void onInit() {}
}

class _OfflineCompareController extends CompareController {
  @override
  void onInit() {}
}

/// Her isteği BAŞARISIZ sayan sepet repository'si: iyimser çizimin geri
/// alınıp alınmadığını sınamak için (boş liste = istek başarısız).
class _FailingCartRepository extends ApiCartRepository {
  @override
  Future<List<CartItemModel>> addToCart({required String userId, required String productId, required int quantity}) async => [];

  @override
  Future<List<CartItemModel>> updateQuantity({required String cartItemId, required int quantity}) async => [];
}

/// Sunucuya hiç gitmeyen sepet: yerel durum testleri için.
class _SilentCartRepository extends ApiCartRepository {
  @override
  Future<List<CartItemModel>?> fetchUserCart(String userId) async => null;
}

CartItemModel _item({
  required String productId,
  required String title,
  required String erpSource,
  double price = 100,
  int quantity = 1,
  String? cartItemId,
}) =>
    CartItemModel(
      productId: productId,
      title: title,
      price: price,
      quantity: quantity,
      erpSource: erpSource,
      cartItemId: cartItemId,
      image: '',
    );

CompareItemModel _compareItem({
  required String id,
  required String name,
  double price = 100,
  int stock = 5,
  String category = '',
  double? weight,
}) =>
    CompareItemModel(
      comparisonItemId: 'c-$id',
      productId: id,
      productName: name,
      mainImage: '',
      slug: id,
      price: price,
      stockAmount: stock,
      description: '',
      categoryName: category,
      color: '',
      size: '',
      weight: weight,
      isActive: true,
    );

Widget _wrap(Widget child) => GetMaterialApp(theme: TAppTheme.lightTheme, home: child);

/// Sepet ekranının ihtiyaç duyduğu tüm bağımlılıklar; [guest] misafir kapısını
/// açar/kapatır.
CartController _bootCart({required bool guest, ApiCartRepository? cartRepo}) {
  Get.reset();
  Get.put<AuthenticationRepository>(_OfflineAuthRepository(guest: guest));
  Get.put(ApiProductRepository());
  Get.put<ProductController>(_OfflineProductController());
  Get.put(VariationController());
  Get.put(ApiSettingsRepository());
  Get.put<SettingsController>(_OfflineSettingsController());
  Get.put(ApiUserRepository());
  Get.put<UserController>(_OfflineUserController());
  Get.put<ApiCartRepository>(cartRepo ?? _SilentCartRepository());
  Get.put(ApiWishlistRepository());
  Get.put(ApiCompareRepository());
  final cart = Get.put(CartController());
  Get.put<FavouriteController>(_OfflineFavouriteController());
  Get.put<CompareController>(_OfflineCompareController());
  return cart;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    // Sepet/favori yerel aynası kullanıcıya özel bir `GetStorage` kutusunda
    // duruyor; kutu açılmadan `TLocalStorage.instance()` `late` alanla patlar.
    await TLocalStorage.init('faz06-test');
  });

  setUp(() {
    // Başlık çubuğu dar yüzeyde taşıyor; gerçek telefon genişliği veriliyor.
    // (Taşma bir düzen hatası değil, test yüzeyinin varsayılan 800×600'ü.)
  });

  // ── Girişsiz kullanıcı kapısı ────────────────────────────────────────────

  testWidgets('girişsiz kullanıcıya BOŞ SEPET değil "önce giriş yapın" çizilir', (tester) async {
    _bootCart(guest: true);
    await tester.pumpWidget(_wrap(const CartScreen()));
    await tester.pump();

    expect(find.text(TTexts.signInRequired), findsOneWidget);
    expect(find.text(TTexts.cartLoginText), findsOneWidget);
    // Boş sepet metni GÖRÜNMEMELİ: misafirin sepeti "boş" değil YOKTUR.
    expect(find.text(TTexts.cartEmptyText), findsNothing);
    expect(find.text(TTexts.whoopCartEmpty), findsNothing);
  });

  testWidgets('girişsiz kullanıcıya karşılaştırma da giriş kapısı gösterir', (tester) async {
    _bootCart(guest: true);
    await tester.pumpWidget(_wrap(const CompareScreen()));
    await tester.pump();

    expect(find.byType(TEmptyState), findsOneWidget);
    expect(find.text(TTexts.compareLoginText), findsOneWidget);
    expect(find.text(TTexts.comparisonEmptyText), findsNothing);
  });

  // ── Şirkete göre gruplama ────────────────────────────────────────────────

  test('iki şirket → iki grup; sıra SEPETTEKİ sıra (alfabetik değil)', () {
    final items = [
      _item(productId: 'p1', title: 'Foral ürünü', erpSource: 'foral', price: 200, quantity: 2),
      _item(productId: 'p2', title: 'Fores ürünü', erpSource: 'fores', price: 50),
    ];
    final groups = TErpSource.groupCartItems(items);

    expect(groups.length, 2);
    // Alfabetik olsaydı "Fores" önce gelirdi; sepetteki sıra korunuyor.
    expect(groups.first.code, 'foral');
    expect(groups.last.code, 'fores');
    // Ara toplam `price` üzerinden (`salePrice` DEĞİL).
    expect(groups.first.subtotal, 400);
    expect(groups.last.subtotal, 50);
  });

  test('şirketi çözülemeyen kalem sırasını korur, sona atılmaz', () {
    final groups = TErpSource.groupCartItems([
      _item(productId: 'p1', title: 'Bilinmeyen', erpSource: ''),
      _item(productId: 'p2', title: 'Fores', erpSource: 'fores'),
    ]);
    expect(groups.first.code, '');
    expect(groups.first.name, TTexts.otherCompany);
  });

  test('`salePrice` dolu olsa da tutar `price` üzerinden hesaplanır', () {
    // Sunucuda `salePrice` = indirimden ÖNCEKİ fiyat (FAZ 05).
    final item = CartItemModel(productId: 'p', quantity: 2, price: 100, salePrice: 180);
    expect(item.unitPrice, 100);
    expect(item.totalAmount, 200);
  });

  testWidgets('iki şirkette bölme notu ÇIKAR, tek şirkette ÇIKMAZ', (tester) async {
    final cart = _bootCart(guest: false);
    cart.cartItems.assignAll([
      _item(productId: 'p1', title: 'Foral ürünü', erpSource: 'foral', cartItemId: 'c1'),
      _item(productId: 'p2', title: 'Fores ürünü', erpSource: 'fores', cartItemId: 'c2'),
    ]);
    cart.updateCartTotals();

    await tester.pumpWidget(_wrap(const CartScreen()));
    await tester.pump();

    // İki şirket başlığı + bölme notu.
    expect(find.text(TErpSource.label('foral')), findsOneWidget);
    expect(find.text(TErpSource.label('fores')), findsOneWidget);
    expect(find.textContaining(TTexts.cartSplitNote), findsOneWidget);

    // Tek şirkete düşünce not kalkmalı: bölünme yoksa uyarı yanıltıcı olur.
    cart.cartItems.removeAt(0);
    cart.updateCart();
    await tester.pump();
    expect(find.textContaining(TTexts.cartSplitNote), findsNothing);
    expect(find.text(TErpSource.label('fores')), findsOneWidget);
  });

  // ── İyimser miktar + geri alma ───────────────────────────────────────────

  testWidgets('sunucu reddedince iyimser miktar GERİ ALINIR', (tester) async {
    final cart = _bootCart(guest: false, cartRepo: _FailingCartRepository());
    // Ekran kurulmalı: `TLoaders` hata balonunu `Get.context` üzerinden çiziyor.
    await tester.pumpWidget(_wrap(const CartScreen()));
    await tester.pump();

    // (a) Var olan kalem: eski adedine döner.
    final existing = _item(productId: 'p1', title: 'Var olan', erpSource: 'fores', quantity: 2, cartItemId: 'c1');
    cart.cartItems.assignAll([existing]);
    cart.updateCart();

    await cart.addOneToCart(existing);
    await tester.pump();
    expect(cart.cartItems.single.quantity, 2, reason: 'adet eski değerine dönmeliydi');

    // (b) Sepette HİÇ olmayan kalem: tümüyle kaldırılır.
    final fresh = _item(productId: 'p9', title: 'Yeni kalem', erpSource: 'fores');
    await cart.addOneToCart(fresh);
    await tester.pump();
    expect(cart.cartItems.any((i) => i.productId == 'p9'), isFalse, reason: 'yeni kalem sepetten silinmeliydi');

    // Geri alma kullanıcıya hata balonu gösteriyor; balonun süreölçeri
    // tüketilmezse test "bekleyen zamanlayıcı" diye düşüyor.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  test('setQuantity elle yazılan adedi uygular, 0 sepette bırakmaz', () async {
    final cart = _bootCart(guest: false, cartRepo: _FailingCartRepository());
    final item = _item(productId: 'p1', title: 'Kalem', erpSource: 'fores', quantity: 2, cartItemId: 'c1');
    cart.cartItems.assignAll([item]);
    cart.updateCart();

    // Sunucu reddediyor → geri alınır (iyimser kuralı `setQuantity`te de aynı).
    await cart.setQuantity(item, 7);
    expect(cart.cartItems.single.quantity, 2);
  });

  // ── Karşılaştırma tablosu ────────────────────────────────────────────────

  testWidgets('karşılaştırmada sütunlar EŞİT ve uzun ad KIRPILMIYOR', (tester) async {
    _bootCart(guest: false);
    final compare = CompareController.instance;
    compare.items.assignAll([
      _compareItem(
        id: '1',
        name: 'Çok uzun bir ürün adı — karşılaştırma tablosunda alt satıra geçmeli, kırpılmamalı',
      ),
      _compareItem(id: '2', name: 'Kısa ad'),
    ]);
    compare.comparisonId.value = 'x';

    await tester.pumpWidget(_wrap(const CompareScreen()));
    await tester.pump();

    // Ürün sütunlarının hepsi aynı genişlikte.
    //
    // 🔴 Kural aynı, ÖLÇÜM YERİ değişti: karşılaştırma artık donuk etiket
    // sütunlu, yatay kaydırılan bir `Table` değil; etiket değerlerin üstünde
    // duruyor ve sütunlar `Expanded` ile ekranı eşit bölüşüyor. Genişlik bu
    // yüzden çizilmiş sütunlardan ölçülüyor.
    final widths = [
      for (final id in ['1', '2'])
        tester.getSize(find.byKey(ValueKey('compare-column-$id'))).width,
    ];
    expect(widths.toSet().length, 1, reason: 'ürün sütunları eşit genişlikte değil');

    // Ad hücresinde kırpma YOK: satır sınırı ve ellipsis verilmemiş.
    final nameText = tester.widget<Text>(find.text(
      'Çok uzun bir ürün adı — karşılaştırma tablosunda alt satıra geçmeli, kırpılmamalı',
    ));
    expect(nameText.maxLines, isNull);
    expect(nameText.overflow, anyOf(isNull, TextOverflow.clip));
  });

  testWidgets('5. ürün eklenince sınır uyarısı EKRANDA çizilir', (tester) async {
    _bootCart(guest: false);
    final compare = CompareController.instance;
    // Liste dolu (sunucu sınırı 4); istemci kapısı isteği atmadan uyarmalı.
    compare.items.assignAll([
      for (var i = 1; i <= CompareController.maxItems; i++) _compareItem(id: '$i', name: 'Ürün $i'),
    ]);
    compare.comparisonId.value = 'x';

    await tester.pumpWidget(_wrap(const CompareScreen()));
    await tester.pump();

    await compare.toggleCompare('yeni', ProductModel.empty());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // 🔴 Uyarının yalnız çağrılması yetmez, GERÇEKTEN çizilmeli: `TLoaders`
    // snackbar'ları bir kare sonrasına erteliyordu ve hiçbiri ekrana
    // gelmiyordu (FAZ 06'da bulunup düzeltildi).
    expect(find.text(TTexts.compareLimitReached), findsOneWidget);
    expect(compare.items.length, CompareController.maxItems, reason: 'sınır aşılmamalıydı');

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('dört üründe de boş olan satır ÇİZİLMEZ, dolu olan çizilir', (tester) async {
    _bootCart(guest: false);
    final compare = CompareController.instance;
    // Ağırlığı olan tek ürün → "ağırlık" satırı çizilmeli.
    compare.items.assignAll([
      _compareItem(id: '1', name: 'Ağırlıklı', weight: 2.5),
      _compareItem(id: '2', name: 'Ağırlıksız'),
    ]);
    compare.comparisonId.value = 'x';

    await tester.pumpWidget(_wrap(const CompareScreen()));
    await tester.pump();

    expect(find.text(TTexts.unitWeight), findsOneWidget, reason: 'tek üründe dolu olan satır çizilmeliydi');
    // Hiçbir üründe kategori yok → o satır hiç üretilmemeli.
    expect(find.text(TTexts.category), findsNothing);
  });
}
