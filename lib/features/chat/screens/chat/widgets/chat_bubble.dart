/// Sohbet balonu (TASARIM.md §1 ve §6).
///
/// **Gelen** mesaj beyaz zemin + 1px `borderSecondary` çerçeve, **giden**
/// mesaj dolu indigo. Ayrım gölgeyle değil çizgiyle veriliyor; paketin
/// varsayılan gri/turuncu balonları bu dile uymuyordu.
///
/// Balonun içi (`child`) `flutter_chat_ui` tarafından çizilir; burada yalnız
/// kabuk (zemin, çerçeve, köşe) değiştirilir.
library;

import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class TChatBubble extends StatelessWidget {
  const TChatBubble({
    super.key,
    required this.child,
    required this.isMine,
    required this.nextMessageInGroup,
  });

  final Widget child;
  final bool isMine;

  /// Aynı kişinin arka arkaya mesajlarında kuyruk köşesi yalnız **son**
  /// balonda sivri kalır; blok tek bir konuşma gibi okunur.
  final bool nextMessageInGroup;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    const radius = Radius.circular(TSizes.cardRadiusLg);
    const tail = Radius.circular(TSizes.cardRadiusXs);

    return Container(
      decoration: BoxDecoration(
        color: isMine
            ? TColors.primary
            : (dark ? TColors.darkSurface : TColors.white),
        border: isMine
            ? null
            : Border.all(
                color: dark ? TColors.darkBorder : TColors.borderSecondary,
                width: TSizes.dividerHeight,
              ),
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: isMine || nextMessageInGroup ? radius : tail,
          bottomRight: !isMine || nextMessageInGroup ? radius : tail,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        child: child,
      ),
    );
  }
}
