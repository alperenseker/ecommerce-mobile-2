import 'package:get/get.dart';

import '../features/personalization/controllers/user_controller.dart';

/// Kullanıcı denetleyicisini isteyen ekranların bağımlılığı.
class UserBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => UserController());
  }
}
