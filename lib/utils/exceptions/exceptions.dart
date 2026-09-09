import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Genel hata sınıfı — hata kodunu kullanıcıya okunur mesaja çevirir.
class TExceptions implements Exception {
  /// The associated error message.
  final String message;

  /// Default constructor with a generic error message.
  const TExceptions([this.message = 'An unexpected error occurred. Please try again.']);

  /// Create an authentication exception from a Firebase authentication exception code.
  factory TExceptions.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return TExceptions(TTexts.emailAlreadyRegistered.tr);
      case 'invalid-email':
        return TExceptions(TTexts.invalidEmail.tr);
      case 'weak-password':
        return TExceptions(TTexts.weakPassword.tr);
      case 'user-disabled':
        return TExceptions(TTexts.userDisabled.tr);
      case 'user-not-found':
        return TExceptions(TTexts.invalidLoginDetails.tr);
      case 'wrong-password':
        return TExceptions(TTexts.incorrectPassword.tr);
      case 'INVALID_LOGIN_CREDENTIALS':
        return TExceptions(TTexts.invalidLoginCredentials.tr);
      case 'too-many-requests':
        return TExceptions(TTexts.tooManyRequests.tr);
      case 'invalid-argument':
        return TExceptions(TTexts.invalidAuthArgument.tr);
      case 'invalid-password':
        return TExceptions(TTexts.incorrectPasswordTryAgain.tr);
      case 'invalid-phone-number':
        return TExceptions(TTexts.invalidPhoneNumber.tr);
      case 'operation-not-allowed':
        return TExceptions(TTexts.signInProviderDisabled.tr);
      case 'session-cookie-expired':
        return TExceptions(TTexts.sessionExpired.tr);
      case 'uid-already-exists':
        return TExceptions(TTexts.userIdAlreadyInUse.tr);
      case 'sign_in_failed':
        return TExceptions(TTexts.signInFailed.tr);
      case 'network-request-failed':
        return TExceptions(TTexts.networkRequestFailed.tr);
      case 'internal-error':
        return TExceptions(TTexts.internalError.tr);
      case 'invalid-verification-code':
        return TExceptions(TTexts.invalidVerificationCode.tr);
      case 'invalid-verification-id':
        return TExceptions(TTexts.invalidVerificationId.tr);
      case 'quota-exceeded':
        return TExceptions(TTexts.quotaExceeded.tr);
      default:
        return const TExceptions();
    }
  }
}
