/// Sepetin tek sahibi.
///
/// 🔴 Sepet SUNUCUDA tutulur ve **web uygulamasıyla paylaşılır**. Yereldeki
/// kopya yalnız hızlı açılış içindir; çelişki çıkarsa sunucu haklıdır. Bu
/// yüzden sepet ekranı açılırken, uygulama ön plana dönerken ve ödemeye
/// geçmeden hemen önce sunucudan yeniden okunur — kullanıcı siparişi webden
/// tamamlamış olabilir ve sunucu sepeti o an tüketmiştir.
///
/// 🔴 Girişsiz kullanıcının sepeti YOKTUR (sepet kullanıcıya bağlı). Misafir
/// bir eyleme kalkışınca `showSignInRequiredPopup()` devreye girer; sepet
/// ekranı da boş sepet değil "önce giriş yapın" çizer.
///
/// 🔴 Miktar değişimi **iyimser** uygulanır: önce yerel liste güncellenir ve
/// ekran hemen çizilir, sunucu isteği arkadan gider. İstek başarısız olursa
/// değişiklik geri alınır (bkz. [_rollback]).
library;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/cart/api_cart_repository.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/erp_source_helper.dart';
import '../../../../utils/local_storage/storage_utility.dart';
import '../../../../utils/popups/dialogs.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/user_settings_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import 'product_controller.dart';
import 'variation_controller.dart';

class CartController extends GetxController {
  static CartController get instance => Get.isRegistered() ? Get.find() : Get.put(CartController());

  RxInt noOfCartItems = 0.obs;
  RxDouble totalCartPrice = 0.0.obs;
  RxInt productQuantityInCart = 0.obs;
  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  RxBool loading = false.obs;
  final variationController = VariationController.instance;
  final AuthenticationRepository authRepo = AuthenticationRepository.instance;

  ApiCartRepository get _cartRepo => Get.isRegistered<ApiCartRepository>()
      ? ApiCartRepository.instance
      : Get.put(ApiCartRepository());

  /// Uygulama ön plana döndüğünde sepeti tazelemek için kullanılır (aşağıya bkz).
  AppLifecycleListener? _lifecycleListener;

  CartController() {
    if (!authRepo.isGuestUser) {
      loadCartItems();
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Sepet sunucuda tutulur ve web ile paylaşılır. Kullanıcı uygulamayı arka
    // plana atıp webden sipariş verebilir (bu, sunucudaki sepeti tüketir), o
    // yüzden uygulama her ön plana döndüğünde sepeti yeniden okuyoruz.
    _lifecycleListener = AppLifecycleListener(onResume: refreshFromBackend);
  }

  @override
  void onClose() {
    _lifecycleListener?.dispose();
    super.onClose();
  }

  /// Kullanıcının stoksuz sipariş yetkisi (`CanOrderWithoutStock`). Ayarlar
  /// henüz gelmediyse false döner — güvenli taraf "yalnız stoktakiler".
  bool get canOrderWithoutStock =>
      Get.isRegistered<UserSettingsController>() && UserSettingsController.instance.canOrderWithoutStock;

  /// Ürün sepete eklenebilir mi: ya stokta vardır ya da kullanıcı stoksuz
  /// sipariş verebilir.
  bool isProductOrderable(ProductModel product) => product.isInStock || canOrderWithoutStock;

  CartItemModel convertToCartItem(ProductModel product, int quantity) {
    if (product.productType == ProductType.simple) {
      variationController.resetSelectedAttributes();
    }
    final variation = variationController.selectedVariation.value;
    final isVariation = variationController.selectedVariation.value.id.isNotEmpty;
    final price = isVariation ? variation.price : product.price;
    final salePrice =
        isVariation
            ? variation.salePrice > 0.0
                ? variation.salePrice
                : 0.0
            : (product.salePrice ?? 0) > 0.0
            ? product.salePrice
            : 0.0;

    return CartItemModel(
      productId: product.id,
      title: product.title,
      price: price,
      salePrice: salePrice!,
      quantity: quantity,
      variationId: variation.id,
      image: isVariation ? variation.image.value : product.thumbnail,
      brandName: product.brand != null ? product.brand!.name : '',
      selectedVariation: isVariation ? variation.attributeValues : null,
      // Şirket bilgisi iyimser eklemede de dolsun ki kalem, backend senkronu
      // dönmeden önce sepette doğru başlığın altında görünsün.
      erpSource: product.erpSource,
    );
  }

  Future<void> addToCart(ProductModel product) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    if (product.productType.name == ProductType.variable.name && variationController.selectedVariation.value.id.isEmpty) {
      TLoaders.customToast(message: TTexts.selectVariations.tr);
      return;
    }
    // Stoksuz sipariş yetkisi olan bayide stok kontrolü atlanır.
    if (!canOrderWithoutStock) {
      if (product.productType.name == ProductType.variable.name) {
        if (variationController.selectedVariation.value.stock < 1) {
          TLoaders.warningSnackBar(message: TTexts.selectVariationsOutOfStock.tr, title: TTexts.ohSnap.tr);
          return;
        }
      } else {
        if (product.stock < 1) {
          TLoaders.warningSnackBar(message: TTexts.selectProductOutOfStock.tr, title: TTexts.ohSnap.tr);
          return;
        }
      }
    }

    final selectedCartItem = convertToCartItem(product, productQuantityInCart.value);
    final quantity = selectedCartItem.quantity < 1 ? 1 : selectedCartItem.quantity;

    int index = cartItems.indexWhere(
      (cartItem) => cartItem.productId == selectedCartItem.productId && cartItem.variationId == selectedCartItem.variationId,
    );

    // İyimser yerel güncelleme: kullanıcı ağ gecikmesini hissetmesin.
    final int? previousQuantity = index >= 0 ? cartItems[index].quantity : null;
    if (index >= 0) {
      cartItems[index].quantity = quantity;
    } else {
      cartItems.add(selectedCartItem..quantity = quantity);
    }
    updateCart();
    TLoaders.customToast(message: TTexts.productAddedToCart.tr);

    // Sunucu senkronizasyonu
    final updatedItems = await _cartRepo.addToCart(
      userId: authRepo.getUserID,
      productId: product.id,
      quantity: quantity,
    );
    if (updatedItems.isNotEmpty) {
      _mergeCartItemIds(updatedItems);
    } else {
      // İstek başarısız: iyimser çizim geri alınır, yoksa kullanıcı sepette
      // olmayan bir kalemi sepette görür.
      _rollback(productId: selectedCartItem.productId, variationId: selectedCartItem.variationId, previousQuantity: previousQuantity);
    }
  }

  Future<void> addOneToCart(CartItemModel item) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    int index = cartItems.indexWhere(
      (cartItem) => cartItem.productId == item.productId && cartItem.variationId == item.variationId,
    );

    final int? previousQuantity = index >= 0 ? cartItems[index].quantity : null;

    if (index >= 0) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(item);
      index = cartItems.length - 1;
    }
    updateCart();

    final cartItemId = cartItems[index].cartItemId;
    if (cartItemId != null) {
      final updatedItems = await _cartRepo.updateQuantity(
        cartItemId: cartItemId,
        quantity: cartItems[index].quantity,
      );
      if (updatedItems.isNotEmpty) {
        _mergeCartItemIds(updatedItems);
      } else {
        _rollback(productId: item.productId, variationId: item.variationId, previousQuantity: previousQuantity);
      }
    } else {
      // cartItemId yoksa (ilk ekleme), addToCart'ı çağır
      final updatedItems = await _cartRepo.addToCart(
        userId: authRepo.getUserID,
        productId: item.productId,
        quantity: cartItems[index].quantity,
      );
      if (updatedItems.isNotEmpty) {
        _mergeCartItemIds(updatedItems);
      } else {
        _rollback(productId: item.productId, variationId: item.variationId, previousQuantity: previousQuantity);
      }
    }
  }

  Future<void> removeOneFromCart(CartItemModel item) async {
    int index = cartItems.indexWhere(
      (cartItem) => cartItem.productId == item.productId && cartItem.variationId == item.variationId,
    );

    if (index < 0) return;

    final cartItemId = cartItems[index].cartItemId;

    if (cartItems[index].quantity > 1) {
      final previousQuantity = cartItems[index].quantity;
      cartItems[index].quantity -= 1;
      productQuantityInCart--;
      updateCart();

      if (cartItemId != null) {
        final updatedItems = await _cartRepo.updateQuantity(
          cartItemId: cartItemId,
          quantity: cartItems[index].quantity,
        );
        if (updatedItems.isNotEmpty) {
          _mergeCartItemIds(updatedItems);
        } else {
          _rollback(productId: item.productId, variationId: item.variationId, previousQuantity: previousQuantity);
        }
      }
    } else {
      // Son adet: silmek geri alınamaz bir iş, önce onay sorulur.
      cartItems[index].quantity == 1 ? removeFromCartDialog(index) : cartItems.removeAt(index);
      productQuantityInCart--;
      updateCart();
    }
  }

  /// Kalemin miktarını doğrudan **belirli bir sayıya** çeker (adımlayıcının
  /// yazılabilir alanı için). 500 adet isteyen bayi artı düğmesine 500 kez
  /// basmasın diye alan elle yazılabilir; kural aynı, değişim iyimser
  /// uygulanır ve sunucu hatasında geri alınır.
  ///
  /// 0 yazılması "kalemi sil" demektir; silme geri alınamaz bir iş olduğu için
  /// onay sorulur.
  Future<void> setQuantity(CartItemModel item, int quantity) async {
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    final index = cartItems.indexWhere(
      (cartItem) => cartItem.productId == item.productId && cartItem.variationId == item.variationId,
    );
    if (index < 0) return;

    final previousQuantity = cartItems[index].quantity;
    if (quantity == previousQuantity) return;

    if (quantity < 1) {
      removeFromCartDialog(index);
      return;
    }

    cartItems[index].quantity = quantity;
    updateCart();

    final cartItemId = cartItems[index].cartItemId;
    final updatedItems = cartItemId != null
        ? await _cartRepo.updateQuantity(cartItemId: cartItemId, quantity: quantity)
        : await _cartRepo.addToCart(userId: authRepo.getUserID, productId: item.productId, quantity: quantity);

    if (updatedItems.isNotEmpty) {
      _mergeCartItemIds(updatedItems);
    } else {
      _rollback(productId: item.productId, variationId: item.variationId, previousQuantity: previousQuantity);
    }
  }

  /// İyimser çizimi geri alır. [previousQuantity] `null` ise kalem sepette
  /// hiç yoktu ve tamamen kaldırılır.
  void _rollback({required String productId, required String variationId, int? previousQuantity}) {
    final index = cartItems.indexWhere(
      (cartItem) => cartItem.productId == productId && cartItem.variationId == variationId,
    );
    if (index < 0) return;

    if (previousQuantity == null) {
      cartItems.removeAt(index);
    } else {
      cartItems[index].quantity = previousQuantity;
    }
    updateCart();
    TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.somethingWentWrong.tr);
  }

  void removeFromCartDialog(int index) {
    final cartItemId = cartItems[index].cartItemId;

    TDialogs.confirm(
      title: TTexts.removeProduct.tr,
      message: TTexts.removeProductSure.tr,
      icon: Iconsax.trash,
      isDestructive: true,
      confirmText: TTexts.delete.tr,
      onConfirm: () async {
        cartItems.removeAt(index);
        updateCart();
        TLoaders.customToast(message: TTexts.productRemoveFromCart.tr);

        if (cartItemId != null) {
          await _cartRepo.removeItem(cartItemId);
        }
      },
    );
  }

  void replaceCartItem() {
    TDialogs.confirm(
      title: TTexts.removeProduct.tr,
      message: TTexts.removeStoreCartProduct.tr,
      icon: Iconsax.trash,
      isDestructive: true,
      confirmText: TTexts.delete.tr,
      onConfirm: () async {
        cartItems.clear();
        updateCart();
        TLoaders.customToast(message: TTexts.productRemoveFromCart.tr);
        Get.back();

        await _cartRepo.clearCart(authRepo.getUserID);
      },
    );
  }

  void updateCart() {
    updateCartTotals();
    saveCartItems();
    cartItems.refresh();
  }

  Future<void> loadCartItems() async {
    loading.value = true;

    // Önce yerelden yükle (hızlı başlangıç)
    final cartItemStrings = TLocalStorage.instance().readData<List<dynamic>>('cartItems');
    if (cartItemStrings != null) {
      cartItems.assignAll(cartItemStrings.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)));
      updateCartTotals();
    }

    // Sunucudan senkronize et
    await _syncFromBackend();

    loading.value = false;
  }

  /// Sunucudaki sepeti (web ile PAYLAŞILAN sepet) okuyup yerel sepeti ona
  /// eşitler. Yerel sepet asla "kaynak" değildir; sunucu neyse o geçerlidir.
  Future<void> _syncFromBackend() async {
    final userId = authRepo.getUserID;
    if (userId.isEmpty) return;

    // `null` = istek başarısız oldu; sunucudaki sepet bilinmiyor, yerel sepete
    // dokunma. Gerçek bir cevap (BOŞ LİSTE DAHİL) ise sunucu haklıdır.
    final backendItems = await _cartRepo.fetchUserCart(userId);
    if (backendItems == null) return;

    if (backendItems.isEmpty) {
      // Sunucudaki sepet boşaldı — kullanıcı siparişi webden tamamladı ve
      // sunucu sepeti tüketti. Yerel sepeti tutmak, sipariş edilemeyecek
      // ürünleri ekranda bırakır; bu yüzden yerel de boşaltılır.
      cartItems.clear();
      productQuantityInCart.value = 0;
    } else {
      // Sunucuyu kaynak olarak kullan: yerel `salePrice`/`brandName` gibi
      // ekstra alanları koruyarak `cartItemId`leri güncelle.
      for (final backendItem in backendItems) {
        final localIndex = cartItems.indexWhere((c) => c.productId == backendItem.productId);
        if (localIndex >= 0) {
          cartItems[localIndex].cartItemId = backendItem.cartItemId;
          cartItems[localIndex].quantity = backendItem.quantity;
          // Şirket kodu sunucunun bildiğidir; yerelde boşsa (eski kayıt)
          // doldur, doluysa da tazele.
          if (backendItem.erpSource.isNotEmpty) {
            cartItems[localIndex].erpSource = backendItem.erpSource;
          }
        } else {
          cartItems.add(backendItem);
        }
      }

      // Yerelde olup sunucuda olmayan ürünleri kaldır
      cartItems.removeWhere(
        (local) => !backendItems.any((b) => b.productId == local.productId),
      );
    }

    _fillMissingErpSources();
    updateCart();
  }

  /// Şirketi çözülemeyen kalemleri **ürün önbelleğinden** tamamlar.
  ///
  /// 🔴 Sepet ucu `ErpSource`u ayrı bir alanda göndermiyor; şirket
  /// `ProductSnapshot` JSON'unun içinde geliyor (bkz. `ApiCartRepository`).
  /// Eski snapshot'larda bu alan yok ve kalem sepette "Diğer" başlığı altına
  /// düşüyor. Katalog zaten bellekte duruyor (`ProductController.allProducts`),
  /// oradan okumak ek istek gerektirmiyor.
  void _fillMissingErpSources() {
    final missing = cartItems.where((item) => TErpSource.normalizeCode(item.erpSource).isEmpty).toList();
    if (missing.isEmpty) return;
    if (!Get.isRegistered<ProductController>()) return;

    final catalog = ProductController.instance.allProducts;
    if (catalog.isEmpty) return;

    for (final item in missing) {
      final product = catalog.firstWhereOrNull((p) => p.id == item.productId);
      if (product != null && product.erpSource.isNotEmpty) {
        item.erpSource = product.erpSource;
      }
    }
  }

  /// Paylaşılan sunucu sepetini yeniden okur ve yerel sepete uygular.
  ///
  /// Sepet sunucuda tutulur ve web uygulamasıyla PAYLAŞILIR; orada olan her
  /// şey (en önemlisi: sipariş tamamlanınca sunucunun sepeti tüketmesi) buraya
  /// da yansımalıdır. Sepet ekranı açıldığında, uygulama arka plandan
  /// döndüğünde ve ödemeye geçmeden hemen önce çağrılır.
  ///
  /// Sessizce çalışır: sepet başka bir cihazda değiştiyse ekran kendiliğinden
  /// güncellenir, kullanıcıya ayrıca bir mesaj gösterilmez.
  Future<void> refreshFromBackend({bool showLoader = false}) async {
    if (authRepo.isGuestUser) return;
    if (showLoader) loading.value = true;
    try {
      await _syncFromBackend();
    } finally {
      if (showLoader) loading.value = false;
    }
  }

  /// Sunucu yanıtından gelen `cartItemId`leri yerel `cartItems`a yansıtır.
  void _mergeCartItemIds(List<CartItemModel> backendItems) {
    for (final backendItem in backendItems) {
      final index = cartItems.indexWhere((c) => c.productId == backendItem.productId);
      if (index >= 0) {
        cartItems[index].cartItemId = backendItem.cartItemId;
        cartItems[index].quantity = backendItem.quantity;
        if (backendItem.erpSource.isNotEmpty) {
          cartItems[index].erpSource = backendItem.erpSource;
        }
      }
    }
    _fillMissingErpSources();
    updateCartTotals();
    saveCartItems();
    cartItems.refresh();
  }

  // ─── Şirket (1C kaynağı) kırılımı ─────────────────────────────────────────

  /// Sepetin şirkete göre kümelenmiş hâli. Sepet değiştikçe (miktar, silme,
  /// sunucu senkronu) yeniden hesaplanır; `Obx` içinden okunmalıdır.
  /// Grup sırası kalemlerin sepetteki sırasıdır (bkz. [TErpSource.groupCartItems]).
  List<TCartCompanyGroup> get companyGroups => TErpSource.groupCartItems(cartItems);

  /// Bu sepet kaç ayrı siparişe bölünecek. Siparişi **sunucu** bölüyor; bu
  /// sayı yalnız müşteriyi önceden bilgilendirmek için hesaplanıyor.
  int get splitOrderCount => companyGroups.length;

  /// Bölünme uyarısı gösterilsin mi. Tek şirketli sepette bölünme yoktur,
  /// uyarı yanıltıcı olurdu.
  bool get willBeSplit => splitOrderCount > 1;

  void updateCartTotals() {
    double calculatedTotalPrice = 0.0;
    int calculatedNoOfItems = 0;

    for (var item in cartItems) {
      // Birim fiyat daima `price`; `salePrice` "indirimden önceki fiyat"
      // anlamına geliyor (bkz. [CartItemModel.unitPrice]).
      calculatedTotalPrice += item.totalAmount;
      calculatedNoOfItems += item.quantity;
    }

    totalCartPrice.value = calculatedTotalPrice;
    noOfCartItems.value = calculatedNoOfItems;
  }

  void saveCartItems() {
    final cartItemStrings = cartItems.map((item) => item.toJson()).toList();
    TLocalStorage.instance().writeData('cartItems', cartItemStrings);
  }

  void updateAlreadyAddedProductCount(ProductModel product) {
    if (product.productType.toString() == ProductType.simple.toString()) {
      productQuantityInCart.value = getProductQuantityInCart(product.id);
    } else {
      final variationId = variationController.selectedVariation.value.id;
      if (variationId.isNotEmpty) {
        productQuantityInCart.value = getVariationQuantityInCart(product.id, variationId);
      } else {
        productQuantityInCart.value = 0;
      }
    }
  }

  int getProductQuantityInCart(String productId) {
    return cartItems
        .where((item) => item.productId == productId)
        .fold(0, (prev, el) => prev + el.quantity);
  }

  int getVariationQuantityInCart(String productId, String variationId) {
    final foundItem = cartItems.firstWhere(
      (item) => item.productId == productId && item.variationId == variationId,
      orElse: () => CartItemModel.empty(),
    );
    return foundItem.quantity;
  }

  /// 🔴 Çıkışta çağrılır: **yalnız bellekteki** durumu siler. [clearCart]
  /// sunucuya da gider ve çıkışta jeton kalmadığı için orada kullanılamaz.
  void clearLocalState() {
    cartItems.clear();
    noOfCartItems.value = 0;
    totalCartPrice.value = 0.0;
    productQuantityInCart.value = 0;
    cartItems.refresh();
  }

  Future<void> clearCart() async {
    productQuantityInCart.value = 0;
    cartItems.clear();
    updateCart();
    await _cartRepo.clearCart(authRepo.getUserID);
  }

  /// Onay al, sonra sepeti tamamen boşalt. Üstteki çöp kutusu düğmesi kullanır.
  void clearCartDialog() {
    if (cartItems.isEmpty) return;
    TDialogs.confirm(
      title: TTexts.removeProduct.tr,
      message: TTexts.removeProductSure.tr,
      icon: Iconsax.trash,
      isDestructive: true,
      confirmText: TTexts.delete.tr,
      onConfirm: () async {
        await clearCart();
        TLoaders.customToast(message: TTexts.productRemoveFromCart.tr);
      },
    );
  }

  /// Onay al, sonra kalemi miktarı ne olursa olsun tümüyle kaldır.
  /// Kalem başındaki çöp kutusu düğmesi kullanır.
  void removeItemFromCart(CartItemModel item) {
    final index = cartItems.indexWhere(
      (c) => c.productId == item.productId && c.variationId == item.variationId,
    );
    if (index < 0) return;
    removeFromCartDialog(index);
  }
}
