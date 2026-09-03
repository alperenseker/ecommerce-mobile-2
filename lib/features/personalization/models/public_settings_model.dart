/// FAZ 34 — `GET /api/settings/public` (anonim) yanıtı: üç genel anahtar.
///
/// Uç **bilerek dar**: kayıt ekranı anonimdir ve `GET /api/settings`
/// kimlik doğrulaması istiyor (Faz 29). Burada yalnız istemcinin ekran
/// çizmek için ihtiyaç duyduğu üç alan var; `taxRate`, `appLogo` gibi
/// alanlar bu uçtan gelmiyor.
///
/// 🔴 **Varsayılan = BUGÜNKÜ DAVRANIŞ.** Alan eksikse, yanıt okunamazsa ya da
/// `paymentMode` tanınmayan bir değerse kayıt AÇIK ve mod `gateway` kabul
/// edilir. Bir ağ hatası uygulamayı kayıt kapalıya ya da ödemesiz moda
/// düşürmemeli — asıl kapı sunucudadır (K29.2).
class PublicSettingsModel {
  /// Ödeme bugünkü akışta: Halyk ePay kart ekranı.
  static const String paymentModeGateway = 'gateway';

  /// Ödeme tümüyle havaleye alındı: kart ekranı hiç açılmaz.
  static const String paymentModeTransferOnly = 'transfer_only';

  final bool retailRegistrationEnabled;
  final bool companyRegistrationEnabled;
  final String paymentMode;

  const PublicSettingsModel({
    this.retailRegistrationEnabled = true,
    this.companyRegistrationEnabled = true,
    this.paymentMode = paymentModeGateway,
  });

  /// Anahtarlar okunamadığında kullanılan hâl: bugünkü davranış.
  static const PublicSettingsModel defaults = PublicSettingsModel();

  bool get isTransferOnly => paymentMode == paymentModeTransferOnly;

  /// Hiçbir kayıt tipi açık değil → kayıt ekranı yerine kapalı mesajı.
  bool get isRegistrationClosed => !retailRegistrationEnabled && !companyRegistrationEnabled;

  /// Tek bir kayıt tipi açık → hesap tipi seçicisi hiç çizilmez (K29.2).
  bool get hasSingleAccountType => retailRegistrationEnabled != companyRegistrationEnabled;

  /// Savunmacı ayrıştırma (kabul kriteri 6): eksik alan "bugünkü davranış"
  /// sayılır, böylece yeni sürüm **eski API'ye karşı da** açılır.
  factory PublicSettingsModel.fromJson(Map<String, dynamic> data) {
    bool flag(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is bool) return value;
        if (value is String && value.trim().isNotEmpty) {
          return value.trim().toLowerCase() != 'false';
        }
      }
      // Alan yok → bugünkü davranış (açık).
      return true;
    }

    String mode() {
      for (final key in ['paymentMode', 'PaymentMode', 'paymentmode']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          final normalized = value.trim().toLowerCase();
          // Tanınmayan değer `gateway`'e düşer. Mod ileride üçüncü bir değer
          // alırsa (K29.1) bu sürüm kart akışını KESMEZ, sürdürür — bilinçli.
          if (normalized == paymentModeTransferOnly) return paymentModeTransferOnly;
          return paymentModeGateway;
        }
      }
      return paymentModeGateway;
    }

    return PublicSettingsModel(
      retailRegistrationEnabled:
          flag(['retailRegistrationEnabled', 'RetailRegistrationEnabled', 'retailregistrationenabled']),
      companyRegistrationEnabled:
          flag(['companyRegistrationEnabled', 'CompanyRegistrationEnabled', 'companyregistrationenabled']),
      paymentMode: mode(),
    );
  }

  PublicSettingsModel copyWith({
    bool? retailRegistrationEnabled,
    bool? companyRegistrationEnabled,
    String? paymentMode,
  }) =>
      PublicSettingsModel(
        retailRegistrationEnabled: retailRegistrationEnabled ?? this.retailRegistrationEnabled,
        companyRegistrationEnabled: companyRegistrationEnabled ?? this.companyRegistrationEnabled,
        paymentMode: paymentMode ?? this.paymentMode,
      );
}
