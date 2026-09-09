import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../repositories/authentication/authentication_repository.dart';
import '../../../utils/http/dio_client.dart';

/// Favori (istek listesi) uçları (`Wishlist/...`). Kullanıcıya özel, önbelleksiz.
class ApiWishlistRepository extends GetxController {
  static ApiWishlistRepository get instance => Get.find();

  /// Shared app-wide Dio (see [THttpClient]).
  final Dio _dio = THttpClient.dio;

  Options get _authOptions {
    final token = AuthenticationRepository.instance.customAuthToken.value;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  bool _isSuccess(Map<String, dynamic> data) =>
      data['success'] == true || data['Success'] == true;

  dynamic _getData(Map<String, dynamic> data) =>
      data['data'] ?? data['Data'];

  /// Backend'deki default wishlist'i getirir.
  /// Dönüş: { productId: wishlistItemId } map'i
  Future<Map<String, String>> fetchDefaultWishlistItems(String userId) async {
    try {
      final response = await _dio.get(
        'wishlist/user/$userId/default',
        options: _authOptions,
      );

      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        final wishlistData = _getData(data) as Map<String, dynamic>?;
        if (wishlistData == null) return {};

        final items = (wishlistData['items'] ?? wishlistData['Items']) as List<dynamic>? ?? [];
        final result = <String, String>{};
        for (final item in items) {
          final pid = (item['productId'] ?? item['ProductId'])?.toString();
          final wid = (item['wishlistItemId'] ?? item['WishlistItemId'])?.toString();
          if (pid != null && wid != null) result[pid] = wid;
        }
        return result;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Ürünü backend wishlist'ine ekler.
  /// Başarılıysa wishlistItemId döner, hata olursa null döner.
  Future<String?> addToWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        'wishlist/add',
        data: {
          'userId': userId,
          'productId': productId,
          'note': '',
          'priority': 0,
        },
        options: _authOptions,
      );

      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        final wishlistData = _getData(data) as Map<String, dynamic>?;
        if (wishlistData == null) return null;

        final items = (wishlistData['items'] ?? wishlistData['Items']) as List<dynamic>? ?? [];
        for (final item in items) {
          final pid = (item['productId'] ?? item['ProductId'])?.toString();
          final wid = (item['wishlistItemId'] ?? item['WishlistItemId'])?.toString();
          if (pid == productId && wid != null) return wid;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ürünü backend wishlist'inden çıkarır.
  Future<bool> removeFromWishlist(String wishlistItemId) async {
    try {
      final response = await _dio.delete(
        'wishlist/remove/$wishlistItemId',
        options: _authOptions,
      );

      final data = response.data as Map<String, dynamic>;
      return _isSuccess(data);
    } catch (_) {
      return false;
    }
  }
}
