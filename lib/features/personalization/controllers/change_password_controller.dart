/// Şifre değiştirme ekranının controller'ı.
///
/// Mevcut şifreyi doğrulayıp yenisini `auth/change-password` ucuna yazar
/// (`AuthenticationRepository.changePassword`). Doğrulama kuralları web ile
/// aynı: üç alan da dolu, yeni şifre en az 6 karakter, tekrar alanı eşleşiyor.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';

class ChangePasswordController extends GetxController {
  static ChangePasswordController get instance => Get.find();

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  // Üç alanın gizliliği ayrı tutuluyor: kullanıcı yalnız yazdığı alanı
  // açıp kontrol etmek istiyor, hepsini birden değil.
  final hideCurrent = true.obs;
  final hideNew = true.obs;
  final hideConfirm = true.obs;

  GlobalKey<FormState> changePasswordFormKey = GlobalKey<FormState>();

  Future<void> changePassword() async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!changePasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.changePassword(
        oldPassword: currentPassword.text.trim(),
        newPassword: newPassword.text.trim(),
      );

      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.passwordChanged.tr);

      // Ekranda kalan şifre alanları temizlenir; geri dönüldüğünde eski
      // değerler formda durmasın.
      currentPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      Get.back();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  @override
  void onClose() {
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}
