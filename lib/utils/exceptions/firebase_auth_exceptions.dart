import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Firebase kimlik doğrulama hatalarını okunur mesaja çeviren sınıf.
///
/// ⚠️ Proje Firebase kullanmıyor (KURALLAR §6); dosya referansla eşitlik için
/// duruyor, çağrılmıyor.
class TFirebaseAuthException implements Exception {
  /// The error code associated with the exception.
  final String code;

  /// Constructor that takes an error code.
  TFirebaseAuthException(this.code);

  /// Get the corresponding error message based on the error code.
  String get message {
    switch (code) {
      case 'email-already-in-use':
        return TTexts.emailAlreadyInUse.tr;
      case 'invalid-email':
        return TTexts.invalidEmail.tr;
      case 'weak-password':
        return TTexts.weakPassword.tr;
      case 'user-disabled':
        return TTexts.userDisabled.tr;
      case 'user-not-found':
        return TTexts.userNotFound.tr;
      case 'wrong-password':
        return TTexts.wrongPassword.tr;
      case 'invalid-verification-code':
        return TTexts.invalidVerificationCode.tr;
      case 'invalid-verification-id':
        return TTexts.invalidVerificationId.tr;
      case 'quota-exceeded':
        return TTexts.quotaExceeded.tr;
      case 'email-already-exists':
        return TTexts.emailAlreadyExists.tr;
      case 'provider-already-linked':
        return TTexts.providerAlreadyLinked.tr;
      case 'requires-recent-login':
        return TTexts.requiresRecentLogin.tr;
      case 'credential-already-in-use':
        return TTexts.credentialAlreadyInUse.tr;
      case 'user-mismatch':
        return TTexts.userMismatch.tr;
      case 'account-exists-with-different-credential':
        return TTexts.accountExistsWithDifferentCredential.tr;
      case 'operation-not-allowed':
        return TTexts.operationNotAllowed.tr;
      case 'expired-action-code':
        return TTexts.expiredActionCode.tr;
      case 'invalid-action-code':
        return TTexts.invalidActionCode.tr;
      case 'missing-action-code':
        return TTexts.missingActionCode.tr;
      case 'user-token-expired':
        return TTexts.userTokenExpired.tr;
      case 'invalid-credential':
        return TTexts.invalidCredential.tr;
      case 'user-token-revoked':
        return TTexts.userTokenRevoked.tr;
      case 'invalid-message-payload':
        return TTexts.invalidMessagePayload.tr;
      case 'invalid-sender':
        return TTexts.invalidSender.tr;
      case 'invalid-recipient-email':
        return TTexts.invalidRecipientEmail.tr;
      case 'missing-iframe-start':
        return TTexts.missingIframeStart.tr;
      case 'missing-iframe-end':
        return TTexts.missingIframeEnd.tr;
      case 'missing-iframe-src':
        return TTexts.missingIframeSrc.tr;
      case 'auth-domain-config-required':
        return TTexts.authDomainConfigRequired.tr;
      case 'missing-app-credential':
        return TTexts.missingAppCredential.tr;
      case 'invalid-app-credential':
        return TTexts.invalidAppCredential.tr;
      case 'session-cookie-expired':
        return TTexts.sessionCookieExpired.tr;
      case 'uid-already-exists':
        return TTexts.uidAlreadyExists.tr;
      case 'invalid-cordova-configuration':
        return TTexts.invalidCordovaConfiguration.tr;
      case 'app-deleted':
        return TTexts.appDeleted.tr;
      case 'user-token-mismatch':
        return TTexts.userTokenMismatch.tr;
      case 'web-storage-unsupported':
        return TTexts.webStorageUnsupported.tr;
      case 'app-not-authorized':
        return TTexts.appNotAuthorized.tr;
      case 'keychain-error':
        return TTexts.keychainError.tr;
      case 'internal-error':
        return TTexts.internalError.tr;
      case 'INVALID_LOGIN_CREDENTIALS':
        return TTexts.invalidLoginCredentials.tr;
      default:
        return TTexts.unexpectedAuthError.tr;

    }
  }
}
