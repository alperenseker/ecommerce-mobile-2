import 'package:get/get.dart';

import '../features/personalization/controllers/language_controller.dart';

/// Dil ekranının bağlaması.
///
/// ⚠️ `LanguageController` uygulama açılışında `main.dart` içinde
/// `permanent` kuruluyor (`GetMaterialApp` başlangıç `locale`'ini ondan
/// okuyor). Bu bağlama referansla dosya eşliği için duruyor; `lazyPut` zaten
/// kayıtlı örneği ezmez.
class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => LanguageController());
  }
}
