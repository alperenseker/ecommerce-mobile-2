/// Form doğrulayıcıları.
///
/// Kurallar referanstakiyle birebir aynıdır: şifre en az 6 karakter **ve**
/// büyük harf + rakam + özel karakter ister. Sunucu bunlardan yalnız 6
/// karakteri zorluyor; istemcideki ek kurallar bilerek daha sıkı tutuldu ve
/// gevşetilmedi — gevşetmek, referansla aynı hesabın mobilde kabul edilip
/// webde reddedilmesine yol açardı.
library;

/// VALIDATION CLASS
class TValidator {
  /// Empty Text Validation
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  /// Username Validation
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required.';
    }

    // Kullanıcı adı deseni: 3-20 karakter, harf/rakam/alt çizgi/tire.
    const pattern = r"^[a-zA-Z0-9_-]{3,20}$";

    final regex = RegExp(pattern);

    bool isValid = regex.hasMatch(username);

    // Alt çizgi veya tire ile başlayıp bitmesi ayrıca engelleniyor; desen
    // bunu tek başına yakalamıyor.
    if (isValid) {
      isValid = !username.startsWith('_') && !username.startsWith('-') && !username.endsWith('_') && !username.endsWith('-');
    }

    if (!isValid) {
      return 'Username is not valid.';
    }

    return null;
  }

  /// Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  /// Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    // Asgari uzunluk — sunucunun da zorladığı tek kural.
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  /// Phone Number Validation
  ///
  /// Yalnız boşluk denetimi yapılır. Referansta 14 haneli desen denenmiş ve
  /// yorumda bırakılmış: ülke kodu ayrı bir alandan geldiği için hane sayısı
  /// ülkeye göre değişiyor ve sabit desen geçerli numaraları reddediyordu.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }

    return null;
  }

// Add more custom validators as needed for your specific requirements.
}
