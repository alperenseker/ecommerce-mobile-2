import 'package:get/get.dart';

import '../../features/shop/models/cart_item_model.dart';
import '../constants/text_strings.dart';

/// Sepetin şirkete göre kırılmış hâlindeki bir küme.
///
/// [code] boşsa kalemin şirketi çözülemedi (eski sepet kaydı ya da snapshot'sız
/// kalem) — sipariş yine de doğru bölünür, bölmeyi sunucu yapıyor.
class TCartCompanyGroup {
  const TCartCompanyGroup({required this.code, required this.name, required this.items});

  final String code;
  final String name;
  final List<CartItemModel> items;

  /// Bu şirketin ara toplamı.
  ///
  /// Birim fiyat [CartItemModel.unitPrice] üzerinden okunur — `salePrice`
  /// sunucuda "indirimden ÖNCEKİ fiyat" anlamına geliyor (FAZ 05).
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  /// Bu şirketten sepetteki toplam adet.
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Şirket (1C kaynağı) adlarının istemci tarafında çözümü.
///
/// `GET /api/erp-sources` Faz 20'de admin'e kilitlendi; müşteri tarafı şirket
/// adlarını oradan çekemiyor. Sipariş uçları adı zaten `ErpSourceName` ile
/// gönderiyor, sepet ise yalnız kodu (`productSnapshot.erpSource`) taşıyor.
/// Bu yüzden ad çözümü üç adımlı:
///   1. sunucudan gelen ad (`ErpSourceName`)
///   2. aşağıdaki eşleme
///   3. kodun baş harfi büyük hâli (`xyz` → `Xyz`)
///
/// Yeni bir 1C bağlandığında [labels]'a tek satır eklemek yeter (Faz 27'de
/// `stark` böyle eklendi). Web tarafındaki `apiClient.js` →
/// `ERP_SOURCE_LABELS` ile aynı listedir; ikisi birlikte güncellenir.
class TErpSource {
  TErpSource._();

  static const Map<String, String> labels = {
    'fores': 'Fores',
    'foral': 'Foral',
    'stark': 'Stark Alpha',
  };

  /// Şirket kodunu karşılaştırılabilir hâle getirir (boşluk + büyük/küçük harf).
  static String normalizeCode(String? code) => (code ?? '').trim().toLowerCase();

  /// Ekranda görünecek şirket adı.
  ///
  /// Kod da ad da yoksa **boş string** döner: şirketi olmayan (eski,
  /// `erp_source_id IS NULL`) kayıtta ad uydurulmaz, ekranda hiç gösterilmez.
  static String label(String? code, [String? nameFromServer]) {
    final name = (nameFromServer ?? '').trim();
    if (name.isNotEmpty) return name;

    final normalized = normalizeCode(code);
    if (normalized.isEmpty) return '';

    final mapped = labels[normalized];
    if (mapped != null) return mapped;

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  /// Şirketi çözülemeyen kalemlerin toplandığı başlık ("Diğer").
  static String get unknownLabel => TTexts.otherCompany.tr;

  /// Sepet kalemlerini şirkete göre kümeler.
  ///
  /// 🔴 Sıralama **kalemlerin sepetteki sırasıdır** (ilk görülen şirket önce);
  /// web `data/product-model.js` → `groupByErp` ile aynı kural. Kullanıcı
  /// eklediği sırayı hatırlıyor, listeyi alfabetik dizmek kalemi "kaybolmuş"
  /// gösteriyordu. Sunucudaki bölme sırası `erp_sources.sort_order`'a göredir,
  /// yani ekrandaki sıra ile sipariş numarasındaki sıra aynı olmak zorunda
  /// DEĞİLDİR — bölme kararını yine sunucu veriyor.
  ///
  /// Şirketi çözülemeyen kalemler de sırasını korur, sona atılmaz: onları da
  /// kullanıcı bir yerde eklemiştir.
  ///
  /// Boş sepette boş liste döner.
  static List<TCartCompanyGroup> groupCartItems(List<CartItemModel> items) {
    // `LinkedHashMap` (Dart'ta varsayılan Map) ekleme sırasını koruduğu için
    // ayrıca bir indeks tutmaya gerek yok.
    final buckets = <String, List<CartItemModel>>{};
    for (final item in items) {
      buckets.putIfAbsent(normalizeCode(item.erpSource), () => <CartItemModel>[]).add(item);
    }

    return buckets.entries
        .map((entry) => TCartCompanyGroup(
              code: entry.key,
              name: entry.key.isEmpty ? unknownLabel : label(entry.key),
              items: entry.value,
            ))
        .toList();
  }
}
