/// Ayar repository'sinin arayüzü.
library;

import '../../../features/personalization/models/setting_model.dart';

abstract class SettingsRepository {
  Future<SettingsModel> getSettings();
  Future<void> registerSettings(SettingsModel setting);
  Future<void> updateSettingDetails(SettingsModel updatedSetting);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
}
