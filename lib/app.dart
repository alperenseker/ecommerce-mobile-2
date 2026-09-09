import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'bindings/general_bindings.dart';
import 'routes/app_routes.dart';
import 'utils/constants/colors.dart';
import 'utils/constants/image_strings.dart';
import 'utils/constants/sizes.dart';
import 'utils/constants/text_strings.dart';
import 'utils/theme/theme.dart';
import 'features/personalization/controllers/language_controller.dart';
import 'localization/languages.dart';

/// Uygulamanın kökü: tema, rotalar, diller ve genel bağlamalar burada kurulur.
///
/// `GetMaterialApp` kullanılıyor çünkü mimarinin tamamı GetX üzerine oturuyor
/// (rota, bağlama, çeviri, snackbar hepsi Get üzerinden çalışıyor).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Başlangıç dili: kullanıcının kayıtlı seçimi (bkz. `LanguageController`).
    final langController = Get.find<LanguageController>();
    return GetMaterialApp(
      title: TTexts.appName,
      locale: langController.localeFor(langController.selectedLocale.value.languageCode),
      // 🔴 `Languages` şu an İSKELET (sözlükler FAZ 11'de geliyor); sözlük
      // yokken `.tr` anahtarın kendisini döndürür. FAZ 11'in burayı
      // değiştirmesine gerek yok, yalnız `_builders` haritasını dolduracak.
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

      /// `AuthenticationRepository` hangi ekrana gidileceğine karar verene
      /// kadar duran yer tutucu. Marka logosu **nötr zeminde** kalıyor (yerel
      /// açılış görseliyle aynı), böylece açılışta renkli bir ekran parlamıyor.
      home: Scaffold(
        backgroundColor: TColors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(TImages.foresLogo, width: 160, fit: BoxFit.contain),
              const SizedBox(height: TSizes.xl),
              const SizedBox(
                width: TSizes.iconMd,
                height: TSizes.iconMd,
                child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
