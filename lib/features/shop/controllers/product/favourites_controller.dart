/// Favoriler (istek listesi) controller'ı.
///
/// 🔴 Listenin ASIL yeri SUNUCUDUR. Ama kalp ikonunun dolu mu boş mu olduğu
/// her kartta anında bilinmeli; kart başına ayrı istek atmak kabul edilemez.
/// Bu yüzden sunucudaki liste yerelde bir AYNA (`favorites`) olarak tutulur:
/// ekran aynadan çizilir, dokunuş önce aynayı çevirir, istek arkadan gider.
///
/// 🔴 Sunucuya ulaşılamazsa AYNAYA DOKUNULMAZ. "İstek hatası" ile "liste boş"
/// aynı şey değildir; karıştırılırsa kullanıcının kalpleri sebepsiz söner
/// (web `wishlist.service.js` ile aynı kural).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/products/product_cards/widgets/product_stock_badge.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/product/api_products_repository.dart';
import '../../../../data/repositories/wishlist/api_wishlist_repository.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/local_storage/storage_utility.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/product_model.dart';
import 'cart_controller.dart';
import 'product_controller.dart';

class FavouriteController extends GetxController {
  static FavouriteController get instance => Get.find();

  /// productId -> bool (hızlı isFavourite kontrolü için)
  final favorites = <String, bool>{}.obs;

  /// productId -> wishlistItemId (sunucudan silmek için)
  final _wishlistItemIds = <String, String>{};

  /// "Hepsini sepete at" sürerken düğme kilitlensin diye.
  final isBulkAdding = false.obs;

  TextEditingController textEditingController = TextEditingController();

  /// ⚠️ Referansta koşulsuz `Get.put(ProductController())` vardı; her kurulumda
  /// bir ProductController daha yaratıp atıyordu. Kayıtlıysa var olan
  /// kullanılıyor (FAZ 05'te `ReviewController` için verilen aynı karar).
  final ProductController productController =
      Get.isRegistered<ProductController>() ? ProductController.instance : Get.put(ProductController());
  final AuthenticationRepository authRepo = AuthenticationRepository.instance;

  @override
  void onInit() {
    super.onInit();
    if (!authRepo.isGuestUser) {
      initFavorites();
    }
  }

  /// 🔴 Çıkışta çağrılır: **yalnız bellekteki** durumu siler, sunucuya
  /// gitmez (jeton zaten silinmiş olur). Temizlenmezse misafir kullanıcı bir
  /// önceki hesabın favori sayacını alt gezinmede görmeye devam ediyordu.
  void clearLocalState() {
    favorites.clear();
    favorites.refresh();
  }

  /// Yerel depodan yükle, ardından sunucu ile senkronize et.
  Future<void> initFavorites() async {
    final json = TLocalStorage.instance().readData('favorites');
    if (json != null) {
      final stored = jsonDecode(json) as Map<String, dynamic>;
      favorites.assignAll(stored.map((k, v) => MapEntry(k, v as bool)));
    }
    await _syncFromBackend();
  }

  /// Sunucudaki varsayılan istek listesini çekip yerel durumla eşitler.
  Future<void> _syncFromBackend() async {
    final userId = authRepo.getUserID;
    if (userId.isEmpty) return;

    try {
      final wishlistRepo = Get.isRegistered<ApiWishlistRepository>()
          ? ApiWishlistRepository.instance
          : Get.put(ApiWishlistRepository());

      final backendItems = await wishlistRepo.fetchDefaultWishlistItems(userId);

      for (final entry in backendItems.entries) {
        favorites[entry.key] = true;
        _wishlistItemIds[entry.key] = entry.value;
      }

      final toRemove = favorites.keys
          .where((id) => !backendItems.containsKey(id))
          .toList();
      for (final id in toRemove) {
        favorites.remove(id);
        _wishlistItemIds.remove(id);
      }

      saveFavoritesToStorage();
      favorites.refresh();
    } catch (_) {
      // Sunucuya erişilemezse yerel ayna korunur (bkz. dosya başlığı).
    }
  }

  /// Ürün istek listesinde mi?
  bool isFavourite(String productId) => favorites[productId] ?? false;

  /// Favoriye ekle / çıkar
  Future<void> toggleFavoriteProduct(String productId, ProductModel product) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    if (!favorites.containsKey(productId)) {
      // --- EKLE ---
      favorites[productId] = true;
      saveFavoritesToStorage();

      final wishlistRepo = Get.isRegistered<ApiWishlistRepository>()
          ? ApiWishlistRepository.instance
          : Get.put(ApiWishlistRepository());

      final wishlistItemId = await wishlistRepo.addToWishlist(
        userId: authRepo.getUserID,
        productId: productId,
      );

      if (wishlistItemId != null) {
        _wishlistItemIds[productId] = wishlistItemId;
        TLoaders.customToast(message: TTexts.productAddedToWishlist.tr);
      } else {
        favorites.remove(productId);
        saveFavoritesToStorage();
        TLoaders.errorSnackBar(
          title: TTexts.ohSnap.tr,
          message: TTexts.wishlistAddFailed.tr,
        );
      }
    } else {
      // --- ÇIKAR ---
      final wishlistItemId = _wishlistItemIds[productId];

      favorites.remove(productId);
      _wishlistItemIds.remove(productId);
      saveFavoritesToStorage();
      favorites.refresh();

      if (wishlistItemId != null) {
        final wishlistRepo = Get.isRegistered<ApiWishlistRepository>()
            ? ApiWishlistRepository.instance
            : Get.put(ApiWishlistRepository());

        final success = await wishlistRepo.removeFromWishlist(wishlistItemId);
        if (!success) {
          favorites[productId] = true;
          _wishlistItemIds[productId] = wishlistItemId;
          saveFavoritesToStorage();
          favorites.refresh();
          TLoaders.errorSnackBar(
            title: TTexts.ohSnap.tr,
            message: TTexts.wishlistRemoveFailed.tr,
          );
          return;
        }
      }

      TLoaders.customToast(message: TTexts.productRemoveFromWishlist.tr);
    }
  }

  void saveFavoritesToStorage() {
    final encoded = json.encode(favorites);
    TLocalStorage.instance().writeData('favorites', encoded);
  }

  Future<List<ProductModel>> favoriteProducts() {
    final ids = favorites.keys.toList();
    if (ids.isEmpty) return Future.value(<ProductModel>[]);

    // Katalog zaten bellekteyse ek istek atma: bu metot `FutureBuilder`
    // içinden çağrılıyor ve favori her değiştiğinde yeniden koşuyor.
    final cached = Get.isRegistered<ProductController>()
        ? ProductController.instance.allProducts
        : const <ProductModel>[];
    if (cached.isNotEmpty) {
      return Future.value(cached.where((p) => ids.contains(p.id)).toList());
    }

    return ApiProductRepository.instance
        .fetchAllItems()
        .then((all) => all.where((p) => ids.contains(p.id)).toList());
  }

  /// **Stokta olan** bütün favorileri sepete atar.
  ///
  /// 🔴 İstekler SIRAYLA gönderilir. Aynı anda 30 istek atmak sunucuyu
  /// gereksiz zorluyor ve hata durumunda hangisinin başarısız olduğu
  /// anlaşılmıyor (web `pages/wishlist.js` aynı gerekçeyle sıralı gidiyor).
  ///
  /// Her kalem için tek tek "sepete eklendi" balonu çıkmasın diye sepet
  /// controller'ının kendi bildirimi kullanılmaz; sonunda tek özet gösterilir.
  Future<void> addAllToCart(List<ProductModel> products) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }
    if (isBulkAdding.value) return;

    // Stok kuralının tek kaynağı `TProductStock` (stoksuz sipariş yetkisi
    // olan bayide "stokta yok" ürün de sipariş edilebilir).
    final addable = products.where((p) => TProductStock.resolve(p).canOrder).toList();
    if (addable.isEmpty) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.noneInStock.tr);
      return;
    }

    isBulkAdding.value = true;
    final cartController = CartController.instance;
    var added = 0;

    try {
      for (final product in addable) {
        final item = cartController.convertToCartItem(product, 1);
        final before = cartController.getProductQuantityInCart(product.id);
        await cartController.addOneToCart(item);
        if (cartController.getProductQuantityInCart(product.id) > before) added++;
      }
    } finally {
      isBulkAdding.value = false;
    }

    if (added > 0) {
      TLoaders.successSnackBar(
        title: TTexts.great.tr,
        message: TTexts.addedToCartCount.trParams({'count': '$added'}),
      );
    } else {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.somethingWentWrong.tr);
    }
  }
}
