/// Kimlik ekranlarındaki uyarı/bilgi kutusu.
///
/// 🔴 Metin boşsa widget **hiç çizilmez** (`SizedBox.shrink`). Web'de bu
/// kutular `hidden` ile duruyor; Flutter'da boş bir kap çizmek ekranda
/// açıklamasız renkli bir blok bırakırdı.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../custom_shapes/containers/rounded_container.dart';

/// Kutunun anlamı — renk buradan gelir, çağıran renk seçmez.
enum TAuthNoticeTone { info, success, warning, error }

class TAuthNotice extends StatelessWidget {
  const TAuthNotice({
    super.key,
    required this.message,
    this.tone = TAuthNoticeTone.info,
    this.icon,
    this.title,
  });

  final String? message;
  final String? title;
  final TAuthNoticeTone tone;
  final IconData? icon;

  Color get _foreground => switch (tone) {
        TAuthNoticeTone.info => TColors.info,
        TAuthNoticeTone.success => TColors.success,
        TAuthNoticeTone.warning => TColors.warning,
        TAuthNoticeTone.error => TColors.error,
      };

  Color get _background => switch (tone) {
        TAuthNoticeTone.info => TColors.infoSoft,
        TAuthNoticeTone.success => TColors.successSoft,
        TAuthNoticeTone.warning => TColors.warningSoft,
        TAuthNoticeTone.error => TColors.errorSoft,
      };

  @override
  Widget build(BuildContext context) {
    final text = message?.trim() ?? '';
    // Metin yoksa hiç çizme.
    if (text.isEmpty && (title == null || title!.trim().isEmpty)) return const SizedBox.shrink();

    return TRoundedContainer(
      padding: const EdgeInsets.all(TSizes.md),
      radius: TSizes.borderRadiusMd,
      backgroundColor: _background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: _foreground, size: TSizes.iconMd),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.trim().isNotEmpty)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                if (text.isNotEmpty)
                  Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
