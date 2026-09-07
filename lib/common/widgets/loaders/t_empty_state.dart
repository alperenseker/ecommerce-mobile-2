/// Boş durum ve "önce giriş yapın" kapısı.
///
/// TASARIM.md §6: *Ortada daire ikon (`lightContainer` zemin) + başlık +
/// açıklama + tek düğme.* Referanstaki `TAnimationLoaderWidget` (Lottie
/// animasyon + koyu düğme) bu dile uymuyor; animasyon dosyaları duruyor ve
/// widget silinmedi, yalnız sepet/favori/karşılaştırma/kupon ekranları bu
/// sade kutuyu kullanıyor.
///
/// 🔴 Girişsiz kullanıcıya BOŞ LİSTE gösterilmez: sepet, favoriler ve
/// karşılaştırma sunucuda kullanıcıya bağlıdır, misafirin listesi "boş"
/// değil **yoktur**. [TEmptyState.signInRequired] bu kapıyı çizer.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

class TEmptyState extends StatelessWidget {
  const TEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  /// Girişsiz kullanıcıya gösterilen kapı: kilit ikonu + açıklama + giriş
  /// düğmesi. [message] ekrana özel metindir (sepet / favori / karşılaştırma).
  factory TEmptyState.signInRequired({required String message}) {
    return TEmptyState(
      icon: Iconsax.lock,
      title: TTexts.signInRequired.tr,
      message: message,
      actionText: TTexts.signIn.tr,
      // Karşılama ekranı giriş/kayıt seçimini sunuyor (FAZ 03).
      onAction: () => Get.toNamed(TRoutes.welcome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? TColors.darkContainer : TColors.lightContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: TColors.darkGrey),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if ((message ?? '').isNotEmpty) ...[
              const SizedBox(height: TSizes.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: TSizes.spaceBtwSections),
              SizedBox(
                width: 220,
                height: TSizes.buttonHeight,
                child: ElevatedButton(onPressed: onAction, child: Text(actionText!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
