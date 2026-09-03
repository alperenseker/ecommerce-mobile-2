/// Yönetici tarafından belirlenen genel mağaza ayarları (puan katsayıları,
/// kargo, para birimi …). Yetki ister; `settings/public` ile karıştırma —
/// o anonimdir ve yalnız üç anahtarı taşır ([PublicSettingsController]).
library;

import 'package:get/get.dart';

import '../../../data/repositories/settings/api_settings_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/setting_model.dart';

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

// Observable variables
  RxBool loading = false.obs;
  Rx<SettingsModel> settings = SettingsModel().obs;
  final settingRepository = ApiSettingsRepository.instance;

  @override
  Future<void> onInit() async {
    // Fetch setting details on controller initialization
    await fetchSettingDetails();
    super.onInit();
  }

  /// Fetches setting details from the repository
  Future<void> fetchSettingDetails() async {
    try {
      loading.value = true;
      final settings = await settingRepository.getSettings();
      this.settings.value = settings;
      loading.value = false;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.somethingWentWrong.tr, message: e.toString());
    }
  }
}
