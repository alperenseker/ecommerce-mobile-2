import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../utils/http/dio_client.dart';

/// Kimlik uçlarının **`package:http`** tabanlı eski istemcisi.
///
/// ⚠️ Sınıf adı `ApiAuth` — `api_auth.dart` içindeki dio tabanlı `ApiAuth` ile
/// aynıdır; ikisini aynı dosyaya import etme. Bunu yalnız FAZ 03'teki
/// `verify_email_controller` kullanıyor.
class ApiAuth {
  // Taban adres tek yerde (`THttpClient`) tanımlı. Buradaki çağrılar yolu
  // `'$baseUrl/auth/login'` gibi kurduğu için sondaki eğik çizgi atılıyor;
  // aksi hâlde `//auth/login` oluşurdu. Uç adları değişmedi.
  static final String baseUrl =
      THttpClient.baseUrl.replaceFirst(RegExp(r'/+\$'), '');
  
  /// Login with Email and Password using custom API
  static Future<Map<String, dynamic>> loginWithEmailPassword({
    required String email,
    required String password,
    String? twoFactorCode,
    String? twoFactorRecoveryCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': email,
          'Password': password,
          'TwoFactorCode': twoFactorCode ?? 'string',
          'TwoFactorRecoveryCode': twoFactorRecoveryCode ?? 'string',
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data;
        } else {
          throw data['message'] ?? 'Login failed';
        }
      } else {
        throw data['message'] ?? 'Server error occurred';
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw 'Network error. Please check your connection.';
      }
      rethrow;
    }
  }

  /// Register with Email and Password using custom API
  static Future<Map<String, dynamic>> registerWithEmailPassword({
    required String name,
    required String surname,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Name': name,
          'Surname': surname,
          'Email': email,
          'Password': password,
          'Phone': phone ?? '',
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data;
        } else {
          throw data['message'] ?? 'Registration failed';
        }
      } else {
        throw data['message'] ?? 'Server error occurred';
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw 'Network error. Please check your connection.';
      }
      rethrow;
    }
  }

  /// Send Email Verification
  static Future<bool> sendEmailVerification(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-verification-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send Password Reset Email
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get User Profile
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      throw 'Failed to fetch user profile';
    } catch (e) {
      rethrow;
    }
  }
}