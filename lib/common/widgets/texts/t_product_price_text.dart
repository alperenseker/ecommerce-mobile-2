/// Fiyat metni.
///
/// 🔴 `priceHidden` doğruysa rakam BASILMAZ; sunucu bu ürünlerde `Price: 0`
/// gönderiyor ve "0,00 ₸" yazmak müşteriyi yanıltıyordu (bkz. API.md).
/// TASARIM.md §6: fiyat `w800` ve `textPrimary`; renkli değil.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/text_strings.dart';

class TProductPriceText extends StatelessWidget {
  const TProductPriceText({
    super.key,
    this.currencySign = '₸',
    required this.price,
    this.isLarge = false,
    this.maxLines = 1,
    this.lineThrough = false,
    this.priceHidden = false,
  });

  final String currencySign, price;
  final int maxLines;
  final bool isLarge;
  final bool lineThrough;

  /// Fiyat misafirden gizliyse rakam yerine soluk bir bilgi metni basılır.
  final bool priceHidden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = (isLarge ? theme.textTheme.headlineMedium! : theme.textTheme.titleLarge!)
        .copyWith(fontWeight: FontWeight.w800);

    if (priceHidden) {
      // İkincil bilgi gibi durmalı: aynı satır yüksekliği, daha küçük ve soluk.
      // Böylece kart yüksekliği değişmiyor, ızgara hizası korunuyor.
      return Text(
        TTexts.priceOnRequest.tr,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 16) * 0.8,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodySmall?.color,
        ),
      );
    }

    return Text(
      currencySign + price,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.apply(decoration: lineThrough ? TextDecoration.lineThrough : null),
    );
  }
}
