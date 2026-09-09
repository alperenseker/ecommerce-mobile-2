import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/shop/controllers/product/cart_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../styles/spacing_styles.dart';

/// Uygulamanın ortak başlık çubuğu.
///
/// TASARIM.md §6'nın "beyaz, gölgesiz, altında 1px çizgi" kuralı burada
/// tamamlanıyor: çizgiyi `AppBarTheme` veremiyor (böyle bir alanı yok), bu
/// yüzden yatay dolgunun **dışında** duran bir [DecoratedBox] çiziyor —
/// dolgunun içine konsaydı çizgi iki yandan içeri kaçar, kırık görünürdü.
class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Custom appbar for achieving a desired design goal.
  /// - Set [title] for a custom title.
  /// - [showBackArrow] to toggle the visibility of the back arrow.
  /// - [leadingIcon] for a custom leading icon.
  /// - [leadingOnPressed] callback for the leading icon press event.
  /// - [actions] for adding a list of action widgets.
  /// - Horizontal padding of the appbar can be customized inside this widget.
  const TAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showActionWithBadge = false,
    this.showBackArrow = false,
    required this.showActions,
    required this.showSkipButton,
    this.actionIcon,
    this.actionOnPressed,
    this.titleSpacing,
    this.leadingColor,
  });

  final Widget? title;
  final bool showBackArrow;
  final bool showActions;
  final bool showSkipButton;
  final bool showActionWithBadge;
  final IconData? leadingIcon;
  final IconData? actionIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final VoidCallback? actionOnPressed;
  final double? titleSpacing;

  /// Overrides the leading (back/leading) icon color. Defaults to the
  /// theme-based light/dark color when null.
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final leadingIconColor = leadingColor ?? (dark ? TColors.light : TColors.dark);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        border: Border(bottom: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary)),
      ),
      child: Padding(
        padding: TSpacingStyle.paddingWithDefaultWidth,
        child: AppBar(
          backgroundColor: Colors.transparent,
          titleTextStyle: Theme.of(context).textTheme.headlineSmall,
          automaticallyImplyLeading: false,
          titleSpacing: titleSpacing,
          leading:
              showBackArrow
                  ? IconButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: Icon(Iconsax.arrow_left_24, color: leadingIconColor),
                  )
                  : leadingIcon != null
                  ? IconButton(
                    onPressed: leadingOnPressed,
                    icon: Icon(leadingIcon, color: leadingIconColor),
                  )
                  : null,

          title: title,
          actions:
              showSkipButton
                  ? [
                    OutlinedButton(
                      onPressed: () => Get.toNamed(TRoutes.navigation),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        textStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      child: Text(TTexts.skip.tr),
                    ),
                  ]
                  : showActions
                  ? (actions != null)
                      ? actions
                      : [
                        showActionWithBadge
                            ? Obx(() {
                              // Sepetteki kalem sayısı; sayaç sıfırsa balon HİÇ
                              // çizilmez ("0" yazan balon boş sepette de
                              // dikkat çekiyordu).
                              final count = CartController.instance.cartItems.length;
                              final icon = IconButton(
                                onPressed: actionOnPressed,
                                icon: Icon(actionIcon, color: dark ? TColors.light : TColors.dark),
                              );
                              if (count == 0) return icon;
                              return badges.Badge(
                                position: badges.BadgePosition.topEnd(top: 0, end: 0),
                                // TASARIM.md §6: sayaç balonu `deal` rengi.
                                badgeStyle: const badges.BadgeStyle(badgeColor: TColors.deal),
                                badgeContent: Text('$count', style: const TextStyle(color: Colors.white)),
                                child: icon,
                              );
                            })
                            : IconButton(
                              onPressed: actionOnPressed,
                              icon: Icon(actionIcon, color: dark ? TColors.light : TColors.dark),
                            ),
                      ]
                  : null,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}
