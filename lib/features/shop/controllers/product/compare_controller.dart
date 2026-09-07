/// Karşılaştırma listesi controller'ı.
///
/// 🔴 Sunucu **en çok 4 ürün** kabul ediyor ve varsayılan olarak "aynı
/// kategori" kuralı uyguluyor. Kategori kuralı mağazada zorunlu değil, bu
/// yüzden ekleme isteği `ignoreCategory: true` ile gidiyor (bkz.
/// `ApiCompareRepository`). Sunucudan dönen doğrulama mesajları ham hâliyle
/// gösterilmez; web `compare.service.js` ile aynı eşleme kullanılarak
/// anlaşılır uyarılara çevrilir.
///
/// 🔴 Karşılaştırma ucu kalem başına yalnız birkaç alan döndürüyor (ad, fiyat,
/// stok). Tablo şirket · ölçü · ağırlık · puan da gösterdiği için her kalem
/// katalogdan zenginleştiriliyor ([productDetails]).
library;

import 'package:get/get.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/compare/api_compare_repository.dart';
import '../../../../data/repositories/product/api_products_repository.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/compare_item_model.dart';
import '../../models/product_model.dart';
import '../../screens/product_detail/product_detail.dart';
import 'product_controller.dart';

class CompareController extends GetxController {
  static CompareController get instance => Get.find();

  /// Karşılaştırma tablosundaki kalemler.
  final RxList<CompareItemModel> items = <CompareItemModel>[].obs;

  /// Etkin karşılaştırma kimliği (ilk ürün eklenene kadar boş).
  final RxString comparisonId = ''.obs;

  /// productId -> comparisonItemId. Hızlı `isInCompare()`, kaldırma ve
  /// alt gezinme balonu bunu kullanır.
  final compareIds = <String, String>{}.obs;

  /// productId -> tam ürün kaydı (katalogdan zenginleştirme).
  final productDetails = <String, ProductModel>{}.obs;

  final isLoading = false.obs;

  /// Sunucunun kabul ettiği üst sınır. İstemci de aynı sınırı uygular ki
  /// kullanıcı isteği göndermeden uyarılsın.
  static const int maxItems = 4;

  final AuthenticationRepository authRepo = AuthenticationRepository.instance;

  ApiCompareRepository get _repo => Get.isRegistered<ApiCompareRepository>()
      ? ApiCompareRepository.instance
      : Get.put(ApiCompareRepository());

  @override
  void onInit() {
    super.onInit();
    if (!authRepo.isGuestUser) loadComparison();
  }

  bool isInCompare(String productId) => compareIds.containsKey(productId);

  /// Kullanıcının karşılaştırma listesini sunucudan çekip yerel durumu kurar.
  Future<void> loadComparison() async {
    final userId = authRepo.getUserID;
    if (userId.isEmpty) return;

    try {
      isLoading.value = true;
      final result = await _repo.fetchUserComparison(userId);
      comparisonId.value = result.comparisonId ?? '';
      items.assignAll(result.items);
      _rebuildIndex();
      await _enrichDetails();
    } finally {
      isLoading.value = false;
    }
  }

  /// Her kalem için tam ürün kaydını getirir; tablo kategori, şirket, ağırlık,
  /// ölçü, puan gibi alanları buradan okur. Katalog zaten bellekteyse ondan
  /// alınır, yoksa ürün ucundan (paralel) çekilir. Tek bir kalemin hatası
  /// yutulur — o satır kalemin kendi alanlarına düşer.
  Future<void> _enrichDetails() async {
    if (items.isEmpty) return;

    final cached = Get.isRegistered<ProductController>()
        ? ProductController.instance.allProducts
        : const <ProductModel>[];

    final repo = ApiProductRepository.instance;
    await Future.wait(items.map((item) async {
      if (productDetails.containsKey(item.productId)) return;

      final hit = cached.firstWhereOrNull((p) => p.id == item.productId);
      if (hit != null) {
        productDetails[item.productId] = hit;
        return;
      }
      try {
        productDetails[item.productId] = await repo.fetchSingleItem(item.productId);
      } catch (_) {
        // Yut: satır kalemin taşıdığı seyrek veriye düşer.
      }
    }));
    productDetails.refresh();
  }

  /// 🔴 Çıkışta çağrılır: **yalnız bellekteki** durumu siler, sunucuya
  /// gitmez. Bkz. [FavouritesController.clearLocalState].
  void clearLocalState() {
    items.clear();
    compareIds.clear();
    productDetails.clear();
    comparisonId.value = '';
    items.refresh();
    compareIds.refresh();
  }

  void _rebuildIndex() {
    compareIds.clear();
    for (final item in items) {
      compareIds[item.productId] = item.comparisonItemId;
    }
    compareIds.refresh();
  }

  /// Ürünü listeye ekler; zaten listedeyse çıkarır.
  Future<void> toggleCompare(String productId, ProductModel product) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    if (isInCompare(productId)) {
      await removeItem(compareIds[productId]!);
      return;
    }

    // İstemci tarafı kapı: sunucunun reddetmesini beklemeden uyar.
    if (items.length >= maxItems) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.compareLimitReached.tr);
      return;
    }

    final result = await _repo.addToCompare(
      userId: authRepo.getUserID,
      productId: productId,
      comparisonId: comparisonId.value,
      categoryId: product.categoryId,
    );

    if (result.success) {
      await loadComparison();
      TLoaders.customToast(message: TTexts.productAddedToCompare.tr);
      return;
    }

    // Sunucu doğrulama mesajlarını anlaşılır uyarılara çevir (web ile aynı).
    final msg = result.message.toLowerCase();
    if (msg.contains('category')) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.compareSameCategory.tr);
    } else if (msg.contains('limit') || msg.contains('4')) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.compareLimitReached.tr);
    } else if (msg.contains('already')) {
      TLoaders.customToast(message: TTexts.alreadyInCompare.tr);
    } else {
      TLoaders.errorSnackBar(
        title: TTexts.ohSnap.tr,
        message: result.message.isEmpty ? TTexts.somethingWentWrong.tr : result.message,
      );
    }
  }

  /// [productId] için ürün detayını açar (tabloda görsele/ada dokununca).
  /// Zenginleştirilmiş kayıt varsa o kullanılır, yoksa istek atılır.
  Future<void> openProduct(String productId) async {
    var product = productDetails[productId];
    if (product == null) {
      try {
        product = await ApiProductRepository.instance.fetchSingleItem(productId);
      } catch (_) {
        return;
      }
    }
    Get.to(() => ProductDetailScreen(product: product!));
  }

  Future<void> removeItem(String comparisonItemId) async {
    final success = await _repo.removeFromCompare(comparisonItemId);
    if (!success) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.somethingWentWrong.tr);
      return;
    }

    String? removedProductId;
    compareIds.forEach((pid, cid) {
      if (cid == comparisonItemId) removedProductId = pid;
    });

    items.removeWhere((i) => i.comparisonItemId == comparisonItemId);
    if (removedProductId != null) compareIds.remove(removedProductId);
    compareIds.refresh();

    TLoaders.customToast(message: TTexts.productRemovedFromCompare.tr);
  }

  Future<void> clearAll() async {
    if (comparisonId.value.isEmpty || items.isEmpty) return;

    final success = await _repo.clearCompare(comparisonId.value);
    if (success) {
      items.clear();
      compareIds.clear();
      compareIds.refresh();
    } else {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.somethingWentWrong.tr);
    }
  }
}
