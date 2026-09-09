import '../../../features/personalization/models/address_model.dart';

/// Adres repository sözleşmesi.
abstract class AddressRepository {
  Future<List<AddressModel>> fetchUserAddresses(String userId);
  Future<AddressModel> fetchSingleAddress(String addressId);
  Future<AddressModel> createAddress(AddressModel address);
  Future<AddressModel> updateAddress(AddressModel address);
  Future<bool> deleteAddress(String addressId);
  Future<AddressModel> setDefaultAddress(String addressId);
}
