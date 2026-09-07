/// Kategori ağacını tutan controller.
///
/// 🔴 `ApiCategoryRepository.fetchAllItems()` ağacı DÜZLEŞTİRİR: kökler ve tüm
/// alt dallar tek listede döner (canlıda 41 satır). Kökler `parentId` boş
/// olanlardır; liste uzunluğu "kök sayısı" DEĞİLDİR.
///
/// 🔴 Derinlik sabit değil: canlıda `Foral` 4, `Fores` 2, `Stark Alpha` 1
/// seviye. Ağaç çizen her yer özyinelemeli çalışmalı; iki seviye varsaymak
/// Foral'ın 11 yaprağını gizler.
library;

import 'package:get/get.dart';

import '../../../data/repositories/categories/api_category_repository.dart';
import '../../../data/repositories/product/api_products_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  RxBool isLoading = true.obs;
  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> featuredCategories = <CategoryModel>[].obs;
  final _categoryRepository = ApiCategoryRepository.instance;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  /// -- Kategori verisini yükle
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final fetchedCategories = await _categoryRepository.fetchAllItems();

      fetchedCategories.sort((a, b) {
        if (a.priority == b.priority) {
          // Öncelik aynıysa kimliğe göre sabit bir sıra tut.
          return a.id.compareTo(b.id);
        }
        return a.priority.compareTo(b.priority);
      });

      allCategories.assignAll(fetchedCategories);

      // Öne çıkan kategoriler: yalnız kökler, en çok 8 tane.
      featuredCategories.assignAll(
        allCategories.where((category) => (category.isFeatured) && category.parentId.isEmpty).take(8).toList(),
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// -- Seçili kategorinin alt kategorileri
  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      return allCategories.where((cat) => cat.parentId == categoryId).toList();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return [];
    }
  }

  /// -- Kök (ilk seviye) kategoriler, gösterim sırasına göre.
  List<CategoryModel> get rootCategories => getChildren('');

  /// -- [parentId]'nin doğrudan çocukları, gösterim sırasına göre.
  /// [getSubCategories]'in eşzamanlı sürümü; özyinelemeli ağaç bununla çizilir.
  List<CategoryModel> getChildren(String parentId) {
    final children = allCategories.where((cat) => cat.parentId == parentId).toList();
    children.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return children;
  }

  /// [categoryId] ve **bütün alt ağacının** kimlikleri.
  ///
  /// Mağazada bir kategori seçildiğinde alt dalları da otomatik dâhil olur;
  /// web'deki `App.catalog.descendantIds()` ile aynı kural.
  List<String> descendantIds(String categoryId) {
    final ids = <String>[categoryId];
    void collect(String parentId) {
      for (final child in getChildren(parentId)) {
        ids.add(child.id);
        collect(child.id);
      }
    }

    collect(categoryId);
    return ids;
  }

  /// Kategori (ya da alt kategori) ürünleri.
  /// Bu kategorideki TÜM ürünler isteniyorsa [limit] = -1 verin.
  ///
  /// 🔴 Süzme SUNUCUDA `categoryId` sorgu parametresiyle yapılır: ürün listesi
  /// yanıtı ürün başına kategori kimliği taşımıyor, istemci tarafı süzme her
  /// zaman boş dönerdi.
  Future<List<ProductModel>> getCategoryProducts({required String categoryId, int limit = -1}) async {
    try {
      final products = await ApiProductRepository.instance.fetchProductsByCategory(categoryId);
      if (limit != -1) return products.take(limit).toList();
      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return [];
    }
  }

  Future<void> updateCategoryView(String categoryId, CategoryModel category) async {
    int view = category.viewCount;
    view++;
    _categoryRepository.updateSingleField(categoryId, {"viewCount": view});
  }
}
