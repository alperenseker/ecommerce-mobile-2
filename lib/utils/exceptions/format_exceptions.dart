import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Biçim (format) hatalarını okunur mesaja çeviren sınıf.
class TFormatException implements Exception {
  /// The associated error message.
  final String message;

  /// Default constructor with a generic error message.
  const TFormatException([this.message = 'An unexpected format error occurred. Please check your input.']);

  /// Create a format exception from a specific error message.
  factory TFormatException.fromMessage(String message) {
    return TFormatException(message);
  }

  /// Get the corresponding error message.
  String get formattedMessage => message;

  /// Create a format exception from a specific error code.
  factory TFormatException.fromCode(String code) {
    switch (code) {
      case 'invalid-email-format':
        return TFormatException(TTexts.formatInvalidEmail.tr);
      case 'invalid-phone-number-format':
        return TFormatException(TTexts.formatInvalidPhoneNumber.tr);
      case 'invalid-date-format':
        return TFormatException(TTexts.formatInvalidDate.tr);
      case 'invalid-url-format':
        return TFormatException(TTexts.formatInvalidUrl.tr);
      case 'invalid-credit-card-format':
        return TFormatException(TTexts.formatInvalidCreditCard.tr);
      case 'invalid-numeric-format':
        return TFormatException(TTexts.formatInvalidNumeric.tr);
      default:
        return const TFormatException();
    }

  }
}