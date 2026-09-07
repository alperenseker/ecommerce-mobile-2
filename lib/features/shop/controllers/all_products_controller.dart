/// "Tüm ürünler" ekranının sıralama controller'ı.
///
/// Ürünler dışarıdan verilir ([assignProducts]); bu controller yalnız
/// sıralamayı tutar. Sıralama listesi web ile aynı
/// (`shop.html` → `#sort-select`) artı referanstaki "indirim" seçeneği.
library;

import 'package:get/get.dart';

import '../../../data/repositories/product/api_products_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/product_model.dart';

/// Sıralama seçenekleri. Referansta bunlar İngilizce dizeydi (`'Name'`,
/// `'Higher Price'`, …) ve ekranda çevrilemiyordu; enum + çeviri anahtarı
/// hem FAZ 11'i hem de [StoreSort] ile aynı dili konuşmayı sağlıyor.
enum AllProductsSort {
  /// Sunucudan geldiği sıra.
  defaultOrder(TTexts.sortDefault),
  priceLow(TTexts.sortPriceLow),
  priceHigh(TTexts.sortPriceHigh),
  newest(TTexts.sortNewest),
  popular(TTexts.sortPopular),
  rating(TTexts.sortRating),

  /// İndirimli ürünler önce (referanstaki `'Sale'`).
  sale(TTexts.sortSale);

  const AllProductsSort(this.labelKey);
  final String labelKey;
}

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository = ApiProductRepository.instance;
  final Rx<AllProductsSort> selectedSortOption = AllProductsSort.defaultOrder.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  /// Dışarıdan bir liste verilmediğinde tüm katalog gösterilir.
  Future<List<ProductModel>> fetchProductsByQuery(dynamic query) async {
    try {
      return await repository.fetchAllItems();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return [];
    }
  }

  void assignProducts(List<ProductModel> products) {
    this.products.assignAll(products);
    sortProducts(selectedSortOption.value);
    refresh();
  }

  /// Fiyata göre karşılaştırıcı — `StoreController._comparePrice` ile aynı
  /// kural: 🔴 fiyatı gizli/olmayan ürünler yön fark etmeksizin sona gider.
  int _comparePrice(ProductModel a, ProductModel b, {required bool ascending}) {
    if (a.isPriceHidden != b.isPriceHidden) return a.isPriceHidden ? 1 : -1;
    if (a.isPriceHidden) return 0;

    final pa = (a.salePrice ?? 0) > 0 ? a.salePrice! : a.price;
    final pb = (b.salePrice ?? 0) > 0 ? b.salePrice! : b.price;
    return ascending ? pa.compareTo(pb) : pb.compareTo(pa);
  }

  void sortProducts(AllProductsSort sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case AllProductsSort.defaultOrder:
        // Sunucudan geldiği sıra korunur.
        break;
      case AllProductsSort.priceHigh:
        products.sort((a, b) => _comparePrice(a, b, ascending: false));
        break;
      case AllProductsSort.priceLow:
        products.sort((a, b) => _comparePrice(a, b, ascending: true));
        break;
      case AllProductsSort.newest:
        products.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case AllProductsSort.popular:
        products.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      case AllProductsSort.rating:
        // Puanı olanlar önce; yorumsuzlar sona.
        products.sort((a, b) {
          final ra = a.reviewsCount ?? 0;
          final rb = b.reviewsCount ?? 0;
          if (ra > 0 && rb == 0) return -1;
          if (ra == 0 && rb > 0) return 1;
          if (ra == 0 && rb == 0) return 0;
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
      case AllProductsSort.sale:
        products.sort((a, b) {
          final saleA = a.salePrice ?? 0;
          final saleB = b.salePrice ?? 0;

          if (saleB > 0 && saleA > 0) {
            return saleB.compareTo(saleA); // indirimi büyük olan önce
          } else if (saleB > 0) {
            return -1; // indirimli ürünler öne
          } else if (saleA > 0) {
            return 1;
          } else {
            return 0; // indirim yok, sıra bozulmasın
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    products.clear();
    super.dispose();
  }
}
