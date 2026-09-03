/// Kullanıcı profili uçları (`users/{id}`).
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/personalization/models/user_model.dart';
import '../../../features/shop/models/order_model.dart';
import '../../../utils/constants/enums.dart';
import 'user_repository.dart';

class ApiUserRepository extends TApiRepositoryController<UserModel>
    implements UserRepository {

  static ApiUserRepository get instance => Get.find();

  ApiUserRepository() : super(
    fromJson: (json) => UserModel.fromJson(json['userId']?.toString() ?? json['id']?.toString() ?? '', json),
    toJson: (user) => user.toJson(),
    getId: (user) => user.id,
  );

  @override
  String getEndpoint() => 'users';

  int _currentOffset = 0;
  Map<String, dynamic>? _lastFilterParams;

  /// Yeni kullanıcı ekle (Admin registration)
  @override
  Future<String> addItem(UserModel item) async {
    try {
      final response = await dio.post(
        'auth/register',
        data: {
          'name': item.firstName,
          'surname': item.lastName,
          'email': item.email,
          'phone': item.phoneNumber,
          'profileImage': item.profilePicture,
          'password': 'TempPass123!',
        },
      );

      if (response.data['success'] == true) {
        return response.data['userId'];
      } else {
        throw response.data['message'] ?? 'Failed to create user';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Tüm kullanıcıları getir
  @override
  Future<List<UserModel>> fetchAllItems() async {
    try {
      final response = await dio.get(
        getEndpoint(),
        queryParameters: {
          'limit': 1000,
          'role': AppRole.user.name,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> usersJson = response.data['data'] ?? [];
        return usersJson
            .map((json) => UserModel.fromJson(
                  (json['userId'] ?? json['id'] ?? '').toString(),
                  json as Map<String, dynamic>,
                ))
            .toList();
      } else {
        throw response.data['message'] ?? 'Failed to fetch users';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Tek kullanıcı getir
  @override
  Future<UserModel> fetchSingleItem(String id) async {
    try {
      final response = await dio.get('${getEndpoint()}/$id');

      if (response.data['success'] == true) {
        return UserModel.fromJson(id, response.data['data']);
      } else {
        throw response.data['message'] ?? 'Failed to fetch user';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kullanıcı güncelle
  @override
  Future<void> updateItem(UserModel item) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/${item.id}',
        data: {
          'name': item.firstName,
          'surname': item.lastName,
          'userName': item.userName,
          'phone': item.phoneNumber,
          'profileImage': item.profilePicture,
          'role': item.role.name,
          'isActive': item.isProfileActive,
          'isEmailVerified': item.isEmailVerified,
          'points': item.points,
          'orderCount': item.orderCount,
          'deviceToken': item.deviceToken,
          'verificationStatus': item.verificationStatus.name,
        },
      );

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to update user';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Belirli alanları güncelle
  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$id/fields',
        data: {'fields': json},
      );

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to update fields';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kullanıcı sil
  @override
  Future<void> deleteItem(UserModel item) async {
    try {
      final response = await dio.delete('${getEndpoint()}/${item.id}');

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to delete user';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kullanıcının siparişlerini getir
  @override
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      final response = await dio.get('order/user/$userId');

      if (response.data['Success'] == true || response.data['success'] == true) {
        final List<dynamic> ordersJson = response.data['Data'] ?? response.data['data'] ?? [];
        return ordersJson
            .map((json) => OrderModel.fromJson('', json as Map<String, dynamic>))
            .toList();
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to fetch user orders';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Admin kaydı
  @override
  Future<void> registerAdmin(UserModel user) async {
    try {
      final response = await dio.post(
        'auth/register',
        data: {
          'name': user.firstName,
          'surname': user.lastName,
          'email': user.email,
          'phone': user.phoneNumber,
          'profileImage': user.profilePicture,
          'password': 'AdminPass123!',
        },
      );

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to register admin';
      }

      final userId = response.data['userId'];
      await updateSingleField(userId, {'role': 'admin'});
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Kullanıcı puanlarını güncelle
  @override
  Future<void> updateUserPoints(String userId, int pointsToAdd) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$userId/points',
        data: {'pointsToAdd': pointsToAdd},
      );

      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to update points';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Filtrelenmiş ve sayfalanmış kullanıcıları getir
  @override
  Future<List<UserModel>> fetchFilteredPaginatedItems({
    required int limit,
    Map<String, dynamic>? isEqualTo,
    Map<String, dynamic>? isNotEqualTo,
    Map<String, Iterable<Object?>?>? arrayContainsAny,
    Map<String, Iterable<Object?>?>? whereIn,
    Map<String, bool>? isNull,
  }) async {
    try {
      final currentFilterParams = {
        'isEqualTo': isEqualTo,
        'isNotEqualTo': isNotEqualTo,
        'arrayContainsAny': arrayContainsAny,
        'whereIn': whereIn,
        'isNull': isNull,
      };

      if (_lastFilterParams.toString() != currentFilterParams.toString()) {
        _currentOffset = 0;
        _lastFilterParams = currentFilterParams;
      }

      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': _currentOffset,
      };

      isEqualTo?.forEach((field, value) {
        queryParams[field] = value;
      });

      if (isNotEqualTo != null && isNotEqualTo.isNotEmpty) {
        queryParams['notEqual'] = isNotEqualTo.entries
            .map((e) => '${e.key}:${e.value}')
            .join(',');
      }

      if (arrayContainsAny != null && arrayContainsAny.isNotEmpty) {
        arrayContainsAny.forEach((field, values) {
          if (values != null) {
            queryParams['arrayContains_$field'] = values.join(',');
          }
        });
      }

      if (whereIn != null && whereIn.isNotEmpty) {
        whereIn.forEach((field, values) {
          if (values != null) {
            queryParams['in_$field'] = values.join(',');
          }
        });
      }

      if (isNull != null && isNull.isNotEmpty) {
        isNull.forEach((field, value) {
          queryParams['null_$field'] = value;
        });
      }

      final response = await dio.get(
        '${getEndpoint()}/filtered',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> usersJson = response.data['data'] ?? [];

        if (usersJson.isNotEmpty) {
          _currentOffset += usersJson.length;
        }

        return usersJson
            .map((json) => UserModel.fromJson(
                  (json['userId'] ?? json['id'] ?? '').toString(),
                  json as Map<String, dynamic>,
                ))
            .toList();
      } else {
        throw response.data['message'] ?? 'Failed to fetch filtered users';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  void resetPagination() {
    _currentOffset = 0;
    _lastFilterParams = null;
  }

  @override
  Future<void> removeUserRecord(String userId) async {
    try {
      final response = await dio.delete('${getEndpoint()}/$userId');
      if (response.data['success'] != true) {
        throw response.data['message'] ?? 'Failed to remove user record';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  Future<List<UserModel>> searchByEmail(String email) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/search/by-email',
        queryParameters: {'email': email},
      );

      if (response.data['success'] == true) {
        final List<dynamic> usersJson = response.data['data'] ?? [];
        return usersJson
            .map((json) => UserModel.fromJson(
                  (json['userId'] ?? json['id'] ?? '').toString(),
                  json as Map<String, dynamic>,
                ))
            .toList();
      } else {
        throw response.data['message'] ?? 'Failed to search users by email';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
