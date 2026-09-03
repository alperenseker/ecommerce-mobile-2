/// Adres uçları (`Address/...`).
///
/// Sunucu `FirstName`/`LastName`'i ayrı tutar; ekranda tek "ad soyad" alanı
/// vardır, çeviri tek yerde yapılır.
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../features/personalization/models/address_model.dart';
import '../authentication/authentication_repository.dart';
import 'address_repository.dart';

class ApiAddressRepository extends TApiRepositoryController<AddressModel>
    implements AddressRepository {

  static ApiAddressRepository get instance => Get.find();

  ApiAddressRepository()
      : super(
          fromJson: (json) => AddressModel.fromJson(json['id']?.toString() ?? '', json),
          toJson: (address) => address.toJson(),
          getId: (address) => address.id,
        );

  @override
  String getEndpoint() => 'address';

  /// Kullanıcıya ait tüm adresleri getir
  @override
  Future<List<AddressModel>> fetchUserAddresses(String userId) async {
    try {
      // print('🌐 [AddressRepository] Fetching addresses for userId: $userId');
      final response = await dio.get('${getEndpoint()}/user/$userId');

      // DEBUG: raw server payload to verify field names/casing
      // print('🧾 [AddressRepository] Raw response.data: ${response.data}');

      if (isSuccess(response.data)) {
        final List<dynamic> dataList = (dataOf(response.data) as List<dynamic>?) ?? [];
        // print('📍 [AddressRepository] Fetched ${dataList.length} addresses');
        if (dataList.isNotEmpty) {
          // print('🧾 [AddressRepository] First address json: ${dataList.first}');
        }
        return dataList
            .map((json) => AddressModel.fromJson(
                  (json as Map<String, dynamic>)['AddressId']?.toString() ?? json['id']?.toString() ?? '',
                  json,
                ))
            .toList();
      } else {
        throw messageOf(response.data) ?? 'Failed to fetch addresses';
      }
    } on DioException catch (e) {
      // print('❌ [AddressRepository] DioException: $e');
      throw handleException(e);
    } catch (e) {
      // print('❌ [AddressRepository] Exception: $e');
      throw handleException(e);
    }
  }

  /// Fetches the company's official registered address by IIN, used as the
  /// (locked) billing address for corporate accounts: GET /company/{iin}.
  ///
  /// Returns null on any failure so the UI can fall back gracefully.
  Future<AddressModel?> fetchCompanyBillingAddress(String iin) async {
    try {
      // print('🏢 [AddressRepository] Fetching company info for iin: $iin');
      final response = await dio.get('company/$iin');

      // DEBUG: raw payload to verify the /company/{iin} field names/casing
      // print('🧾 [AddressRepository] Company raw response.data: ${response.data}');

      final raw = isSuccess(response.data) ? dataOf(response.data) : response.data;
      if (raw is Map<String, dynamic>) {
        // /company/{iin} returns: { nameRu, director, address }
        // Map to AddressModel: company name → company, address string → street.
        return AddressModel(
          id: iin,
          name: raw['director']?.toString() ?? '',
          company: raw['nameRu']?.toString() ?? '',
          street: raw['address']?.toString() ?? '',
          phoneNumber: '',
          city: '',
          state: '',
          postalCode: '',
          country: '',
          selectedAddress: false,
          addressType: 'billing',
          isActive: true,
        );
      }
      return null;
    } on DioException catch (e) {
      // print('❌ [AddressRepository] Company DioException: $e');
      return null;
    } catch (e) {
      // print('❌ [AddressRepository] Company Exception: $e');
      return null;
    }
  }

  /// Tek bir adresi getir
  @override
  Future<AddressModel> fetchSingleAddress(String addressId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$addressId');

      if (response.data['Success'] == true) {
        final data = response.data['Data'] as Map<String, dynamic>;
        return AddressModel.fromJson(data['id']?.toString() ?? '', data);
      } else {
        throw response.data['Message'] ?? 'Failed to fetch address';
      }
    } on DioException catch (e) {
      throw handleException(e);
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Yeni adres oluştur
  @override
  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      final response = await dio.post(
        getEndpoint(),
        data: address.toJson(),
      );

      if (response.data['Success'] == true) {
        // print('✅ [AddressRepository] Address created successfully');
        final d = response.data['Data'] as Map<String, dynamic>;
        return AddressModel.fromJson(d['id']?.toString() ?? '', d);
      } else {
        throw response.data['Message'] ?? 'Failed to create address';
      }
    } on DioException catch (e) {
      throw handleException(e);
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Mevcut adresi güncelle
  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    try {
      final userId = AuthenticationRepository.instance.getUserID;
      final data = address.toJson()
        ..['userId'] = userId
        ..['addressId'] = address.id;

      // print('🌐 [AddressRepository] PUT ${getEndpoint()}/${address.id}');
      // print('📤 [AddressRepository] Request payload: $data');

      final response = await dio.put(
        '${getEndpoint()}/${address.id}',
        data: data,
      );

      // print('📥 [AddressRepository] Response status: ${response.statusCode}');
      // print('📥 [AddressRepository] Response data: ${response.data}');

      final respMap = response.data as Map<String, dynamic>;
      final success = respMap['Success'] ?? respMap['success'];
      if (success == true) {
        // print('✅ [AddressRepository] Address updated successfully');
        final d = (respMap['Data'] ?? respMap['data']) as Map<String, dynamic>;
        return AddressModel.fromJson(d['AddressId']?.toString() ?? d['id']?.toString() ?? '', d);
      } else {
        final msg = respMap['Message'] ?? respMap['message'] ?? 'Failed to update address';
        // print('❌ [AddressRepository] Update failed: $msg');
        throw msg;
      }
    } on DioException catch (e) {
      // print('❌ [AddressRepository] DioException on update: $e');
      // print('❌ [AddressRepository] Response body: ${e.response?.data}');
      throw handleException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Adresi sil (soft delete)
  @override
  Future<bool> deleteAddress(String addressId) async {
    try {
      final response = await dio.delete('${getEndpoint()}/$addressId');

      if (response.data['Success'] == true) {
        // print('✅ [AddressRepository] Address deleted successfully');
        return response.data['Data'] ?? true;
      } else {
        throw response.data['Message'] ?? 'Failed to delete address';
      }
    } on DioException catch (e) {
      throw handleException(e);
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Varsayılan adresi ayarla
  @override
  Future<AddressModel> setDefaultAddress(String addressId) async {
    try {
      final response = await dio.put('${getEndpoint()}/$addressId/set-default');

      if (response.data['Success'] == true) {
        // print('✅ [AddressRepository] Default address set successfully');
        final d = response.data['Data'] as Map<String, dynamic>;
        return AddressModel.fromJson(d['id']?.toString() ?? '', d);
      } else {
        throw response.data['Message'] ?? 'Failed to set default address';
      }
    } on DioException catch (e) {
      throw handleException(e);
    } catch (e) {
      throw handleException(e);
    }
  }
}