import '../../../features/personalization/models/setting_model.dart';

/// Ayar repository sözleşmesi.
abstract class SettingsRepository {
  Future<SettingsModel> getSettings();
  Future<void> registerSettings(SettingsModel setting);
  Future<void> updateSettingDetails(SettingsModel updatedSetting);
  Future<void> updateSingleField(String id, Map<String, dynamic> json);
}
