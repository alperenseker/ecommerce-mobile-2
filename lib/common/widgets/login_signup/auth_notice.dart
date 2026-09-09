import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// Kimlik ekranlarındaki bilgi/uyarı kutusu.
///
/// 🔴 Metin boşsa widget **hiç çizilmez**. Ekranda yer tutan boş bir kutu,
/// "bir şey yüklenemedi" izlenimi veriyor; bu yüzden `SizedBox.shrink()`
/// dönülüyor ve üstteki `SizedBox` boşlukları da devreye girmiyor.
enum TAuthNoticeType { info, warning, error, success }

class TAuthNotice extends StatelessWidget {
  const TAuthNotice({super.key, required this.text, this.type = TAuthNoticeType.info});

  final String? text;
  final TAuthNoticeType type;

  @override
  Widget build(BuildContext context) {
    final message = text?.trim() ?? '';
    if (message.isEmpty) return const SizedBox.shrink();

    final (Color foreground, Color background, IconData icon) = switch (type) {
      TAuthNoticeType.info => (TColors.info, TColors.infoSoft, Iconsax.info_circle),
      TAuthNoticeType.warning => (TColors.warning, TColors.warningSoft, Iconsax.warning_2),
      TAuthNoticeType.error => (TColors.error, TColors.errorSoft, Iconsax.close_circle),
      TAuthNoticeType.success => (TColors.success, TColors.successSoft, Iconsax.tick_circle),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: TSizes.iconMd),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
