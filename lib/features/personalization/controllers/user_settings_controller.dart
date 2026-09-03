/// Giriş yapmış kullanıcının yöneticiye bağlı ticari ayarları (stoksuz
/// sipariş, kredi limiti, fiyat kategorisi, özel indirim).
library;

import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/api_user_settings_repository.dart';
import '../models/user_settings_model.dart';

/// Holds the logged-in user's admin-managed commercial settings and exposes
/// them app-wide (stock override, credit limit, price tier, custom discount).
///
/// Varsayılanlar **bilerek en kısıtlayıcı** hâldedir (stoksuz sipariş yok,
/// kredi yok): gerçek ayarlar gelene kadar ya da çağrı başarısız olduğunda
/// davranış güvenli tarafta kalır. Yetki çağrısının başarısız olması girişi
/// bozmaz.
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

  /// FAZ 34 — müşterinin gerçekten kendi kredi satırı var mı.
  ///
  /// [canBypassPayment] `transfer_only` modunda **herkes için** true dönüyor
  /// (K29.7); "kredili müşteri" ile "ödeme genel olarak kapalı" ayrımı yalnız
  /// bununla yapılabilir.
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
      // Hata hâlinde güvenli varsayılanlarda kalınır — ayarlar yüzünden
      // uygulama asla bloklanmaz.
      settings.value = UserSettingsModel.empty();
    } finally {
      loading.value = false;
    }
  }

  /// Reset to defaults on logout.
  void clear() => settings.value = UserSettingsModel.empty();
}
