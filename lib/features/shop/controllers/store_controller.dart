/// Mağaza ekranını süren controller.
///
/// Geçerli kapsamdaki ürün kümesi (tüm aktif katalog ya da seçili
/// kategoriler) **bir kez** çekilir; arama, fiyat aralığı, sıralama ve
/// sayfalama bellekte uygulanır. Böylece toplam sayı bilinir, arama tüm
/// ürünleri (ad / stok kodu / açıklama) kapsar ve "daha fazla" düğmesi ağ
/// isteği atmadan listeyi açar. Yalnız **kategori kapsamı** değişince
/// yeniden çekilir.
library;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/repositories/product/api_products_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/product_model.dart';
import 'categories_controller.dart';

/// Mağaza ızgarasının sıralama seçenekleri. Liste web ile birebir aynı
/// (`shop.html` → `#sort-select`): varsayılan · fiyat artan · fiyat azalan ·
/// yeni · popüler · puan. Her değer kendi çeviri anahtarını taşır.
enum StoreSort {
  /// Sunucudan geldiği sıra — web'deki `default`.
  name(TTexts.sortDefault),
  priceLow(TTexts.sortPriceLow),
  priceHigh(TTexts.sortPriceHigh),
  newest(TTexts.sortNewest),

  /// Görüntülenme sayısına göre (web: `popularity`).
  popular(TTexts.sortPopular),

  /// Puana göre; yorumsuz ürünler sona (web: `rating`).
  rating(TTexts.sortRating);

  const StoreSort(this.labelKey);
  final String labelKey;
}

class StoreController extends GetxController {
  static StoreController get instance => Get.find();

  /// 🔴 Sayfa boyutu SABİT 48. Web'de de öyle (`config.js` → `PAGE_SIZE`);
  /// kullanıcıya "kaç ürün" diye sorulmaz, o seçici kaldırıldı.
  static const int pageSize = 48;

  final RxBool isLoading = true.obs;

  /// 🔴 "Yüklenemedi" ile "sonuç yok" AYRI durumlardır. Ağ kesikken kapsam
  /// boş kalıyordu ve ekran "Veri Bulunamadı!" yazıyordu — müşteriye
  /// kataloğun boş olduğunu söylemek yanlış. (Havale rekvizitlerinde
  /// verilen kararın aynısı: `bankLoadError` ≠ `bankMissing`.)
  final RxBool loadFailed = false.obs;

  /// Geçerli kapsamdaki tüm aktif ürünler. Arama / fiyat / sıralama bunun
  /// üstüne uygulanır.
  final RxList<ProductModel> _scope = <ProductModel>[].obs;

  /// Eşleşen ürünlerden kaçı gösteriliyor. "Daha fazla"da [pageSize] kadar
  /// büyür — tamamen istemci tarafında, istek yok.
  final RxInt visibleCount = pageSize.obs;

  /// [Obx] yeniden çizimleri arasında kaydırma konumu korunsun diye burada.
  final ScrollController scrollController = ScrollController();

  // -- Etkin süzgeçler
  final RxSet<String> selectedCategoryIds = <String>{}.obs;
  final Rxn<double> minPrice = Rxn<double>();
  final Rxn<double> maxPrice = Rxn<double>();
  final Rx<StoreSort> sort = StoreSort.name.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchTextController = TextEditingController();

  /// Geciken bir kapsam çağrısı, daha yenisinin sonucunu ezmesin diye.
  int _loadToken = 0;

  @override
  void onInit() {
    loadScope();
    super.onInit();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Geçerli kategori kapsamı için ürünleri (yeniden) çeker.
  ///
  /// 🔴 ÇOKLU KATEGORİ = **VEYA**: A ve B seçiliyse ikisinin BİRLEŞİMİ
  /// listelenir; ürünün ikisine birden ait olması gerekmez. Seçilen
  /// kategorinin **alt ağacı** da otomatik dâhildir
  /// (`CategoryController.descendantIds`).
  Future<void> loadScope() async {
    final token = ++_loadToken;
    try {
      isLoading.value = true;
      visibleCount.value = pageSize;

      final List<ProductModel> scope;
      if (selectedCategoryIds.isEmpty) {
        scope = await ApiProductRepository.instance.fetchAllItems();
      } else {
        final ids = _withDescendants(selectedCategoryIds);
        final lists = await Future.wait(
          ids.map((id) => ApiProductRepository.instance.fetchProductsByCategory(id)),
        );
        // Kimliğe göre birleştir: iki kategoride de görünen ürün bir kez çıksın.
        final merged = <String, ProductModel>{};
        for (final list in lists) {
          for (final product in list) {
            merged[product.id] = product;
          }
        }
        scope = merged.values.toList();
      }

      if (token != _loadToken) return; // daha yeni bir yükleme başladı — eskisini at
      _scope.assignAll(scope);
      loadFailed.value = false;
    } catch (e) {
      if (token != _loadToken) return;
      loadFailed.value = true;
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      if (token == _loadToken) isLoading.value = false;
    }
  }

  /// Seçili kategorilerin alt ağaçlarıyla birlikte kimlik kümesi.
  /// `CategoryController` henüz kurulmadıysa yalnız seçilenler kullanılır.
  Set<String> _withDescendants(Iterable<String> ids) {
    if (!Get.isRegistered<CategoryController>()) return ids.toSet();
    final controller = CategoryController.instance;
    return {for (final id in ids) ...controller.descendantIds(id)};
  }

  /// Sonraki [pageSize] ürünü açar (istemci tarafı, istek yok).
  void showMore() => visibleCount.value += pageSize;

  // -- Arama (anlık, yüklü kapsam üzerinde: ad / stok kodu / açıklama)
  void search(String query) {
    searchQuery.value = query;
    visibleCount.value = pageSize; // yeni sorgu için sayfalama başa döner
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty) return;
    searchTextController.clear();
    search('');
  }

  // -- Kategori süzgeci. Seçim değişince kapsam değişir → yeniden çekilir.
  void toggleCategory(String categoryId) {
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
    } else {
      selectedCategoryIds.add(categoryId);
    }
    loadScope();
  }

  void setSelectedCategories(Iterable<String> ids) {
    final next = ids.toSet();
    if (next.length == selectedCategoryIds.length && next.containsAll(selectedCategoryIds)) {
      return; // değişmedi — gereksiz yeniden çekmeyi önle
    }
    selectedCategoryIds.assignAll(next);
    loadScope();
  }

  /// Ana sayfadaki "daha fazla" düğmesi mağazayı **o kategorinin süzgeciyle**
  /// açar; önceki arama metni temizlenir ki sonuç beklenmedik biçimde daralmasın.
  void openWithCategory(String categoryId) {
    searchTextController.clear();
    searchQuery.value = '';
    setSelectedCategories([categoryId]);
  }

  void clearCategoryFilter() {
    if (selectedCategoryIds.isEmpty) return;
    selectedCategoryIds.clear();
    loadScope();
  }

  // -- Fiyat aralığı (istemci tarafı)
  void setPriceRange(double? min, double? max) {
    minPrice.value = min;
    maxPrice.value = max;
    visibleCount.value = pageSize;
  }

  /// Etkin süzgeç sayısı (kategori + fiyat) — "Süzgeç" çipindeki rozet.
  int get activeFilterCount {
    var count = selectedCategoryIds.length;
    if (minPrice.value != null || maxPrice.value != null) count++;
    return count;
  }

  void clearAllFilters() {
    final hadCategories = selectedCategoryIds.isNotEmpty;
    selectedCategoryIds.clear();
    minPrice.value = null;
    maxPrice.value = null;
    sort.value = StoreSort.name;
    visibleCount.value = pageSize;
    if (hadCategories) loadScope(); // süzgeçsiz kataloğu yeniden çek
  }

  double _effectivePrice(ProductModel p) => (p.salePrice ?? 0) > 0 ? p.salePrice! : p.price;

  /// Fiyata göre karşılaştırıcı.
  ///
  /// 🔴 Fiyatı gizli/olmayan ürün `price: 0` taşır; ham karşılaştırma bunları
  /// "ucuzdan pahalıya"da en başa yığıyordu. **Yön ne olursa olsun fiyatsızlar
  /// HER ZAMAN sona gider** — puan sıralamasındaki "yorumsuzlar sona" kuralıyla
  /// aynı mantık (web `shop-filters.js` → `comparePrice`).
  int _comparePrice(ProductModel a, ProductModel b, {required bool ascending}) {
    if (a.isPriceHidden != b.isPriceHidden) return a.isPriceHidden ? 1 : -1;
    if (a.isPriceHidden) return 0;

    return ascending
        ? _effectivePrice(a).compareTo(_effectivePrice(b))
        : _effectivePrice(b).compareTo(_effectivePrice(a));
  }

  /// Kapsamdaki, arama + fiyat süzgecine uyan ürünlerin sıralanmış tam listesi.
  /// Izgara bunun ilk [visibleCount] tanesini, başlık ise toplam uzunluğunu
  /// gösterir.
  List<ProductModel> get matchedProducts {
    final q = searchQuery.value.trim().toLowerCase();
    final result = _scope.where((p) {
      if (!p.isActive) return false;
      if (q.isNotEmpty) {
        final hit = p.title.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.description?.toLowerCase().contains(q) ?? false);
        if (!hit) return false;
      }
      final price = _effectivePrice(p);
      if (minPrice.value != null && price < minPrice.value!) return false;
      if (maxPrice.value != null && price > maxPrice.value!) return false;
      return true;
    }).toList();

    switch (sort.value) {
      case StoreSort.name:
        // Varsayılan: sunucudan geldiği sıra korunur (web'deki `default`).
        break;
      case StoreSort.priceLow:
        result.sort((a, b) => _comparePrice(a, b, ascending: true));
        break;
      case StoreSort.priceHigh:
        result.sort((a, b) => _comparePrice(a, b, ascending: false));
        break;
      case StoreSort.newest:
        result.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case StoreSort.popular:
        result.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      case StoreSort.rating:
        // Puanı olanlar önce (yüksek puan kazanır, eşitlikte yorum sayısı);
        // yorumsuzlar varsayılan sırasıyla arkada kalır.
        final rated = <ProductModel>[];
        final unrated = <ProductModel>[];
        for (final p in result) {
          ((p.rating ?? 0) > 0 ? rated : unrated).add(p);
        }
        rated.sort((a, b) {
          final byRating = (b.rating ?? 0).compareTo(a.rating ?? 0);
          if (byRating != 0) return byRating;
          return (b.ratingCount ?? 0).compareTo(a.ratingCount ?? 0);
        });
        result
          ..clear()
          ..addAll(rated)
          ..addAll(unrated);
        break;
    }
    return result;
  }
}
