/// Firebase hatalarının çevirisi.
///
/// ⚠️ Bu proje Firebase KULLANMIYOR; dosya referansla eşitlik için duruyor.
library;

import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Custom exception class to handle various Firebase-related errors.
class TFirebaseException implements Exception {
  /// The error code associated with the exception.
  final String code;

  /// Constructor that takes an error code.
  TFirebaseException(this.code);

  /// Get the corresponding error message based on the error code.
  String get message {
    switch (code) {
      case 'unknown':
        return TTexts.firebaseUnknownError.tr;
      case 'invalid-custom-token':
        return TTexts.invalidCustomTokenFormat.tr;
      case 'custom-token-mismatch':
        return TTexts.customTokenAudienceMismatch.tr;
      case 'user-disabled':
        return TTexts.firebaseUserDisabled.tr;
      case 'user-not-found':
        return TTexts.firebaseUserNotFound.tr;
      case 'invalid-email':
        return TTexts.firebaseInvalidEmail.tr;
      case 'email-already-in-use':
        return TTexts.firebaseEmailAlreadyInUse.tr;
      case 'wrong-password':
        return TTexts.firebaseWrongPassword.tr;
      case 'weak-password':
        return TTexts.firebaseWeakPassword.tr;
      case 'provider-already-linked':
        return TTexts.firebaseProviderAlreadyLinked.tr;
      case 'operation-not-allowed':
        return TTexts.firebaseOperationNotAllowed.tr;
      case 'invalid-credential':
        return TTexts.firebaseInvalidCredential.tr;
      case 'invalid-verification-code':
        return TTexts.firebaseInvalidVerificationCode.tr;
      case 'invalid-verification-id':
        return TTexts.firebaseInvalidVerificationId.tr;
      case 'captcha-check-failed':
        return TTexts.firebaseCaptchaCheckFailed.tr;
      case 'app-not-authorized':
        return TTexts.firebaseAppNotAuthorized.tr;
      case 'keychain-error':
        return TTexts.firebaseKeychainError.tr;
      case 'internal-error':
        return TTexts.firebaseInternalError.tr;
      case 'invalid-app-credential':
        return TTexts.firebaseInvalidAppCredential.tr;
      case 'user-mismatch':
        return TTexts.firebaseUserCredentialMismatch.tr;
      case 'requires-recent-login':
        return TTexts.firebaseRequiresRecentLogin.tr;
      case 'quota-exceeded':
        return TTexts.firebaseQuotaExceeded.tr;
      case 'account-exists-with-different-credential':
        return TTexts.firebaseAccountExistsWithDifferentCredential.tr;
      case 'missing-iframe-start':
        return TTexts.firebaseMissingIframeStartTag.tr;
      case 'missing-iframe-end':
        return TTexts.firebaseMissingIframeEndTag.tr;
      case 'missing-iframe-src':
        return TTexts.firebaseMissingIframeSrc.tr;
      case 'auth-domain-config-required':
        return TTexts.firebaseAuthDomainConfigRequired.tr;
      case 'missing-app-credential':
        return TTexts.firebaseMissingAppCredential.tr;
      case 'session-cookie-expired':
        return TTexts.firebaseSessionCookieExpired.tr;
      case 'uid-already-exists':
        return TTexts.firebaseUidAlreadyExists.tr;
      case 'web-storage-unsupported':
        return TTexts.firebaseWebStorageUnsupported.tr;
      case 'app-deleted':
        return TTexts.firebaseAppDeleted.tr;
      case 'user-token-mismatch':
        return TTexts.firebaseUserTokenMismatch.tr;
      case 'invalid-message-payload':
        return TTexts.firebaseInvalidMessagePayload.tr;
      case 'invalid-sender':
        return TTexts.firebaseInvalidEmailSender.tr;
      case 'invalid-recipient-email':
        return TTexts.firebaseInvalidRecipientEmail.tr;
      case 'missing-action-code':
        return TTexts.firebaseMissingActionCode.tr;
      case 'user-token-expired':
        return TTexts.firebaseUserTokenExpired.tr;
      case 'INVALID_LOGIN_CREDENTIALS':
        return TTexts.firebaseInvalidLoginCredentials.tr;
      case 'expired-action-code':
        return TTexts.firebaseExpiredActionCode.tr;
      case 'invalid-action-code':
        return TTexts.firebaseInvalidActionCode.tr;
      case 'credential-already-in-use':
        return TTexts.firebaseCredentialAlreadyInUse.tr;
      default:
        return TTexts.firebaseUnexpectedError.tr;
    }

  }
}
