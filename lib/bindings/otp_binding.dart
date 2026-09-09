import 'package:get/get.dart';
import '../features/authentication/controllers/otp_controller.dart';

/// Telefon OTP ekranının bağımlılığı.
class OtpBinding extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.lazyPut(() => OTPController());
  }
}
