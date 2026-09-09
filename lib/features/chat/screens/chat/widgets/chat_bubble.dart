/// Sohbet balonu.
///
/// `flutter_chat_ui` paketinin varsayılan balonu turuncu/gri bir dil
/// kullanıyor; TASARIM.md §6'ya göre **gelen mesaj beyaz + 1px çerçeve**,
/// **giden mesaj dolu indigo** olmalı. Paket `bubbleBuilder` ile balonun
/// çizimini devrettiği için metin/görsel içeriği paketten geliyor, yalnız
/// kabuk burada çiziliyor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class TChatBubble extends StatelessWidget {
  const TChatBubble({
    super.key,
    required this.child,
    required this.message,
    required this.nextMessageInGroup,
    required this.currentUserId,
  });

  final Widget child;
  final types.Message message;

  /// Aynı kişinin arka arkaya mesajlarından biri mi. Kuyruk köşesi yalnız
  /// **son** balona veriliyor; her balona verilince dizi tırtıklı görünüyor.
  final bool nextMessageInGroup;

  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isMine = message.author.id == currentUserId;

    // Giden: dolu indigo. Gelen: beyaz (karanlıkta kap zemini) + ince çerçeve.
    final background = isMine
        ? TColors.primary
        : (dark ? TColors.darkerGrey : TColors.white);
    final border = isMine
        ? null
        : Border.all(
            color: dark ? TColors.darkerGrey : TColors.borderSecondary,
            width: 1,
          );

    const radius = Radius.circular(TSizes.cardRadiusLg);
    // Kuyruk köşesi: gönderene bakan alt köşe küçülür.
    final tail = nextMessageInGroup
        ? radius
        : const Radius.circular(TSizes.borderRadiusSm);

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: isMine ? radius : tail,
          bottomRight: isMine ? tail : radius,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
