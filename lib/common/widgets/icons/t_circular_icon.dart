/// Yuvarlak zeminli ikon düğmesi.
///
/// TASARIM.md §6: ürün kartındaki kalp/karşılaştır düğmeleri **yuvarlak beyaz**
/// ve ince çerçevelidir; bu yüzden `showBorder` eklendi. Diğer kullanım
/// noktaları (sepet sayaç adımlayıcısı vb.) çerçevesiz kalır.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class TCircularIcon extends StatelessWidget {
  /// A custom Circular Icon widget with a background color.
  ///
  /// Properties are:
  /// Container [width], [height], & [backgroundColor].
  ///
  /// Icon's [size], [color] & [onPressed]
  const TCircularIcon({
    super.key,
    required this.icon,
    this.width,
    this.height,
    this.size = TSizes.lg,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.showBorder = false,
    this.borderColor,
  });

  final double? width, height, size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final bool showBorder;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? (dark ? TColors.darkSurface : TColors.white),
        borderRadius: BorderRadius.circular(100),
        border: showBorder
            ? Border.all(color: borderColor ?? (dark ? TColors.darkBorder : TColors.borderSecondary))
            : null,
      ),
      // IconButton'ın varsayılan 8px dolgusu ve 48px asgari ölçüsü sıfırlandı;
      // yoksa 32px'lik küçük yuvarlak düğmede ikon kırpılıyor/kayıyor.
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: size ?? TSizes.lg,
        icon: Icon(icon, color: color ?? (dark ? TColors.light : TColors.darkerGrey), size: size),
      ),
    );
  }
}
