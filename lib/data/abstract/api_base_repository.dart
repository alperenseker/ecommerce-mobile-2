/// Tüm API repository'lerinin temel sınıfı.
///
/// Paylaşılan `Dio`'yu, sayfalama alanlarını, varsayılan CRUD iskeletini ve
/// `DioException` → kullanıcıya gösterilebilir metin çevirisini burada tutar.
///
/// Yanıt zarfı iki yazımla da gelebildiği için (`Success`/`success`,
/// `Data`/`data`, `Message`/`message`) okuma daima `isSuccess` / `dataOf` /
/// `messageOf` üzerinden yapılır.
library;

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../utils/http/dio_client.dart';

abstract class TApiRepositoryController<T> extends GetxController {
  /// Uygulama genelinde paylaşılan `Dio` (taban adres, zaman aşımları, yetki
  /// ve önbellek interceptor'ları [THttpClient] içinde). Her repository kendi
  /// istemcisini kurmak yerine bu tek nesneyi yeniden kullanır.
  final Dio dio = THttpClient.dio;

  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final String Function(T) _getId;

  int currentPage = 1;
  int pageSize = 20;
  int totalCount = 0;

  TApiRepositoryController({
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  })  : _fromJson = fromJson,
        _toJson = toJson,
        _getId = getId;

  String getEndpoint();

  /// Başarı bayrağını **iki yazımı da** kabul ederek okur: `Success`
  /// (.NET arka ucunun varsayılan serileştirmesi) ya da `success`.
  bool isSuccess(dynamic data) =>
      data is Map && (data['Success'] == true || data['success'] == true);

  /// Mesajı iki yazımı da kabul ederek okur: `Message` ya da `message`.
  String? messageOf(dynamic data) =>
      data is Map ? (data['Message'] ?? data['message']) as String? : null;

  /// Yükü iki yazımı da kabul ederek okur: `Data` ya da `data`.
  dynamic dataOf(dynamic data) => data is Map ? (data['Data'] ?? data['data']) : null;

  T fromJson(Map<String, dynamic> json) => _fromJson(json);
  Map<String, dynamic> toJson(T item) => _toJson(item);
  String getId(T item) => _getId(item);

  Future<List<T>> fetchAllItems() async => throw UnimplementedError('fetchAllItems not implemented');
  Future<T> fetchSingleItem(String id) async => throw UnimplementedError('fetchSingleItem not implemented');
  Future<String> addItem(T item) async => throw UnimplementedError('addItem not implemented');
  Future<void> updateItem(T item) async => throw UnimplementedError('updateItem not implemented');
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async => throw UnimplementedError('updateSingleField not implemented');
  Future<void> deleteItem(T item) async => throw UnimplementedError('deleteItem not implemented');

  Future<List<T>> fetchPaginatedItems(int limit) async {
    pageSize = limit;
    try {
      final response = await dio.get(
        getEndpoint(),
        queryParameters: {
          'page': currentPage,
          'pageSize': pageSize,
        },
      );
      if (response.data['Success'] == true) {
        final List<dynamic> dataList = response.data['Data'] as List<dynamic>;
        totalCount = response.data['TotalCount'] ?? 0;
        currentPage++;
        return dataList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch items';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<void> updateItemRecord(T item) async {
    await updateItem(item);
  }

  dynamic handleException(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) return 'Unauthorized. Please login again.';
          if (statusCode == 403) return 'Access denied.';
          if (statusCode == 404) return 'Resource not found.';
          if (statusCode == 500) {
            // 500 gövdesini mesaja taşı: sunucu çökmesini teşhis edebilmek için.
            final body = e.response?.data;
            final detail = body is Map
                ? (body['Message'] ?? body['message'] ?? body['title'] ?? body.toString())
                : body?.toString() ?? '';
            return 'Server error 500: $detail';
          }
          // 400 / 409 / 422: arka ucun gerçek mesajını yukarı taşı.
          final respData = e.response?.data;
          if (respData is Map) {
            final msg = respData['Message'] ?? respData['message'] ??
                respData['Errors'] ?? respData['errors'] ?? respData['title'];
            if (msg != null) return msg.toString();
          }
          return 'Server error occurred. (HTTP $statusCode)';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error. Please check your connection.';
      }
    }
    if (e is String) return e;
    return 'Something went wrong. Please try again.';
  }
}
