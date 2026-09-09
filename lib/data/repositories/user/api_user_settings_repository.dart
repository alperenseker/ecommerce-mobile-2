import 'package:get/get.dart';
import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';

import '../../../features/personalization/models/user_settings_model.dart';
import 'user_settings_repository.dart';

/// Kullanıcının **ticari** ayarlarını getirir (`usersettings/{userId}`).
///
/// Bunlar yöneticinin verdiği yetkilerdir: stoksuz sipariş (`CanOrderWithoutStock`),
/// kredi limiti (`HasCreditLine`, `CreditLimit`, `UsedCredit`), minimum sipariş
/// tutarı ve fiyat kategorisi. Ekranların kapıları buna bakar; çağrı başarısızsa
/// kısıtlayıcı varsayılana düşülür.
class ApiUserSettingsRepository extends TApiRepositoryController<UserSettingsModel>
    implements UserSettingsRepository {

  static ApiUserSettingsRepository get instance => Get.find();

  ApiUserSettingsRepository() : super(
    fromJson: (json) => UserSettingsModel.fromJson(json),
    toJson: (settings) => settings.toJson(),
    getId: (settings) => settings.id ?? '',
  );

  @override
  String getEndpoint() => 'usersettings';

  /// Kullanıcıya özel ayarları getir (fiyat kategorisi, kredi limiti, stoksuz
  /// sipariş izni vb.). Backend ilk erişimde otomatik oluşturur.
  @override
  Future<UserSettingsModel> getUserSettings(String userId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$userId');

      if (isSuccess(response.data)) {
        return UserSettingsModel.fromJson(dataOf(response.data) ?? {});
      } else {
        throw messageOf(response.data) ?? 'Failed to fetch user settings';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
