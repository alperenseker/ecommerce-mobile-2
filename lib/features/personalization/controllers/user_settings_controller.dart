import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/api_user_settings_repository.dart';
import '../models/user_settings_model.dart';

/// Giriş yapan kullanıcının **yönetici tarafından verilen ticari yetkileri**:
/// stok aşımı, kredi limiti, fiyat kategorisi, özel iskonto.
///
/// 🔴 Varsayılanlar bilerek **en kısıtlayıcı**: stoksuz sipariş yok, kredi yok.
/// Yetki çağrısı başarısız olsa bile uygulama çalışmaya devam eder ama
/// müşteriye hak etmediği bir yetki verilmez — bu yüzden [fetchUserSettings]
/// hatayı yukarı fırlatmaz, sessizce varsayılana döner.
class UserSettingsController extends GetxController {
  static UserSettingsController get instance => Get.find();

  final RxBool loading = false.obs;
  final Rx<UserSettingsModel> settings = UserSettingsModel.empty().obs;

  ApiUserSettingsRepository get _repository => Get.isRegistered<ApiUserSettingsRepository>()
      ? ApiUserSettingsRepository.instance
      : Get.put(ApiUserSettingsRepository());

  /// Convenience getters used across cart / checkout / profile.
  bool get canOrderWithoutStock => settings.value.canOrderWithoutStock;
  bool get canBypassPayment => settings.value.canBypassPayment;

  /// Müşterinin gerçekten kendi kredi satırı var mı.
  ///
  /// [canBypassPayment] `transfer_only` modunda **herkes için** true dönüyor;
  /// "kredili müşteri" ile "ödeme genel olarak kapalı" ayrımı yalnız bununla
  /// yapılabilir.
  bool get hasCreditLine => settings.value.hasCreditLine;
  String get priceCategory => settings.value.priceCategory;
  bool get hasCreditLimit => settings.value.hasCreditLimit;
  double get creditLimit => settings.value.creditLimit;
  double get usedCredit => settings.value.usedCredit;
  double get availableCredit => settings.value.availableCredit;
  double get customDiscountRate => settings.value.customDiscountRate;
  double get minimumOrderAmount => settings.value.minimumOrderAmount;

  @override
  void onInit() {
    fetchUserSettings();
    super.onInit();
  }

  /// Fetch the current user's settings. No-op for guests / logged-out users.
  Future<void> fetchUserSettings() async {
    final userId = AuthenticationRepository.instance.getUserID;
    if (userId.isEmpty) {
      settings.value = UserSettingsModel.empty();
      return;
    }

    try {
      loading.value = true;
      settings.value = await _repository.getUserSettings(userId);
    } catch (_) {
      // Hata hâlinde güvenli varsayılan korunur — ayar yüzünden uygulama
      // durdurulmaz.
      settings.value = UserSettingsModel.empty();
    } finally {
      loading.value = false;
    }
  }

  /// Reset to defaults on logout.
  void clear() => settings.value = UserSettingsModel.empty();
}
