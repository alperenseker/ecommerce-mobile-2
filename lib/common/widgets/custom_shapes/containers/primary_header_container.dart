/// Ana sayfanın üst başlığını taşıyan kap.
///
/// 🔴 TASARIM.md §7: referanstaki **koyu turuncu kavisli** başlık kaldırıldı.
/// Yerine beyaz, gölgesiz, altında 1px çizgi olan sade bir başlık geldi
/// (TASARIM.md §6 "Başlık (AppBar)" kuralıyla aynı dil). Sınıf adı ve tek
/// parametresi (`child`) referanstakiyle aynı bırakıldı ki kullanım
/// noktalarına dokunmak gerekmesin.
///
/// Kavis çizen [TCurvedEdgesWidget] ve süs daireleri ([TCircularContainer])
/// silinmedi, yalnız burada kullanılmıyor.
library;

import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

/// A container widget that carries the home screen header.
class TPrimaryHeaderContainer extends StatelessWidget {
  /// Create the home header container.
  ///
  /// Parameters:
  ///   - child: The widget to be placed inside the container.
  const TPrimaryHeaderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        // Ayrım gölgeyle değil çizgiyle veriliyor (TASARIM.md §5).
        border: Border(
          bottom: BorderSide(
            color: dark ? TColors.darkBorder : TColors.borderSecondary,
            width: TSizes.dividerHeight,
          ),
        ),
      ),
      // Durum çubuğu boşluğunu içerideki AppBar (primary: true) zaten ekliyor;
      // burada ayrıca SafeArea sarmak başlığı iki kez aşağı itiyordu.
      child: child,
    );
  }
}
