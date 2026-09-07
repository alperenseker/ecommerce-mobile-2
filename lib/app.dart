import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'bindings/general_bindings.dart';
import 'features/personalization/controllers/language_controller.dart';
import 'localization/languages.dart';
import 'routes/app_routes.dart';
import 'utils/constants/colors.dart';
import 'utils/constants/image_strings.dart';
import 'utils/constants/text_strings.dart';
import 'utils/theme/theme.dart';

/// Uygulamanın kökü: tema, rotalar, çeviri ve genel bağımlılıklar burada
/// kurulur. Ekranların hepsi bu ağacın altında çalışır.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Dil katmanı FAZ 09'da bağlandı. `LanguageController` `main.dart`'ta
    // `permanent` kuruluyor, bu yüzden burada hazır.
    //
    // 🔴 Sözlüklerin kendisi FAZ 11'in işi: `Languages` bugün boş bir
    // yükleyici (bkz. `localization/languages.dart`). Sözlük yokken `.tr`
    // anahtarın kendisini döndürüyor; `TTexts` değerleri okunabilir metin
    // olduğu için ekranda ham anahtar değil İngilizce görünüyor.
    final langController = LanguageController.instance;
    return GetMaterialApp(
      title: TTexts.appName,
      locale: langController.selectedLocale.value,
      translations: Languages(),
      fallbackLocale: const Locale('en', 'US'),
      theme: TAppTheme.lightTheme,
      themeMode: ThemeMode.system,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialBinding: GeneralBindings(),
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
      ],
      getPages: AppRoutes.pages,

      /// Yönlendirme kararı verilene kadar duran bekleme ekranı.
      /// `AuthenticationRepository.screenRedirect()` bunu hemen değiştirir.
      /// Nötr zeminde FORES logosu duruyor (native açılış görseliyle aynı),
      /// böylece açılışta renkli bir ekran parlamıyor.
      home: Scaffold(
        backgroundColor: TColors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(TImages.foresLogo, width: 160, fit: BoxFit.contain),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
