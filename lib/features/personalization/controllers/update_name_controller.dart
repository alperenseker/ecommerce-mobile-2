/// Ad / soyad değiştirme ekranının denetleyicisi.
///
/// Sunucu ad ile soyadı ayrı alanlarda (`FirstName` / `LastName`) tutuyor;
/// bu ekranda da iki alan var (adres formundan farklı — orada tek "ad soyad"
/// alanı vardır ve çeviri `AddressController` içinde yapılır).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/user/api_user_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../screens/profile/profile.dart';
import 'user_controller.dart';

class UpdateNameController extends GetxController {
  static UpdateNameController get instance => Get.find();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final userController = UserController.instance;
  final userRepository = ApiUserRepository.instance;
  GlobalKey<FormState> updateUserNameFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    initializeNames();
    super.onInit();
  }

  /// Formu bellekteki kullanıcı kaydıyla doldurur.
  Future<void> initializeNames() async {
    firstName.text = userController.user.value.firstName;
    lastName.text = userController.user.value.lastName;
  }

  Future<void> updateUserName() async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.updatingInformation.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!updateUserNameFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      Map<String, dynamic> name = {'FirstName': firstName.text.trim(), 'LastName': lastName.text.trim()};
      await userRepository.updateSingleField(userController.user.value.id, name);

      // Bellekteki kayıt da güncellenir.
      userController.user.value.firstName = firstName.text.trim();
      userController.user.value.lastName = lastName.text.trim();
      // 🔴 `refresh()` şart: `user` bir `Rx<UserModel>` ve alanı yerinde
      // değiştirmek dinleyicileri uyandırmıyor — referansta bu satır yoktu ve
      // profil ekranı eski adı göstermeye devam ediyordu.
      userController.user.refresh();

      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.nameUpdated.tr);

      Get.off(() => const ProfileScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    super.onClose();
  }
}
