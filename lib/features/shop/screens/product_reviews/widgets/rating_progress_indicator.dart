/// Puan dağılımının tek çubuğu ("5 ★ ▓▓▓▓░ 12").
///
/// TASARIM.md §2: yıldız rengi `star`, çubuk zemini `grey`.
library;

import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class TRatingProgressIndicator extends StatelessWidget {
  const TRatingProgressIndicator({
    super.key,
    required this.text,
    required this.value,
    this.count,
  });

  /// Yıldız sayısı ("5", "4"…).
  final String text;

  /// 0..1 arası doluluk.
  final double value;

  /// Sağda gösterilen yorum adedi; null ise yazılmaz.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs / 2),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Row(
              children: [
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                const Icon(Icons.star, size: 10, color: TColors.star),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: TColors.grey,
                valueColor: const AlwaysStoppedAnimation(TColors.star),
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: TSizes.sm),
            SizedBox(
              width: 28,
              child: Text(
                count.toString(),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall!.apply(color: TColors.darkGrey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
