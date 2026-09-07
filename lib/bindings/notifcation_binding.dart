/// Bildirim ekranlarının bağımlılığı.
///
/// ⚠️ Dosya adındaki yazım hatası ("notifcation") referansla aynı bırakıldı.
library;

import 'package:get/get.dart';

import '../features/personalization/controllers/notifcation_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Çekirdek
    Get.lazyPut(() => NotificationController());
  }
}
