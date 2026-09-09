/// Yeniden kimlik doğrulama formu.
///
/// Hesap silme gibi geri alınamaz işlemlerden önce kullanıcıdan e-posta ve
/// şifresini yeniden ister; doğrulama `Auth/login` ucuna gerçek bir istekle
/// yapılır (`UserController.reAuthenticateEmailAndPasswordUser`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/validators/validation.dart';
import '../../controllers/user_controller.dart';

class ReAuthLoginForm extends StatelessWidget {
  const ReAuthLoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(TTexts.reAuthenticateUser.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: controller.reAuthFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- E-posta
                TextFormField(
                  controller: controller.verifyEmail,
                  validator: TValidator.validateEmail,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Iconsax.direct_right),
                    labelText: TTexts.email.tr,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// -- Şifre
                Obx(
                  () => TextFormField(
                    obscureText: controller.hidePassword.value,
                    controller: controller.verifyPassword,
                    validator: (value) => TValidator.validateEmptyText(TTexts.password.tr, value),
                    decoration: InputDecoration(
                      labelText: TTexts.password.tr,
                      prefixIcon: const Icon(Iconsax.password_check),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                        icon: Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.reAuthenticateEmailAndPasswordUser(),
                    child: Text(TTexts.verify.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
