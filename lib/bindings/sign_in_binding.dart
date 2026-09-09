import 'package:get/get.dart';

import '../features/authentication/controllers/phone_number_controller.dart';

/// Telefonla giriş ekranının bağımlılığı.
class SignInBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => SignInController());
  }
}
