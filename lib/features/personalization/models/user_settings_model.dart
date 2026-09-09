/// Yönetici panelinden yönetilen, kullanıcıya özel **ticari** ayarlar
/// (`GET /api/usersettings/{userId}`).
///
/// Sıradan ürün/kullanıcı verisinin anlatamadığı davranışları belirler:
/// kullanıcı stokta olmayanı sipariş edebilir mi (`CanOrderWithoutStock`), fiyat
/// kategorisi, özel indirimi ve hesabına yazdırabileceği kredi limiti
/// (`HasCreditLine`, `CreditLimit`, `UsedCredit`) ile minimum sipariş tutarı.
class UserSettingsModel {
  final String? id;
  final String userId;

  /// Fiyat kategorisi (ör. "A", "B", "C"). Katalog bu kullanıcının kimliğiyle
  /// istendiğinde sunucu ona uyan fiyatları uygular.
  final String priceCategory;

  /// Kullanıcı peşin ödemeden sipariş verebilir (hesaba yazma).
  ///
  /// 🔴 FAZ 34 — bu bayrak **tek başına "kredili müşteri" demek DEĞİLDİR.**
  /// Genel ödeme modu `transfer_only` iken sunucu (K29.7 uyum katmanı) bunu
  /// **herkes için** true döndürüyor, böylece güncellenmemiş istemciler de
  /// havale dalına giriyor. Kredili müşteriyi ayırmak için [hasCreditLine]
  /// kullanılır.
  final bool canBypassPayment;

  /// FAZ 34 — müşterinin gerçekten **kendi kredi satırı** var mı
  /// (`GET /api/usersettings/{id}` → `HasCreditLine`, Faz 29'da eklendi).
  ///
  /// `gateway` modunda sunucu bunu [canBypassPayment] ile aynı yazıyor, yani
  /// bugünkü ekran değişmiyor. Ayrım yalnız `transfer_only`'de görünür:
  /// kredisiz müşteriye "hesabınıza tanımlı kredi" denmez ve minimum sipariş
  /// tutarı kontrolü **koşmaya devam eder**.
  final bool hasCreditLine;

  /// Kullanıcı stokta olmayan ürünü sepete ekleyip sipariş edebilir.
  final bool canOrderWithoutStock;

  /// Hesaba yazılabilecek toplam kredi. 0 ise kredi hattı yok.
  final double creditLimit;

  /// Önceki hesaba yazma siparişleriyle kullanılmış kredi.
  final double usedCredit;

  /// Bu kullanıcıya tanınan ek indirim oranı (yüzde).
  final double customDiscountRate;

  /// Sipariş verebilmek için gereken en düşük sepet tutarı (yalnız kredisiz /
  /// ödeme atlama yetkisi olmayan kullanıcılar için). 0 ise alt sınır
  /// uygulanmaz — web ödeme adımındaki `MinimumOrderAmount` /
  /// `checkMinimumOrderLimit` ile aynı kural.
  final double minimumOrderAmount;

  final String adminNotes;
  final bool isActive;

  UserSettingsModel({
    this.id,
    this.userId = '',
    this.priceCategory = '',
    this.canBypassPayment = false,
    this.hasCreditLine = false,
    this.canOrderWithoutStock = false,
    this.creditLimit = 0.0,
    this.usedCredit = 0.0,
    this.customDiscountRate = 0.0,
    this.minimumOrderAmount = 0.0,
    this.adminNotes = '',
    this.isActive = true,
  });

  /// Yönetici bu kullanıcıya kredi hattı açtıysa doğru.
  bool get hasCreditLimit => creditLimit > 0;

  /// Harcanabilir kalan kredi (asla eksiye düşmez).
  double get availableCredit => (creditLimit - usedCredit).clamp(0.0, double.infinity);

  static UserSettingsModel empty() => UserSettingsModel();

  /// Toleranslı ayrıştırma: sunucu PascalCase anahtar döndürür (.NET
  /// varsayılanı), ama camelCase de kabul edilir; serileştirme değişse bile
  /// model ayakta kalır.
  factory UserSettingsModel.fromJson(Map<String, dynamic> data) {
    bool getBool(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is bool) return v;
        if (v is String) return v.toLowerCase() == 'true';
      }
      return false;
    }

    double getDouble(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v is num) return v.toDouble();
        if (v is String && v.trim().isNotEmpty) {
          return double.tryParse(v.trim().replaceAll(',', '.')) ?? 0.0;
        }
      }
      return 0.0;
    }

    String getString(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v != null) return v.toString();
      }
      return '';
    }

    return UserSettingsModel(
      id: getString(['UserSettingsId', 'userSettingsId', 'id']).isEmpty
          ? null
          : getString(['UserSettingsId', 'userSettingsId', 'id']),
      userId: getString(['UserId', 'userId']),
      priceCategory: getString(['PriceCategory', 'priceCategory']),
      canBypassPayment: getBool(['CanBypassPayment', 'canBypassPayment']),
      // Savunmacı: alan yoksa (Faz 29 öncesi API) bugünkü davranışa düşülür —
      // o sürümlerde "bypass" ile "kredili" aynı şeydi. Yeni sürüm eski API'ye
      // karşı da doğru çalışsın (kabul kriteri 6).
      hasCreditLine: data.containsKey('HasCreditLine') || data.containsKey('hasCreditLine')
          ? getBool(['HasCreditLine', 'hasCreditLine'])
          : getBool(['CanBypassPayment', 'canBypassPayment']),
      canOrderWithoutStock: getBool(['CanOrderWithoutStock', 'canOrderWithoutStock']),
      creditLimit: getDouble(['CreditLimit', 'creditLimit']),
      usedCredit: getDouble(['UsedCredit', 'usedCredit']),
      customDiscountRate: getDouble(['CustomDiscountRate', 'customDiscountRate']),
      minimumOrderAmount: getDouble(['MinimumOrderAmount', 'minimumOrderAmount']),
      adminNotes: getString(['AdminNotes', 'adminNotes']),
      isActive: data.containsKey('IsActive') || data.containsKey('isActive')
          ? getBool(['IsActive', 'isActive'])
          : true,
    );
  }

  Map<String, dynamic> toJson() => {
        'UserSettingsId': id,
        'UserId': userId,
        'PriceCategory': priceCategory,
        'CanBypassPayment': canBypassPayment,
        'HasCreditLine': hasCreditLine,
        'CanOrderWithoutStock': canOrderWithoutStock,
        'CreditLimit': creditLimit,
        'UsedCredit': usedCredit,
        'CustomDiscountRate': customDiscountRate,
        'MinimumOrderAmount': minimumOrderAmount,
        'AdminNotes': adminNotes,
        'IsActive': isActive,
      };
}
