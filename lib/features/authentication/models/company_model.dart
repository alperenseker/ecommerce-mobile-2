/// Company information returned by the `/company/{iin}` registry lookup.
///
/// Used during company sign-up to confirm the official record before creating
/// the account. Field names mirror the web client (`nameRu`, `director`,
/// `address`) but we read PascalCase variants too for backend tolerance.
class CompanyModel {
  final String iin;
  final String nameRu;
  final String director;
  final String address;

  const CompanyModel({
    this.iin = '',
    this.nameRu = '',
    this.director = '',
    this.address = '',
  });

  bool get isEmpty => nameRu.isEmpty && director.isEmpty;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      iin: (json['iin'] ?? json['Iin'] ?? json['IIN'] ?? '').toString(),
      nameRu: (json['nameRu'] ?? json['NameRu'] ?? json['name'] ?? json['Name'] ?? '').toString(),
      director: (json['director'] ?? json['Director'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
    );
  }
}
