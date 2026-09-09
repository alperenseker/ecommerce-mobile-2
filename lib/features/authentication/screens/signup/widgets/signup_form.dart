import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../controllers/signup_controller.dart';
import 'terms_conditions_checkbox.dart';

/// Kayıt formu. Hesap tipine göre **aynı form** farklı alanlar çiziyor:
/// şirket seçiliyse BİN/İİN, bireysel seçiliyse ad + soyad.
class TSignupForm extends StatelessWidget {
  const TSignupForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(SignupController());
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          const SizedBox(height: TSizes.spaceBtwSections),

          /// Hesap tipi (Bireysel / Şirket)
          ///
          /// 🔴 Kapalı kayıt tipi **hiç çizilmez**. Tek seçenek kaldıysa seçici
          /// tümden gizlenir (tek başına duran bir seçenek seçim izlenimi verir
          /// ama seçilecek bir şey yoktur).
          Obx(
            () => controller.showAccountTypeSelector
                ? Column(
                    children: [
                      _AccountTypeSelector(controller: controller),
                      const SizedBox(height: TSizes.spaceBtwInputFields),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          /// Şirket: BİN/İİN  |  Bireysel: ad & soyad
          Obx(
            () => controller.isCompany
                ? TextFormField(
                    controller: controller.iin,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    // 12 hane kuralı yalnız şirket akışında zorunlu; bireysel
                    // kayıtta bu alan hiç çizilmediği için doğrulanmıyor da.
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return TValidator.validateEmptyText('IIN / BIN', value);
                      }
                      if (value.trim().length != 12) {
                        return 'IIN / BIN must be 12 digits'.tr;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'IIN / BIN'.tr,
                      hintText: 'Enter 12-digit IIN/BIN'.tr,
                      prefixIcon: const Icon(Iconsax.building),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.firstName,
                          validator: (value) => TValidator.validateEmptyText(TTexts.firstName.tr, value),
                          expands: false,
                          decoration: InputDecoration(labelText: TTexts.firstName.tr, prefixIcon: const Icon(Iconsax.user)),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          controller: controller.lastName,
                          validator: (value) => TValidator.validateEmptyText(TTexts.lastName.tr, value),
                          expands: false,
                          decoration: InputDecoration(labelText: TTexts.lastName.tr, prefixIcon: const Icon(Iconsax.user)),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Email
          TextFormField(
            controller: controller.email,
            validator: TValidator.validateEmail,
            decoration: InputDecoration(labelText: TTexts.email.tr, prefixIcon: const Icon(Iconsax.direct)),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Phone Number
          TextFormField(
            cursorColor: TColors.primary,
            cursorHeight: TSizes.lg,
            style: Theme.of(context).textTheme.bodyMedium,
            validator: (value) => TValidator.validatePhoneNumber(value),
            controller: controller.phoneNumber,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: CountryCodePicker(
                alignLeft: false,
                hideMainText: true,
                showCountryOnly: false,
                padding: EdgeInsets.zero,
                showDropDownButton: true,
                initialSelection: '+44',
                showOnlyCountryWhenClosed: false,
                headerText: TTexts.selectCountry.tr,
                favorite: const ['+92', '+44'],
                onChanged: (value) => controller.selectedCountryCode.value = value.dialCode!,
                searchDecoration: InputDecoration(fillColor: isDark ? TColors.darkContainer : TColors.lightContainer),
                dialogBackgroundColor: isDark ? TColors.dark : TColors.white,
              ),
              hintText: TTexts.phoneNo.tr,
              errorStyle: const TextStyle(color: TColors.error),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Password
          Obx(
            () => TextFormField(
              controller: controller.password,
              validator: TValidator.validatePassword,
              obscureText: controller.hidePassword.value,
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

          /// Terms&Conditions Checkbox
          const TTermsAndConditionCheckbox(),
          const SizedBox(height: TSizes.spaceBtwSections),

          /// Sign Up Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => controller.signup(), child: Text(TTexts.createAccount.tr)),
          ),
        ],
      ),
    );
  }
}

/// Bireysel / Şirket seçicisi — [SignupController.accountType]'a bağlı.
///
/// Bu widget **yalnız iki kayıt tipi de açıkken** çiziliyor
/// ([SignupController.showAccountTypeSelector]), bu yüzden burada ayrıca
/// seçenek eleme yok. Tek tip açıkken hangi akışın koşacağını
/// [SignupController.effectiveAccountType] belirliyor.
class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _AccountTypeChip(
              label: 'Individual'.tr,
              icon: Iconsax.user,
              selected: !controller.isCompany,
              onTap: () => controller.accountType.value = 'retail',
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwInputFields),
          Expanded(
            child: _AccountTypeChip(
              label: 'Company'.tr,
              icon: Iconsax.building,
              selected: controller.isCompany,
              onTap: () => controller.accountType.value = 'company',
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    // TASARIM.md §6 ikincil düğme dili: beyaz zemin + çizgi, seçilince indigo
    // çerçeve ve `accent` zemin.
    final borderColor = selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.borderPrimary);
    final background = selected
        ? (isDark ? TColors.darkAccent : TColors.accent)
        : (isDark ? TColors.darkSurface : TColors.white);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TSizes.md),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: TSizes.iconSm, color: selected ? TColors.primary : null),
            const SizedBox(width: TSizes.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? TColors.primary : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
