/// FAZ 34 — sunucu kaydı **403** ile reddettiğinde fırlatılan hata.
///
/// Kayıt kapısı Faz 29'da üç uca birden kondu (`auth/register`,
/// `auth/pre-register`, `otp/send-registration-otp`) ve yanıt gövdesinde
/// makine-okur bir [errorCode] taşıyor. Bu sınıf o kodu ekrana kadar taşır:
/// düz `String` fırlatılsaydı istemci "hangi kayıt tipi kapandı" bilgisini
/// kaybeder ve K29.2'nin gerektirdiği "kapalı bölümü hiç gösterme"
/// davranışını uygulayamazdı.
///
/// [errorCode] değerleri **Faz 29'un değiştirilemez sözleşmesidir**:
/// `registration_disabled_retail`, `registration_disabled_company`,
/// `registration_disabled`.
class TRegistrationClosedException implements Exception {
  const TRegistrationClosedException(this.errorCode, this.message);

  final String errorCode;

  /// Sunucunun tek dilindeki cümlesi. Yeni istemci bunu **kullanmaz**, kendi
  /// dilindeki metni yazar; yine de taşınıyor ki hiç metin bulunamazsa
  /// gösterilecek bir şey olsun.
  final String message;

  /// Perakende kaydı kapalı.
  bool get isRetail => errorCode == 'registration_disabled_retail';

  /// Bayi (şirket) kaydı kapalı.
  bool get isCompany => errorCode == 'registration_disabled_company';

  /// Kayıt tümüyle kapalı (hesap tipi bildirilmemişti).
  bool get isAll => errorCode == 'registration_disabled';

  /// `e.toString()` mesajı gösteren mevcut `catch` blokları için: teknik bir
  /// sınıf adı değil, kullanıcının okuyabileceği cümle döner.
  @override
  String toString() => message;
}
