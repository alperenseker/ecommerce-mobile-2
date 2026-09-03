/// OTP ekranının bağımlılığı.
library;

import 'package:get/get.dart';
import '../features/authentication/controllers/otp_controller.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => OTPController());
  }
}
