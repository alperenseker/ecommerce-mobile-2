/// Telefonla giriş ekranının bağımlılığı.
library;

import 'package:get/get.dart';

import '../features/authentication/controllers/phone_number_controller.dart';

class SignInBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => SignInController());
  }
}
