import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../features/shop/models/compare_item_model.dart';
import '../../repositories/authentication/authentication_repository.dart';
import '../../../utils/http/dio_client.dart';

/// Karşılaştırma uçlarıyla konuşur.
///
/// Biçim olarak [ApiWishlistRepository] ile aynıdır (aynı taban adres, aynı
/// yetki başlığı, aynı `success`/`data` açma mantığı). `compare/add` gövdesinde
/// `ignoreCategory: true` gider: kullanıcı farklı kategorilerdeki ürünleri de
/// yan yana koyabilmeli.
class ApiCompareRepository extends GetxController {
  static ApiCompareRepository get instance => Get.find();

  /// Shared app-wide Dio (see [THttpClient]).
  final Dio _dio = THttpClient.dio;

  Options get _authOptions {
    final token = AuthenticationRepository.instance.customAuthToken.value;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  bool _isSuccess(Map<String, dynamic> data) =>
      data['success'] == true || data['Success'] == true;

  dynamic _getData(Map<String, dynamic> data) => data['data'] ?? data['Data'];

  /// GET /compare/user/{userId} -> the user's (first) comparison list.
  Future<({String? comparisonId, List<CompareItemModel> items})> fetchUserComparison(String userId) async {
    try {
      final response = await _dio.get('compare/user/$userId', options: _authOptions);
      final data = response.data as Map<String, dynamic>;

      if (_isSuccess(data)) {
        final payload = _getData(data);
        if (payload is List && payload.isNotEmpty) {
          final first = payload.first as Map<String, dynamic>;
          return _parseComparison(first);
        }
        if (payload is Map<String, dynamic>) {
          return _parseComparison(payload);
        }
      }
      return (comparisonId: null, items: <CompareItemModel>[]);
    } catch (_) {
      return (comparisonId: null, items: <CompareItemModel>[]);
    }
  }

  ({String? comparisonId, List<CompareItemModel> items}) _parseComparison(Map<String, dynamic> json) {
    final comparisonId = (json['comparisonId'] ?? json['ComparisonId'])?.toString();
    final rawItems = (json['items'] ?? json['Items']) as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => CompareItemModel.fromJson(e as Map<String, dynamic>))
        .where((i) => i.isActive)
        .toList();
    return (comparisonId: comparisonId, items: items);
  }

  /// POST /compare/add. Returns success flag + backend message (for the
  /// same-category / limit / already-added validations).
  Future<({bool success, String message})> addToCompare({
    required String userId,
    required String productId,
    String? comparisonId,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.post(
        'compare/add',
        data: {
          'userId': userId,
          'productId': productId,
          if (comparisonId != null && comparisonId.isNotEmpty) 'comparisonId': comparisonId,
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        },
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      final message = (data['message'] ?? data['Message'] ?? '').toString();
      return (success: _isSuccess(data), message: message);
    } on DioException catch (e) {
      final resp = e.response?.data;
      final message = resp is Map ? (resp['message'] ?? resp['Message'] ?? '').toString() : '';
      return (success: false, message: message);
    } catch (_) {
      return (success: false, message: '');
    }
  }

  /// DELETE /compare/remove/{comparisonItemId}
  Future<bool> removeFromCompare(String comparisonItemId) async {
    try {
      final response = await _dio.delete('compare/remove/$comparisonItemId', options: _authOptions);
      final data = response.data as Map<String, dynamic>;
      return _isSuccess(data);
    } catch (_) {
      return false;
    }
  }

  /// DELETE /compare/clear/{comparisonId}
  Future<bool> clearCompare(String comparisonId) async {
    try {
      final response = await _dio.delete('compare/clear/$comparisonId', options: _authOptions);
      final data = response.data as Map<String, dynamic>;
      return _isSuccess(data);
    } catch (_) {
      return false;
    }
  }
}
