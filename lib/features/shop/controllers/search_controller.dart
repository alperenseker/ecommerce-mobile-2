/// Arama ekranını süren controller.
///
/// Mağazayla aynı yaklaşım: aktif katalog bir kez çekilir, sorgular bellekte
/// ad / stok kodu / açıklama üzerinde eşleştirilir (sunucudaki `search`
/// parametresi stok kodunu ve tasarım kodlarını kapsamıyor), sonuçlar
/// [pageSize] kadar açılır.
///
/// 🔴 En az 2 karakter yazılmadan arama yapılmaz; tek harf bütün kataloğu
/// döndürüp listeyi anlamsızlaştırıyordu.
library;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/repositories/product/api_products_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/product_model.dart';

class TSearchController extends GetxController {
  static TSearchController get instance => Get.find();

  static const int pageSize = 48;

  /// Aramanın başlaması için gereken en az karakter sayısı.
  static const int minQueryLength = 2;

  final RxBool isLoading = false.obs; // yalnız katalog yüklenirken true
  final RxString query = ''.obs;
  final RxInt visibleCount = pageSize.obs;
  final TextEditingController textController = TextEditingController();

  final RxList<ProductModel> _catalog = <ProductModel>[].obs;
  Future<List<ProductModel>>? _catalogFuture;

  @override
  void onInit() {
    _loadCatalog();
    super.onInit();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> _loadCatalog() async {
    try {
      isLoading.value = true;
      final all = await (_catalogFuture ??= ApiProductRepository.instance.fetchAllItems().catchError((Object e) {
        _catalogFuture = null; // hata sonrası yeniden denenebilsin
        throw e;
      }));
      _catalog.assignAll(all);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Anlık, istemci tarafı. Yeni sorguda sayfalama başa döner.
  void search(String value) {
    query.value = value;
    visibleCount.value = pageSize;
  }

  void clearSearch() {
    if (query.value.isEmpty) return;
    textController.clear();
    search('');
  }

  /// Sorgu aramayı başlatacak kadar uzun mu.
  bool get hasEnoughQuery => query.value.trim().length >= minQueryLength;

  /// Sonraki [pageSize] eşleşmeyi açar (istek yok).
  void showMore() => visibleCount.value += pageSize;

  /// Adı / stok kodu / açıklaması sorguyu içeren aktif ürünler, ada göre
  /// sıralı. Sorgu yeterince uzun değilse boştur.
  List<ProductModel> get matchedProducts {
    final q = query.value.trim().toLowerCase();
    if (q.length < minQueryLength) return const [];
    final result = _catalog.where((p) {
      if (!p.isActive) return false;
      return p.title.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false);
    }).toList();
    result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }
}
