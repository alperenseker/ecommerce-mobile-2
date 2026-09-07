/// Ürün detayındaki **Model + Renk** varyant seçicisini süren controller.
///
/// Açılan ürünün varyant ağacını yükler, seçili Model/Renk'i tutar ve seçim
/// değişince [displayProduct]'ı ilgili varyant ÜRÜNÜYLE değiştirir; böylece
/// ekranın geri kalanı (fiyat, stok, görseller, özellikler) kendiliğinden
/// güncellenir. Web `loadProductVariants` / `switchVariant` akışının aynısı.
///
/// 🔴 UÇ DİZİ DEĞİL NESNE döner (bkz. `faz/API.md` ve
/// [ProductVariantsModel]). Kural özeti:
///   * Tek üye varsa seçici **çizilmez**.
///   * `ColorOptions` bütün varyantları kapsamıyorsa liste `Variants`ten
///     yeniden kurulur (elle kurulan gruplarda renkler tek boş seçeneğe
///     çöküyor) — bu iş [ProductVariantsModel.normalized] içinde yapılır.
///   * Model seçiliyse yalnız **o modele ait** renkler gösterilir
///     (`DesignColorMap`).
///   * Her varyant **ayrı bir üründür**; seçim o ürünün detayını açar.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/product/api_products_repository.dart';
import '../../../../utils/constants/colors.dart';
import '../../../personalization/controllers/user_settings_controller.dart';
import '../../models/product_model.dart';
import '../../models/product_variants_model.dart';
import 'images_controller.dart';

class ProductVariantController extends GetxController {
  static ProductVariantController get instance => Get.find();

  final _repo = ApiProductRepository.instance;

  /// Ekranda şu an gösterilen ürün. Kullanıcının dokunduğu ürünle başlar,
  /// varyant seçilince o varyantın ürünüyle değişir.
  final Rx<ProductModel> displayProduct = ProductModel.empty().obs;

  final Rx<ProductVariantsModel> variants = ProductVariantsModel.empty().obs;
  final RxString selectedDesign = ''.obs;
  final RxString selectedColor = ''.obs;

  /// renk kodu -> hex (ör. '9005' -> '#0d0d0d')
  final RxMap<String, String> colorMap = <String, String>{}.obs;

  final RxBool isLoading = false.obs;

  /// Yeni açılan bir ürün detayı için durumu kur.
  Future<void> initialize(ProductModel product) async {
    displayProduct.value = product;
    variants.value = ProductVariantsModel.empty();
    selectedDesign.value = '';
    selectedColor.value = '';

    await _loadColorMap();
    await _loadVariants(product.id);
  }

  bool get hasVariants => variants.value.hasVariants;

  bool get hasMultipleDesigns => variants.value.designOptions.length > 1;

  /// Liste modu: renk yuvarlakları varyantları ayırt edemiyorsa (renk kodu
  /// boş ya da iki üye aynı kodu taşıyor) yuvarlak yerine resim + isim +
  /// fiyat satır listesi gösterilir. Web `shouldUseVariantList` ile aynı
  /// gerekçe: kullanıcı iki ayrı ürünü tek düğme olarak görmesin.
  bool get useVariantList {
    if (hasMultipleDesigns) return false;
    if (variants.value.variants.length < 2) return false;
    return !variants.value.colorsDistinguishVariants;
  }

  /// Kullanıcı stoksuz sipariş verebiliyor mu.
  ///
  /// `lazyPut` ile kayıtlı controller `isRegistered` demeden kurulmuş
  /// olmayabilir; `isPrepared` de sorulur, yoksa yetki hiç okunmaz.
  bool get _canOrderWithoutStock =>
      (Get.isRegistered<UserSettingsController>() || Get.isPrepared<UserSettingsController>()) &&
      UserSettingsController.instance.canOrderWithoutStock;

  /// Liste modundaki bir satır tıklanabilir mi.
  bool isVariantOrderable(VariantItem v) =>
      (v.stockAmount > 0 && v.stockStatus != 'out_of_stock') || _canOrderWithoutStock;

  /// Seçili Model'e ait renkler; model seçili değilse (ya da eşlemede yoksa)
  /// tam renk listesi.
  List<VariantColorOption> get colorsForSelectedDesign {
    final map = variants.value.designColorMap;
    final design = selectedDesign.value;
    if (design.isNotEmpty && map.containsKey(design)) return map[design]!;
    return variants.value.colorOptions;
  }

  Future<void> _loadColorMap() async {
    final map = await _repo.getProductColors();
    if (map.isNotEmpty) colorMap.assignAll(map);
  }

  Future<void> _loadVariants(String productId) async {
    try {
      isLoading.value = true;
      // Normalleştirme (tek üye elemesi + renk listesinin yeniden kurulması)
      // modelin içinde; hem burası hem ileride hızlı bakış aynı kuralı kullansın.
      final data = (await _repo.getProductVariants(productId)).normalized();
      variants.value = data;
      selectedDesign.value = data.selectedDesign;
      // Sunucu her yanıtta seçili rengi göndermiyor; boşsa açık olan ürünün
      // kendi seçeneğinden türetilir, yoksa boş kalır.
      selectedColor.value =
          data.selectedColor.isNotEmpty ? data.selectedColor : _colorOfProduct(data, productId);
    } catch (_) {
      variants.value = ProductVariantsModel.empty();
    } finally {
      isLoading.value = false;
    }
  }

  /// Açık olan ürünün renk seçeneğindeki etiketi (seçili renk gelmediğinde).
  String _colorOfProduct(ProductVariantsModel data, String productId) {
    for (final option in data.colorOptions) {
      if (option.productIds.contains(productId)) return option.color;
    }
    return '';
  }

  /// Seçili Model'in renkleri, renk koduna göre tekilleştirilmiş.
  /// Web `renderColorButtons` da tekrar eden kodları (ör. hepsi '9016' olan
  /// bir ürün) tek yuvarlağa indiriyor.
  List<VariantColorOption> get dedupedColorsForSelectedDesign {
    final seen = <String>{};
    return colorsForSelectedDesign.where((c) => seen.add(c.color)).toList();
  }

  /// Tekilleştirmeden sonra birden fazla renk kaldı mı.
  bool get hasMultipleColors => dedupedColorsForSelectedDesign.length > 1;

  /// Seçicinin gösterilecek anlamlı bir şeyi var mı: birden fazla model ya da
  /// birden fazla renk. Tek yuvarlak göstermeye değmez.
  bool get hasSelectableVariants => hasMultipleDesigns || hasMultipleColors || useVariantList;

  /// Bir Model tıklanabilir mi.
  bool isDesignAvailable(VariantDesignOption option) => option.isAvailable;

  /// Bir Renk (seçili Model için) tıklanabilir mi.
  bool isColorAvailable(VariantColorOption option) => option.isAvailable;

  Future<void> selectDesign(String design) async {
    if (design == selectedDesign.value) return;
    selectedDesign.value = design;

    // Seçili renk yeni modelde de geçerli kalsın.
    final colors = colorsForSelectedDesign;
    final stillValid = colors.any((c) => c.color == selectedColor.value && c.isAvailable);
    if (!stillValid) {
      final firstAvailable = _firstWhereOrNull(colors, (c) => c.isAvailable);
      selectedColor.value =
          firstAvailable?.color ?? (colors.isNotEmpty ? colors.first.color : selectedColor.value);
    }

    await _switchToSelectedVariant();
  }

  Future<void> selectColor(String color) async {
    if (color == selectedColor.value) return;
    selectedColor.value = color;
    await _switchToSelectedVariant();
  }

  /// Seçili Model + Renk'i bir varyant ürününe çözer ve onu yükler.
  Future<void> _switchToSelectedVariant() async {
    final colors = colorsForSelectedDesign;
    final match = _firstWhereOrNull(colors, (c) => c.color == selectedColor.value);
    if (match == null || match.productId.isEmpty) return;
    await selectVariantProduct(match.productId);
  }

  /// Doğrudan bir varyant ürününe geç (liste modunda satıra dokunma).
  Future<void> selectVariantProduct(String productId) async {
    if (productId.isEmpty || productId == displayProduct.value.id) return;

    try {
      isLoading.value = true;
      final fullProduct = await _repo.fetchSingleItem(productId);
      displayProduct.value = fullProduct;

      // Galeri yeni varyantın görsellerine dönsün.
      if (Get.isRegistered<ImagesController>()) {
        ImagesController.instance.getAllProductImages(fullProduct);
      }
    } catch (_) {
      // Hata hâlinde ekrandaki ürün olduğu gibi kalır.
    } finally {
      isLoading.value = false;
    }
  }

  /// Renk kodunu/adını boyanabilir bir [Color]'a çevirir. Sırayla dener:
  /// 1. sunucudan gelen kod -> hex eşlemesi (`/products/colors`),
  /// 2. gömülü varsayılan eşleme (web `COLOR_MAP` ile aynı),
  /// 3. değerin kendisi hex ise onu,
  /// 4. nötr gri (web'deki `|| '#ccc'`).
  Color colorFor(String code) {
    final raw = code.trim();
    if (raw.isEmpty) return _fallbackSwatch;

    final mapped = colorMap[raw];
    if (mapped != null && mapped.isNotEmpty) return _hexToColor(mapped);

    final defaultHex = _defaultColorMap[raw.toUpperCase()] ?? _defaultColorMap[raw];
    if (defaultHex != null) return _hexToColor(defaultHex);

    if (_looksLikeHex(raw)) return _hexToColor(raw);

    return _fallbackSwatch;
  }

  /// Renk kodu hiçbir yoldan çözülemediğinde basılan nötr yuvarlak.
  /// TASARIM.md §2: kendi rengini üretme, palete bağlan.
  static const Color _fallbackSwatch = TColors.borderPrimary;

  /// Sunucu `/products/colors` cevap vermezse kullanılan gömülü liste;
  /// web `COLOR_MAP` varsayılanıyla aynı.
  static const Map<String, String> _defaultColorMap = {
    '7024': '#5a6472',
    '8003': '#6b4226',
    '8017': '#3b2314',
    '8019': '#2f3234',
    '9005': '#0d0d0d',
    '9016': '#f0f0f0',
    'GOLD': '#d4af37',
    'SILVER': '#c0c0c0',
    'BRONZ': '#cd7f32',
  };

  static bool _looksLikeHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    return (cleaned.length == 6 || cleaned.length == 8) && int.tryParse(cleaned, radix: 16) != null;
  }

  static Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final intVal = int.tryParse(cleaned, radix: 16);
    if (intVal == null) return _fallbackSwatch;
    return Color(intVal);
  }

  static T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }
}
