/// Ödeme adımında ve ödenmemiş havale siparişlerinde gösterilen tek banka
/// hesabı (rekvizit). Web ödeme adımının `/bank-details` yanıtıyla birebir.
///
/// 🔴 Hesaplar **şirkete aittir**: her 1C kaynağının kendi satırları var ve
/// müşteri o siparişin şirketinin hesabını görmeli. Şirket alanları bu yüzden
/// modelde taşınıyor.
class BankDetailModel {
  final String id;
  final String bankName;
  final String iban;
  final String beneficiaryName;
  final String bin;
  final String bik;
  final String kbe;
  final bool isActive;

  /// Hesabın sırası (`sortorder`). Sunucu da bu sırayla döndürüyor; istemcide
  /// gruplama yapıldığında sıranın korunması için taşınıyor.
  final int sortOrder;

  /// Hesabın sahibi şirket. `erpSourceCode` müşteri tarafında kullanılan
  /// anahtardır (sepet/sipariş de kodla kırılıyor).
  ///
  /// Boş olabilir: **şirketsiz (NULL) satır** müşteriye zaten dönmüyor
  /// (Faz 30 kapsam kuralı), yine de gelirse hangi siparişe ait olduğu
  /// belirsizdir ve gösterilmez.
  final String erpSourceId;
  final String erpSourceCode;
  final String erpSourceName;

  BankDetailModel({
    required this.id,
    required this.bankName,
    required this.iban,
    required this.beneficiaryName,
    required this.bin,
    required this.bik,
    required this.kbe,
    required this.isActive,
    this.sortOrder = 0,
    this.erpSourceId = '',
    this.erpSourceCode = '',
    this.erpSourceName = '',
  });

  factory BankDetailModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    return BankDetailModel(
      // Sunucu birincil anahtarı `bankDetailId` adıyla döndürüyor; `id` yalnız
      // eski/farklı serileştirmeler için yedek.
      id: (json['bankDetailId'] ?? json['BankDetailId'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      bankName: json['bankName'] ?? json['BankName'] ?? '',
      iban: json['iban'] ?? json['Iban'] ?? '',
      beneficiaryName: json['beneficiaryName'] ?? json['BeneficiaryName'] ?? '',
      bin: json['bin'] ?? json['Bin'] ?? '',
      bik: json['bik'] ?? json['Bik'] ?? '',
      kbe: json['kbe'] ?? json['Kbe'] ?? '',
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
      sortOrder: asInt(json['sortOrder'] ?? json['SortOrder']),
      // Savunmacı (kabul kriteri 6): Faz 30 öncesi API bu alanları hiç
      // göndermiyor. O durumda kod boş kalır ve gruplama "şirket çözülemedi"
      // dalına düşer — uygulama yine açılır.
      erpSourceId: (json['erpSourceId'] ?? json['ErpSourceId'] ?? '').toString(),
      erpSourceCode: (json['erpSourceCode'] ?? json['ErpSourceCode'] ?? '').toString(),
      erpSourceName: (json['erpSourceName'] ?? json['ErpSourceName'] ?? '').toString(),
    );
  }

  /// Splits a "(KZT)"-style currency suffix off the bank name, matching the
  /// web checkout's `splitBankCurrency`. Returns the cleaned name and the
  /// currency code (null when the name has no suffix).
  ({String name, String? currency}) get nameAndCurrency {
    final match = RegExp(r'^(.*?)\s*\(([A-Z]{3})\)\s*$').firstMatch(bankName);
    if (match != null) return (name: match.group(1)!, currency: match.group(2));
    return (name: bankName, currency: null);
  }

  /// Para birimi anahtarı; eki olmayan hesaplar "OTHER" kovasına düşer.
  String get currencyKey => nameAndCurrency.currency ?? 'OTHER';
}
