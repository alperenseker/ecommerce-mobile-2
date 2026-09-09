import 'package:dio/dio.dart';

import '../../../features/shop/models/bank_detail_model.dart';
import '../../../utils/http/dio_client.dart';

/// Havale rekvizitlerini `GET /bank-details` ucundan çeker (web ödeme adımının
/// kullandığı uç).
///
/// 🔴 Hesaplar **şirkete aittir**: her 1C kaynağının kendi satırları var ve
/// müşteri o siparişin şirketinin hesabını görmeli. Süzgeçsiz çağrıda 12 satır
/// döner (3 şirket × 4 hesap); ekran **daima şirkete göre gruplamalı**, yoksa
/// müşteri yanlış hesaba para yatırır. Uç `?erpSource=<kod|kimlik>` ile de
/// süzülebilir.
class ApiBankDetailsRepository {
  final Dio _dio = THttpClient.dio;

  /// Aktif hesapları getirir. [erpSource] verilirse **sunucu** süzer.
  ///
  /// Çözülemeyen bir şirket kodu 404 değil **200 + boş liste** döndürüyor
  /// (Faz 30 kararı) — yazım hatası müşteride hata ekranı açmasın.
  Future<List<BankDetailModel>> fetchActiveBankDetails({String? erpSource}) async {
    final response = await _dio.get(
      'bank-details',
      queryParameters: (erpSource != null && erpSource.trim().isNotEmpty)
          ? {'erpSource': erpSource.trim()}
          : null,
    );
    final data = response.data;
    final list = (data is Map ? (data['Data'] ?? data['data']) : null) as List<dynamic>? ?? [];
    final rows = list
        .map((json) => BankDetailModel.fromJson(json as Map<String, dynamic>))
        .where((b) => b.isActive)
        .toList();
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows;
  }

  /// Aktif hesapları **şirket koduna göre** indeksler.
  ///
  /// 🔴 Hata durumunda `null` döner, boş harita değil: "hesap yok" ile
  /// "okunamadı" ayrı şeylerdir. `{}` dönseydi bir ağ hatası ekranda
  /// "bu şirketin hesabı yok" diye görünürdü — müşteriyi yanlış yönlendiren
  /// bir yalan olurdu (Faz 32'nin web tarafında verilmiş kararı).
  ///
  /// [erpSource] verilirse sunucu süzer (tek şirketli ekran → küçük yanıt);
  /// verilmezse tek çağrı çekilip istemcide gruplanır (çok şirketli sepette
  /// üç ayrı istek yerine bir istek).
  Future<Map<String, List<BankDetailModel>>?> fetchByCompany({String? erpSource}) async {
    try {
      final rows = await fetchActiveBankDetails(erpSource: erpSource);
      final byCompany = <String, List<BankDetailModel>>{};
      for (final row in rows) {
        final code = row.erpSourceCode.trim().toLowerCase();
        // Şirketsiz satır hangi siparişe ait belli değil — atlanır.
        if (code.isEmpty) continue;
        byCompany.putIfAbsent(code, () => <BankDetailModel>[]).add(row);
      }
      return byCompany;
    } catch (_) {
      return null;
    }
  }
}
