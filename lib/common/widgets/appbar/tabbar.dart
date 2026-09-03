/// Kaydırılabilir sekme çubuğu.
///
/// TASARIM.md §6: beyaz zemin, seçili sekme indigo. Referanstaki siyah
/// karanlık zemin yerine `darkSurface` kullanılıyor.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';

/// A custom tab bar widget with customizable appearance.
class TTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// Default constructor for the TTabBar.
  ///
  /// Parameters:
  ///   - tabs: List of widgets representing the tabs.
  const TTabBar({super.key, required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Material(
      color: dark ? TColors.darkSurface : TColors.white,
      child: TabBar(
        tabs: tabs,
        isScrollable: true,
        indicatorColor: TColors.primary,
        labelColor: TColors.primary,
        unselectedLabelColor: TColors.darkGrey,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());
}
