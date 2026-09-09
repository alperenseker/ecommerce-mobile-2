import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Platform kaynaklı hataları okunur mesaja çeviren sınıf.
class TPlatformException implements Exception {
  final String code;

  TPlatformException(this.code);

  String get message {
    switch (code) {
      case 'INVALID_LOGIN_CREDENTIALS':
        return TTexts.authInvalidCredentials.tr;
      case 'too-many-requests':
        return TTexts.authTooManyRequests.tr;
      case 'invalid-argument':
        return TTexts.authInvalidArgument.tr;
      case 'invalid-password':
        return TTexts.authInvalidPassword.tr;
      case 'invalid-phone-number':
        return TTexts.authInvalidPhoneNumber.tr;
      case 'operation-not-allowed':
        return TTexts.authSignInMethodDisabled.tr;
      case 'session-cookie-expired':
        return TTexts.authSessionCookieExpired.tr;
      case 'uid-already-exists':
        return TTexts.authUserIdAlreadyExists.tr;
      case 'sign_in_failed':
        return TTexts.authSignInFailed.tr;
      case 'network-request-failed':
        return TTexts.authNetworkFailure.tr;
      case 'internal-error':
        return TTexts.authInternalError.tr;
      case 'invalid-verification-code':
        return TTexts.authInvalidVerificationCode.tr;
      case 'invalid-verification-id':
        return TTexts.authInvalidVerificationId.tr;
      case 'quota-exceeded':
        return TTexts.authQuotaExceeded.tr;
      default:
        return TTexts.authUnexpectedPlatformError.tr;
    }

  }
}
