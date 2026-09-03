import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'bindings/general_bindings.dart';
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
    // FAZ 11 — dil seçimi geldiğinde locale + translations buradan beslenecek:
    // final langController = Get.find<LanguageController>();
    return GetMaterialApp(
      title: TTexts.appName,
      // FAZ 11 — çeviri katmanı:
      // locale: langController.selectedLocale.value,
      // translations: Languages(),
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
