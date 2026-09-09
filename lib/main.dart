import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'features/personalization/controllers/language_controller.dart';

/// Uygulamanın giriş noktası.
///
/// Sıra önemli: yerel depo (`GetStorage`) `runApp`'ten **önce** açılıyor,
/// çünkü oturum jetonu ve dil seçimi oradan okunuyor; açılış ekranı da
/// yönlendirme kararını verene kadar korunuyor.
Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX yerel deposu
  await GetStorage.init();

  /// -- iOS tam ekran modunda altta kalan saydam boşluğu kapatır
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  /// -- Uygulama YALNIZ dikey çalışır.
  ///
  /// 🔴 Ekranların hiçbiri (ürün ızgarası, slider, sepet, ödeme adımları)
  /// yatay için tasarlanmadı; telefonu çevirmek düzeni bozuyordu. Kilit hem
  /// burada hem de platform tarafında (iOS `Info.plist`, Android manifest)
  /// duruyor ki dönme hiç başlamasın.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// -- Diğer parçalar yüklenene kadar açılış ekranı ekranda kalsın
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Oturum kontrolü ve açılış yönlendirmesi. Açılış ekranını da
  /// (`FlutterNativeSplash.remove()`) bu repository `onReady()` içinde
  /// kaldırıyor — bu yüzden burada ayrıca kaldırmıyoruz.
  Get.put(AuthenticationRepository());

  /// -- Dil denetleyicisi.
  ///
  /// 🔴 Binding'de değil BURADA kuruluyor: `GetMaterialApp` başlangıç
  /// `locale`'ini bu denetleyiciden okuyor ve `GeneralBindings` o noktada
  /// henüz çalışmamış oluyor. `permanent`, çünkü dil uygulama boyunca yaşar.
  Get.put(LanguageController(), permanent: true);

  Get.testMode = false;

  /// -- Uygulama burada başlıyor
  runApp(const App());
}
