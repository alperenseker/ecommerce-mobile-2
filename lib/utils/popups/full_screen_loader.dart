import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/loaders/animation_loader.dart';
import '../../common/widgets/loaders/circular_loader.dart';
import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

/// Tam ekran yükleme penceresi.
///
/// Sipariş oluşturma, giriş gibi geri alınamaz işlemlerde kullanılıyor:
/// pencere geri tuşuyla da dışına dokunarak da kapanmıyor, böylece işlem
/// sürerken kullanıcı ekranı terk edip yarım kayıt bırakamıyor.
class TFullScreenLoader {
  /// Verilen metin ve Lottie animasyonuyla tam ekran pencereyi açar.
  ///
  /// [text] pencerede görünen metin, [animation] Lottie dosyasının yolu.
  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!, // Overlay pencereleri için overlayContext
      barrierDismissible: false, // Dışına dokunarak kapanmaz
      builder: (_) => PopScope(
        canPop: false, // Geri tuşuyla da kapanmaz
        child: Container(
          color: THelperFunctions.isDarkMode(Get.context!) ? TColors.dark : TColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 250), // Animasyonu ekranın ortasına indirir
              TAnimationLoaderWidget(text: text, animation: animation),
            ],
          ),
        ),
      ),
    );
  }

  static void popUpCircular() {
    Get.defaultDialog(
      title: '',
      onWillPop: () async => false,
      content: const TCircularLoader(),
      backgroundColor: Colors.transparent,
    );
  }

  /// Açık olan yükleme penceresini kapatır.
  static stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }
}
