/// Per-user commercial settings managed from the admin panel and served by
/// `GET /api/usersettings/{userId}`.
///
/// Drives behaviours the regular product/user data can't: whether the user may
/// order out-of-stock items, their price tier, custom discount and the credit
/// limit they can spend on account.
class UserSettingsModel {
  final String? id;
  final String userId;

  /// Price tier (e.g. "A", "B", "C"). Backend applies the matching prices when
  /// the catalog is requested with this user's id.
  final String priceCategory;

  /// User may place orders without paying immediately (order on account).
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

  /// User may add/order products that are out of stock.
  final bool canOrderWithoutStock;

  /// Total credit the user can spend on account. 0 means no credit line.
  final double creditLimit;

  /// Credit already consumed by previous on-account orders.
  final double usedCredit;

  /// Extra discount rate (percentage) granted to this user.
  final double customDiscountRate;

  /// Minimum cart total required to place an order (non credit/bypass users
  /// only). 0 means no minimum is enforced — mirrors the web checkout's
  /// `MinimumOrderAmount` / `checkMinimumOrderLimit`.
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

  /// True when the admin opened a credit line for this user.
  bool get hasCreditLimit => creditLimit > 0;

  /// Remaining credit available to spend (never negative).
  double get availableCredit => (creditLimit - usedCredit).clamp(0.0, double.infinity);

  static UserSettingsModel empty() => UserSettingsModel();

  /// Tolerant parsing: backend returns PascalCase keys (.NET default), but we
  /// also accept camelCase so the model survives a serialization change.
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
