/// Dil ekranının bağımlılığı.
library;

import 'package:get/get.dart';

import '../features/personalization/controllers/language_controller.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Çekirdek
    Get.lazyPut(() => LanguageController());
  }
}
