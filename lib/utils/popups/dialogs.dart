import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/text_strings.dart';
import '../helpers/helper_functions.dart';

/// Uygulamanın ortak onay penceresi.
///
/// Her ekran kendi [Get.defaultDialog]'unu açtığında görünüm birbirini
/// tutmuyordu; tüm onaylar buradan geçsin diye toplandı.
class TDialogs {
  /// İkon, başlık, açıklama ve iki düğmeden oluşan onay penceresi.
  ///
  /// Pencere düğmeye basılınca **kendisi kapanıyor**; bu yüzden
  /// [onConfirm]/[onCancel] geri çağrıları pencereyi kapatmaya çalışmamalı,
  /// yoksa bir alttaki ekran da kapanır.
  ///
  /// Silme gibi geri alınamaz işlemlerde [isDestructive] `true` verilir:
  /// vurgu rengi kırmızıya döner.
  static Future<void> confirm({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData icon = Iconsax.info_circle,
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    final dark = THelperFunctions.isDarkMode(Get.context!);
    final Color accent = isDestructive ? TColors.error : TColors.primary;

    return Get.dialog(
      Dialog(
        backgroundColor: dark ? TColors.darkerGrey : TColors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: TSizes.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(TSizes.md + 2, TSizes.md + 4, TSizes.md + 2, TSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// İkon rozeti
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 1.3),

              /// Başlık
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: TSizes.xs),

              /// Açıklama
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                      color: dark ? TColors.grey : TColors.darkGrey,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems * 1.25),

              /// Düğmeler
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (Get.isDialogOpen ?? false) Get.back();
                        onCancel?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(color: dark ? TColors.darkGrey : TColors.borderPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
                      ),
                      child: Text(
                        cancelText ?? TTexts.cancel.tr,
                        style: TextStyle(color: dark ? TColors.white : TColors.dark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems / 1.5),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (Get.isDialogOpen ?? false) Get.back();
                        onConfirm?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: accent,
                        foregroundColor: TColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(color: accent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
                      ),
                      child: Text(
                        confirmText ?? TTexts.confirm.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }
}
