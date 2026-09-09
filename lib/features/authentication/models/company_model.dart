/// `/company/{iin}` sicil sorgusundan dönen şirket bilgisi.
///
/// Şirket kaydı sırasında resmî kaydı doğrulamak için kullanılır. Alan adları
/// web istemcisiyle aynı (`nameRu`, `director`, `address`); sunucu toleransı için
/// PascalCase yazımları da okunur.
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
