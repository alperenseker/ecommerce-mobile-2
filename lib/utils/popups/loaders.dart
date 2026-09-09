import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

/// Kısa bildirimler: toast ve renkli snackbar'lar.
///
/// Uygulamadaki tüm "başarılı / uyarı / hata" mesajları buradan geçer,
/// böylece renk ve süre tek yerden yönetilir.
class TLoaders {
  /// GetX'in snackbar'ı taşıyabilecek bağlı bir Overlay'i var mı?
  ///
  /// Açılışta ya da rota geçişi sırasında snackbar tetiklenirse (ör. bir
  /// denetleyicinin onInit/onReady isteği navigator hazır olmadan hata verirse)
  /// "No Overlay widget found" çökmesi oluyordu; bu koruma onun içindir.
  ///
  /// 🔴 Koşul, GetX'in snackbar'ı göstermek için GERÇEKTEN aradığı şeydir:
  /// kök navigator'ın overlay'i. Önceki hâli `Overlay.maybeOf(Get.overlayContext)`
  /// bakıyordu; `Get.overlayContext` overlay'in bir ÇOCUK elemanını döndürdüğü
  /// için bu arama **her zaman null** dönüyor ve uygulamadaki bütün hata /
  /// uyarı / başarı snackbar'ları sessizce düşürülüyordu (FAZ 06'da bulundu).
  static bool get _isOverlayReady => Get.key.currentState?.overlay != null;

  /// [show] çağrısını, Overlay hazırsa çalıştırır.
  ///
  /// 🔴 Overlay HAZIRSA doğrudan çağrılır, kare sonrasına ERTELENMEZ.
  /// Ertelenince snackbar'ların hiçbiri ekrana gelmiyordu: GetX snackbar'ı
  /// göstermek için kendisi de bir `addPostFrameCallback` kaydediyor, işlenen
  /// karenin içinden yapılan bu kayıt o karede artık çalıştırılmıyor ve
  /// ekranda başka bir değişiklik olmadığı için yeni bir kare de
  /// planlanmıyordu — mesaj sessizce yutuluyordu (FAZ 06'da bulundu:
  /// karşılaştırma sınır uyarısı hiç görünmüyordu).
  ///
  /// Overlay hiç hazır değilse (çok erken açılış — bir denetleyici daha
  /// navigator kurulmadan hata verirse "No Overlay widget found" çökmesi
  /// oluyordu) bir kare beklenir; o karede de hazır değilse mesaj düşürülür.
  static void _safeShow(VoidCallback show) {
    if (_isOverlayReady) {
      show();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isOverlayReady) return;
      show();
      // GetX'in kendi post-frame kaydı ancak yeni bir karede işlenir.
      WidgetsBinding.instance.scheduleFrame();
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
      // TASARIM.md §2: uyarı/hata renkleri paletten gelir. Referanstaki
      // `Colors.orange` kaldırılan turuncuyu geri getiriyordu.
      backgroundColor: TColors.warning,
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
      backgroundColor: TColors.error,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: TColors.white),
    ));
  }
}
