/// Kullanıcı ticari ayarları repository'sinin arayüzü.
library;

import '../../../features/personalization/models/user_settings_model.dart';

/// Contract for fetching a user's admin-managed commercial settings.
abstract class UserSettingsRepository {
  /// Fetch the settings for [userId] from `GET /api/usersettings/{userId}`.
  Future<UserSettingsModel> getUserSettings(String userId);
}
