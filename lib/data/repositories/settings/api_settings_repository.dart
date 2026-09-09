import 'package:dio/dio.dart';
import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/personalization/models/public_settings_model.dart';
import '../../../features/personalization/models/setting_model.dart';
import 'setting_repository.dart';

/// Genel ayar uçları (`settings`, `settings/public`).
class ApiSettingsRepository extends TApiRepositoryController<SettingsModel>
    implements SettingsRepository {

  static ApiSettingsRepository get instance => Get.find();

  ApiSettingsRepository() : super(
    fromJson: (json) => SettingsModel.fromJson(json),
    toJson: (setting) => setting.toJson(),
    getId: (setting) => setting.id ?? '',
  );

  @override
  String getEndpoint() => 'settings';

  /// Global ayarları getir
  @override
  Future<SettingsModel> getSettings() async {
    try {
      final response = await dio.get(getEndpoint());

      if (isSuccess(response.data)) {
        return SettingsModel.fromJson(dataOf(response.data));
      } else {
        throw messageOf(response.data) ?? 'Failed to fetch settings';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// FAZ 34 — üç genel anahtar (**anonim uç**): `GET /api/settings/public`.
  ///
  /// Kayıt ekranı tanımı gereği anonimdir, `getSettings()`in çağırdığı
  /// `GET /api/settings` ise `[Authorize]` istiyor (Faz 29). Bu yüzden ayrı
  /// bir uç var ve çağrı **token olmadan** yapılıyor (`skip_auth`).
  ///
  /// 🔴 Hata yutulmuyor, çağırana bırakılıyor: "bugünkü davranışa düşme"
  /// kuralı [PublicSettingsController]'da tek yerde uygulanıyor.
  Future<PublicSettingsModel> getPublicSettings({bool forceRefresh = false}) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/public',
        options: Options(extra: {
          'skip_auth': true,
          // Anahtar superAdmin tarafından çevrildiğinde bayat değer müşteriyi
          // yanlış ekrana sokar; kritik anlarda (sipariş oluşturma) önbellek
          // atlanır.
          if (forceRefresh) 'no_cache': true,
        }),
      );

      if (isSuccess(response.data)) {
        final data = dataOf(response.data);
        if (data is Map) {
          return PublicSettingsModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw messageOf(response.data) ?? 'Failed to fetch public settings';
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Global ayarları oluştur/kaydet
  @override
  Future<void> registerSettings(SettingsModel setting) async {
    try {
      final response = await dio.post(
        getEndpoint(),
        data: setting.toJson(),
      );

      if (!isSuccess(response.data)) {
        throw messageOf(response.data) ?? 'Failed to create settings';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Global ayarları güncelle
  @override
  Future<void> updateSettingDetails(SettingsModel updatedSetting) async {
    try {
      final response = await dio.put(
        getEndpoint(),
        data: updatedSetting.toJson(),
      );

      if (!isSuccess(response.data)) {
        throw messageOf(response.data) ?? 'Failed to update settings';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  /// Belirli bir alanı güncelle
  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$id',
        data: json,
      );

      if (!isSuccess(response.data)) {
        throw messageOf(response.data) ?? 'Failed to update field';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
