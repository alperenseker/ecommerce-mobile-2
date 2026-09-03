/// Giriş / Kayıt sekme şeridi (TASARIM.md §7, web `login.html` ile aynı dil).
///
/// Web'de bu iki form tek sayfada sekmeyle değişiyor. Mobilde ekranlar
/// **ayrı kalır** (KURALLAR §3: gezinme referanstaki gibi); sekme yalnız
/// aynı geçişin görsel karşılığıdır ve `Get.offNamed` ile yığın derinliğini
/// büyütmeden karşı ekrana geçer — geri tuşu yine çağıran ekrana döner.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

class TAuthTabs extends StatelessWidget {
  const TAuthTabs({super.key, required this.isLogin});

  /// Hangi sekme seçili: true → giriş, false → kayıt.
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final line = dark ? TColors.darkBorder : TColors.borderSecondary;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line, width: TSizes.dividerHeight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: TTexts.signIn.tr,
              selected: isLogin,
              onTap: isLogin ? null : () => Get.offNamed(TRoutes.logIn),
            ),
          ),
          Expanded(
            child: _Tab(
              label: TTexts.createAccount.tr,
              selected: !isLogin,
              onTap: isLogin ? () => Get.offNamed(TRoutes.signup) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek sekme: seçiliyken indigo metin + 2px indigo alt çizgi.
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TSizes.sm + TSizes.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? TColors.primary : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? TColors.primary : TColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
