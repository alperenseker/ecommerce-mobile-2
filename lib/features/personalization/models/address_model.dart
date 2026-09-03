/// Teslimat / fatura adresi.
///
/// Sunucu `FirstName` ve `LastName`'i ayrı tutar; ekrandaki tek "ad soyad"
/// alanına çeviri bu modelde yapılır.
library;

import '../../../utils/formatters/formatter.dart';



class AddressModel {
  String id;
  final String name;
  final String firstName;
  final String lastName;
  final String company;
  final String email;
  final String phoneNumber;
  final String street;
  final String addressLine2;
  final String city;
  final String district;
  final String neighborhood;
  final String state;
  final String postalCode;
  final String country;
  final String addressType;
  final bool isActive;
  final DateTime? createdAt;
  bool selectedAddress;

  AddressModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.firstName = '',
    this.lastName = '',
    this.company = '',
    this.email = '',
    this.addressLine2 = '',
    this.district = '',
    this.neighborhood = '',
    this.addressType = 'shipping',
    this.isActive = true,
    this.createdAt,
    this.selectedAddress = true,
  });

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  bool get isBilling => addressType.toLowerCase() == 'billing';

  static AddressModel empty() =>
      AddressModel(id: '', name: '', phoneNumber: '', street: '', city: '', state: '', postalCode: '', country: '');

  /// Serializes to the field names the .NET backend expects.
  /// 'userId' is injected by the repository layer (requires auth context).
  Map<String, dynamic> toJson() {
    // If firstName/lastName are available use them; otherwise split the full name.
    final parts = name.trim().split(RegExp(r'\s+'));
    final fName = firstName.isNotEmpty ? firstName : (parts.isNotEmpty ? parts.first : '');
    final lName = lastName.isNotEmpty ? lastName : (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    return {
      'addressType': addressType,
      'title': company,          // backend: Title
      'firstName': fName,        // backend: FirstName
      'lastName': lName,         // backend: LastName
      'phone': phoneNumber,      // backend: Phone
      'email': email,
      'country': country,
      'city': city,
      'district': district.isNotEmpty ? district : state, // backend: District
      'neighborhood': neighborhood,
      'addressLine1': street,    // backend: AddressLine1
      'addressLine2': addressLine2,
      'postalCode': postalCode,
      'isDefault': selectedAddress, // backend: IsDefault
      // 'userId' injected by repository
    };
  }

  /// Create an AddressModel from a JSON Map.
  ///
  /// Tolerant of the .NET backend's PascalCase keys (`FirstName`, `City`,
  /// `AddressLine1`, ...) as well as the legacy lowercase keys (`name`,
  /// `city`, `street`, ...) so both old and new payloads parse correctly.
  factory AddressModel.fromJson(String id, Map<String, dynamic> data) {
    /// Returns the first non-null value among [keys] as a String.
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
      return '';
    }

    final firstName = pick(['FirstName', 'firstName']);
    final lastName = pick(['LastName', 'lastName']);
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    final resolvedId = id.isNotEmpty ? id : pick(['AddressId', 'addressId', 'id']);

    return AddressModel(
      id: resolvedId,
      firstName: firstName,
      lastName: lastName,
      name: pick(['name']).isNotEmpty ? pick(['name']) : fullName,
      company: pick(['Title', 'company']),
      email: pick(['Email', 'email']),
      phoneNumber: pick(['Phone', 'phone', 'phoneNumber']),
      street: pick(['AddressLine1', 'addressLine1', 'street']),
      addressLine2: pick(['AddressLine2', 'addressLine2']),
      city: pick(['City', 'city']),
      district: pick(['District', 'district']),
      neighborhood: pick(['Neighborhood', 'neighborhood']),
      state: pick(['District', 'district', 'State', 'state']),
      postalCode: pick(['PostalCode', 'postalCode', 'postcode']),
      country: pick(['Country', 'country']),
      addressType: pick(['AddressType', 'addressType']).isNotEmpty ? pick(['AddressType', 'addressType']) : 'shipping',
      isActive: (data['IsActive'] ?? data['isActive'] ?? true) as bool,
      selectedAddress: (data['IsDefault'] ?? data['isDefault'] ?? data['selectedAddress'] ?? false) as bool,
      createdAt: DateTime.tryParse(pick(['CreatedAt', 'createdAt'])) ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return '$street, $city, $state $postalCode, $country';
  }
}
