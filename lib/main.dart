import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'features/personalization/controllers/language_controller.dart';

/// -- Uygulamanın giriş noktası
Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX yerel deposu. Oturum jetonu, dil, sepet gibi her şey buradan
  /// okunduğu için başka hiçbir şeyden önce hazır olmalı.
  await GetStorage.init();

  /// -- iOS'ta tam ekran modunda altta kalan saydam boşluğu kapatır
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  /// -- Açılış ekranı, hangi ekrana gidileceği belli olana kadar bekletilir
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Kimlik katmanı. `AuthenticationRepository.onReady()` hem açılış
  /// ekranını kaldırır (`FlutterNativeSplash.remove()`) hem de oturuma göre
  /// yönlendirir; bu yüzden burada ayrıca `remove()` çağrılmaz.
  Get.put(AuthenticationRepository());

  /// -- Dil katmanı (FAZ 09).
  /// `App` kurulmadan ÖNCE kurulur: `onInit` kayıtlı dili okuyup
  /// `Get.updateLocale` çağırıyor ve `GetMaterialApp` başlangıç locale'ini
  /// bu controller'dan alıyor. `fenix: true` — ekran kapansa da ayakta kalır.
  Get.put(LanguageController(), permanent: true);

  /// -- Uygulama burada başlıyor...
  runApp(const App());
}
