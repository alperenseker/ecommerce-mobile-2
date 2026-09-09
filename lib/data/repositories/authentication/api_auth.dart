import 'package:dio/dio.dart';

import '../../../utils/http/dio_client.dart';

/// Kimlik uçlarının **dio** tabanlı istemcisi (güncel olan).
///
/// ⚠️ Aynı adda (`ApiAuth`) ikinci bir sınıf `api_authentication_repository.dart`
/// içinde de var; ikisini aynı dosyaya import etme.
class ApiAuth {
  // Taban adres tek yerde (`THttpClient`) tanımlı olmalı; burada ikinci bir
  // kopya tutmak sunucu taşındığında birini güncellemeyi unutturuyordu.
  // Uç adları ve gövde alanları değişmedi.
  static final String _baseUrl = THttpClient.baseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<Map<String, dynamic>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerWithEmailPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
    String? phone,
    String accountType = 'retail',
    String iin = '',
    String userName = '',
  }) async {
    try {
      final response = await _dio.post(
        'auth/register',
        data: {
          'Name': name,
          'Surname': surname,
          'UserName': userName,
          'Email': email,
          'Password': password,
          'Phone': phone ?? '',
          'ProfileImage': '',
          'DeviceToken': '',
          'AccountType': accountType,
          'Iin': iin,
        },
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return _normalize(e.response!.data);
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Pre-register the user to obtain a temporary token. The token authorizes the
  /// subsequent `/company/{iin}` registry lookup during company sign-up.
  static Future<Map<String, dynamic>> preRegister({
    required String email,
    String name = '',
    String surname = '',
    String accountType = 'company',
  }) async {
    try {
      final response = await _dio.post(
        'auth/pre-register',
        data: {
          'Email': email,
          'Name': name,
          'Surname': surname,
          'AccountType': accountType,
        },
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return _normalize(e.response!.data);
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Look up official company info by IIN/BIN. Returns `success: false` on any
  /// error (e.g. 404 not found) so callers can fall back to manual entry.
  /// [tempToken] is the token from [preRegister] and is sent as a Bearer token.
  static Future<Map<String, dynamic>> getCompanyByIin(
    String iin, {
    String? tempToken,
  }) async {
    try {
      final response = await _dio.get(
        'company/$iin',
        options: (tempToken != null && tempToken.isNotEmpty)
            ? Options(headers: {'Authorization': 'Bearer $tempToken'})
            : null,
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final normalized = _normalize(e.response!.data);
        // A 404/empty body just means the company is not in the registry.
        return {...normalized, 'success': normalized['success'] == true && normalized['data'] != null};
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Send the registration OTP to the given contact (email).
  ///
  /// FAZ 34 — [accountType] (`retail` / `company`) opsiyonel olarak gönderilir.
  /// Sunucudaki kapı (Faz 29) alanı doluysa **o kayıt tipinin** anahtarına,
  /// boşsa yalnız "ikisi de kapalı" durumuna bakıyor. Doğru tipi göndermek
  /// müşterinin kapalı bir akışta OTP beklemesini önler.
  static Future<Map<String, dynamic>> sendRegistrationOtp({
    required String contact,
    String method = 'email',
    String? accountType,
  }) =>
      _otpCall('otp/send-registration-otp', {
        'Contact': contact,
        'Method': method,
        if (accountType != null && accountType.isNotEmpty) 'AccountType': accountType,
      });

  /// Verify the 6-digit registration OTP.
  static Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String contact,
    required String code,
    String method = 'email',
  }) =>
      _otpCall('otp/verify-registration-otp', {'Contact': contact, 'Method': method, 'Code': code});

  /// Resend the registration OTP.
  static Future<Map<String, dynamic>> resendRegistrationOtp({
    required String contact,
    String method = 'email',
  }) =>
      _otpCall('otp/resend-registration-otp', {'Contact': contact, 'Method': method});

  static Future<Map<String, dynamic>> _otpCall(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return _normalize(e.response!.data);
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Normalizes the backend's mixed PascalCase/camelCase envelope into a single
  /// lowercase-keyed map:
  /// `{ success, data, token, tempToken, user, message, userId, errorCode }`.
  ///
  /// FAZ 34 — `errorCode` eklendi. Kayıt kapıları (Faz 29) 403 gövdesinde
  /// `{ success, errorCode, message }` döndürüyor; kod olmadan 403'ün sebebi
  /// ayırt edilemez ve ekran doğru bölümü gizleyemez.
  static Map<String, dynamic> _normalize(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return {
      'success': map['success'] ?? map['Success'] ?? false,
      'data': map['data'] ?? map['Data'],
      'token': map['token'] ?? map['Token'],
      'tempToken': map['tempToken'] ?? map['TempToken'],
      'user': map['user'] ?? map['User'],
      'userId': map['userId'] ?? map['UserId'] ?? map['userID'] ?? map['UserID'],
      'message': map['message'] ?? map['Message'] ?? '',
      'errorCode': map['errorCode'] ?? map['ErrorCode'] ?? '',
    };
  }

  /// Change the password for a logged-in user.
  /// [token] is the current auth token (sent as Bearer).
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        'auth/change-password',
        data: {
          'UserId': userId,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        return _normalize(e.response!.data);
      }
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> sendEmailVerification(String token) async {
    try {
      final response = await _dio.post(
        'auth/send-verification-email',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final response = await _dio.post(
        'auth/forgot-password',
        data: {'Email': email},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// [ForgotPassword] - Verify the OTP code emailed to [email].
  static Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        'auth/verify-forgot-password-otp',
        data: {'Email': email, 'Code': code},
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) return _normalize(e.response!.data);
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// [ForgotPassword] - Set a new password after the OTP has been verified.
  static Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        'auth/reset-forgot-password',
        data: {'Email': email, 'NewPassword': newPassword},
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map) return _normalize(e.response!.data);
      return {'success': false, 'message': e.message ?? 'Network error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
