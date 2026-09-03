/// İade talebi uçları.
library;

import 'package:get/get.dart';

import '../../../features/shop/models/return_request_model.dart';
import '../../../utils/constants/enums.dart';

/// TODO: backend'de /return-requests endpoint'i yok. Eklenince dio ile bu
/// metodları gerçek isteklere bağlayın (bkz. ApiCategoryRepository deseni).
class ApiReturnRepository extends GetxController {
  static ApiReturnRepository get instance => Get.isRegistered<ApiReturnRepository>() ? Get.find() : Get.put(ApiReturnRepository());

  Future<List<ReturnRequest>> fetchAllItems() async => [];

  Future<ReturnRequest> getSingleItem(String id) async => ReturnRequest.empty();

  Future<String> addNewItem(ReturnRequest item) async {
    throw UnsupportedError('İade talebi oluşturma backend tarafında henüz desteklenmiyor.');
  }

  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {}

  Future<List<ReturnRequest>> getReturnRequestsByStatus(ReturnStatus status) async => [];

  Future<List<ReturnRequest>> getReturnRequestsByUserId(String userId) async => [];

  Future<List<ReturnRequest>> getReturnRequestsByOrderId(String orderId) async => [];

  Stream<List<ReturnRequest>> getReturnRequestsStream() => Stream.value(const []);

  Stream<ReturnRequest?> getReturnRequestStream(String requestId) => Stream.value(null);

  Future<Map<String, int>> getReturnStatistics() async => {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'refunded': 0,
        'exchanged': 0,
      };

  Future<int> getReturnCountByStatus(ReturnStatus status) async => 0;
}
