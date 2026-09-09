/// Form alanlarının tek doğrulama kaynağı.
///
/// 🔴 Şifre kuralı burada sunucudan **daha sıkı**: 6 karakterin yanında büyük
/// harf + rakam + özel karakter isteniyor (referanstaki hâli). `new_password`
/// ekranındaki canlı kural listesi bu dördüyle aynı olmalı — birini değiştiren
/// ötekini de değiştirsin, yoksa liste yeşile döner ama form reddeder.
library;

import 'package:get/get.dart';

import '../constants/text_strings.dart';

class TValidator {
  /// Empty Text Validation
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName ${TTexts.isRequired.tr}';
    }

    return null;
  }

  /// Username Validation
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return TTexts.usernameRequired.tr;
    }

    // Define a regular expression pattern for the username.
    const pattern = r"^[a-zA-Z0-9_-]{3,20}$";

    // Create a RegExp instance from the pattern.
    final regex = RegExp(pattern);

    // Use the hasMatch method to check if the username matches the pattern.
    bool isValid = regex.hasMatch(username);

    // Check if the username doesn't start or end with an underscore or hyphen.
    if (isValid) {
      isValid = !username.startsWith('_') && !username.startsWith('-') && !username.endsWith('_') && !username.endsWith('-');
    }

    if (!isValid) {
      return TTexts.usernameInvalid.tr;
    }

    return null;
  }

  /// Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return TTexts.emailRequired.tr;
    }

    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return TTexts.emailInvalid.tr;
    }

    return null;
  }

  /// Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return TTexts.passwordRequired.tr;
    }

    // Check for minimum password length
    if (value.length < 6) {
      return TTexts.passwordMinLength.tr;
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return TTexts.passwordUppercase.tr;
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return TTexts.passwordNumber.tr;
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return TTexts.passwordSpecialChar.tr;
    }

    return null;
  }

  /// Phone Number Validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return TTexts.phoneRequired.tr;
    }
    //
    // // Regular expression for phone number validation (assuming a 10-digit US phone number format)
    // final phoneRegExp = RegExp(r'^\d{14}$');
    //
    // if (!phoneRegExp.hasMatch(value)) {
    //   return 'Invalid phone number format (13 digits required).';
    // }

    return null;
  }

// Add more custom validators as needed for your specific requirements.
}
