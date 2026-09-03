/// Adres repository'sinin arayüzü — uygulaması `api_address_repository.dart`.
library;

import '../../../features/personalization/models/address_model.dart';

abstract class AddressRepository {
  Future<List<AddressModel>> fetchUserAddresses(String userId);
  Future<AddressModel> fetchSingleAddress(String addressId);
  Future<AddressModel> createAddress(AddressModel address);
  Future<AddressModel> updateAddress(AddressModel address);
  Future<bool> deleteAddress(String addressId);
  Future<AddressModel> setDefaultAddress(String addressId);
}
