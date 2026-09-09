import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../models/company_model.dart';

/// Şirket 1C kütüğünde **bulunduğunda** açılan onay penceresi.
/// Kullanıcı resmi kaydı onaylarsa `true` döner.
Future<bool> showCompanyConfirmDialog(CompanyModel company) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
      title: Text('Confirm Company'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please confirm the company details below.'.tr,
            style: Get.textTheme.bodyMedium,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _row('Company'.tr, company.nameRu),
          if (company.director.isNotEmpty) _row('Director'.tr, company.director),
          if (company.address.isNotEmpty) _row('Address'.tr, company.address),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel'.tr)),
        ElevatedButton(onPressed: () => Get.back(result: true), child: Text('Confirm'.tr)),
      ],
    ),
    barrierDismissible: false,
  );
  return result ?? false;
}

/// Şirket kütükte **bulunamadığında** açılan elle giriş penceresi
/// (İP / şahıs şirketi yolu). `{name, director}` ya da iptalde null döner.
Future<Map<String, String>?> showIpCompanyDialog() async {
  final nameController = TextEditingController();
  final directorController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await Get.dialog<Map<String, String>>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
      title: Text('Enter Company Information'.tr),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company not found in the registry. Please enter your details manually.'.tr,
              style: Get.textTheme.bodyMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            TextFormField(
              controller: nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required'.tr : null,
              decoration: InputDecoration(labelText: '${'Company'.tr} *'),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextFormField(
              controller: directorController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required'.tr : null,
              decoration: InputDecoration(labelText: '${'Director'.tr} *'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Get.back(result: {
                'name': nameController.text.trim(),
                'director': directorController.text.trim(),
              });
            }
          },
          child: Text('Continue'.tr),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return result;
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: TSizes.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey))),
        Expanded(
          flex: 3,
          child: Text(value, style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
