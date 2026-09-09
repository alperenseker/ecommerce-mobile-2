import '../../../features/personalization/models/user_settings_model.dart';

/// Kullanıcının yönetici tarafından yönetilen ticari ayarları için sözleşme.
abstract class UserSettingsRepository {
  /// Fetch the settings for [userId] from `GET /api/usersettings/{userId}`.
  Future<UserSettingsModel> getUserSettings(String userId);
}
