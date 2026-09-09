import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// Daire zemin üstünde dönen yükleme göstergesi.
class TCircularLoader extends StatelessWidget {
  /// [foregroundColor] dönen halkanın, [backgroundColor] arkasındaki dairenin
  /// rengidir.
  const TCircularLoader({
    super.key,
    this.foregroundColor = TColors.white,
    this.backgroundColor = TColors.primary,
  });

  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: CircularProgressIndicator(color: foregroundColor, backgroundColor: Colors.transparent),
      ),
    );
  }
}