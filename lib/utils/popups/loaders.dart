import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

class TLoaders {
  /// Whether GetX currently has a mounted Overlay able to host a snackbar.
  /// Guards against the "No Overlay widget found" crash that happens when a
  /// snackbar is triggered during app start-up or a route transition (e.g. a
  /// controller's onInit/onReady fetch fails before the navigator is ready).
  static bool get _isOverlayReady {
    final context = Get.overlayContext;
    return context != null && Overlay.maybeOf(context) != null;
  }

  /// Runs [show] after the current frame, but only once an Overlay is ready.
  /// If the overlay never becomes ready (very early start-up), the snackbar is
  /// silently dropped instead of crashing the app.
  static void _safeShow(VoidCallback show) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isOverlayReady) show();
    });
  }

  static hideSnackBar() => ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: THelperFunctions.isDarkMode(Get.context!) ? TColors.darkerGrey.withValues(alpha: 0.9) : TColors.grey.withValues(alpha: 0.9),
          ),
          child: Center(child: Text(message, style: Theme.of(Get.context!).textTheme.labelLarge)),
        ),
      ),
    );
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    _safeShow(() => Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: TColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      icon: const Icon(Iconsax.check, color: TColors.white),
    ));
  }

  static warningSnackBar({required title, message = ''}) {
    _safeShow(() => Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: Colors.orange,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: TColors.white),
    ));
  }

  static errorSnackBar({required title, message = ''}) {
    _safeShow(() => Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: Colors.red.shade600,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: TColors.white),
    ));
  }
}
