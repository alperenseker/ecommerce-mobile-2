/// Bölüm başlığı: solda başlık, sağda "hepsini gör" bağlantısı.
///
/// TASARIM.md §6: başlık 16px `w700` (`titleLarge`), bağlantı indigo `w600`.
/// Bağlantı rengi temadan gelir (`TextButton` artık indigo).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/text_strings.dart';

class TSectionHeading extends StatelessWidget {
  const TSectionHeading({
    super.key,
    this.onPressed,
    this.textColor,
    this.buttonTitle = TTexts.moreProducts,
    required this.title,
    this.showActionButton = true,
  });

  final Color? textColor;
  final bool showActionButton;
  final String title, buttonTitle;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge!.apply(color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showActionButton)
          TextButton(
            onPressed: onPressed,
            child: Text(buttonTitle.tr, style: Theme.of(context).textTheme.labelLarge!.apply(fontWeightDelta: 0)),
          ),
      ],
    );
  }
}
