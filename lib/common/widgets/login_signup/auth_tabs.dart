import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/helper_functions.dart';

/// Giriş ↔ kayıt arasındaki **sekmeli** geçiş (TASARIM.md §6).
///
/// Referansta böyle bir bileşen yok; oradaki geçiş formun altındaki düğmeyle
/// yapılıyor. Ekranlar yine de **ayrı** kaldı (KURALLAR §3: akış değişmez);
/// sekme yalnız görünüştür ve `Get.offNamed` kullanır — `toNamed` olsaydı
/// kullanıcı iki ekran arasında gidip geldikçe yığın büyür, geri tuşu
/// beklenmedik biçimde eski kopyalara dönerdi.
enum TAuthTab { login, signup }

class TAuthTabs extends StatelessWidget {
  const TAuthTabs({super.key, required this.current});

  final TAuthTab current;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(TSizes.xs),
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: TTexts.signIn.tr,
              selected: current == TAuthTab.login,
              onTap: () => Get.offNamed(TRoutes.logIn),
            ),
          ),
          Expanded(
            child: _Tab(
              label: TTexts.createAccount.tr,
              selected: current == TAuthTab.signup,
              onTap: () => Get.offNamed(TRoutes.signup),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return InkWell(
      // Seçili sekmeye tekrar dokunmak aynı ekranı yeniden kurmasın.
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      child: Container(
        height: TSizes.buttonHeight - TSizes.sm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? (dark ? TColors.dark : TColors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? TColors.primary : TColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
