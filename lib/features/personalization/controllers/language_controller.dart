/// Dil seçimi.
///
/// Seçilen dil `GetStorage`'a **`'language'`** anahtarıyla yazılır — aynı
/// anahtarı `data/services/epay/epay_service.dart` de okuyor (ödeme
/// widget'ının dili), değiştirme.
///
/// Diller **istek üzerine** yükleniyor: `Languages.ensureLoaded` yalnız
/// seçilen dilin haritasını belleğe alır (bkz. `localization/languages.dart`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../localization/languages.dart';
import '../../../utils/constants/image_strings.dart';

class LanguageController extends GetxController {
  static LanguageController get instance => Get.find();
  final box = GetStorage();
  var selectedLocale = const Locale('en', 'US').obs;
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  /// Gerçekten sözlüğü olan diller. FAZ 11 on dilin hepsini eklediğinde bu
  /// küme değişmez; kapı `Languages.hasTranslation` üzerinden de sorulur.
  static const _translated = {'en', 'fr', 'de', 'pt', 'pt_BR', 'vi', 'es', 'ru', 'tr', 'kk'};

  /// Bütün diller, ekranda görünecekleri sırayla.
  final allLanguages = [
    {'name': 'Kazakh', 'code': 'kk', 'flag': TImages.kazakhstan},
    {'name': 'Russian', 'code': 'ru', 'flag': TImages.russia},
    {'name': 'Turkish', 'code': 'tr', 'flag': TImages.turkey},
    {'name': 'English', 'code': 'en', 'flag': TImages.usa},
    {'name': 'French', 'code': 'fr', 'flag': TImages.french},
    {'name': 'German', 'code': 'de', 'flag': TImages.germany},
    {'name': 'Spanish', 'code': 'es', 'flag': TImages.spain},
    {'name': 'Portuguese', 'code': 'pt', 'flag': TImages.portugal},
    {'name': 'Brazilian', 'code': 'pt_BR', 'flag': TImages.brazil},
    {'name': 'Vietnamese', 'code': 'vi', 'flag': TImages.vietnam},
  ];

  /// [languageCode] için gerçekten uygulanacak yerel ayar. Sözlüğü olmayan
  /// dil İngilizceye düşer ki ekranda ham anahtar görünmesin.
  Locale localeFor(String languageCode) =>
      _translated.contains(languageCode) ? Locale(languageCode) : const Locale('en', 'US');

  @override
  void onInit() {
    super.onInit();
    // Kayıtlı dil tercihi
    String? savedLang = box.read<String>('language');
    if (savedLang != null) {
      selectedLocale.value = Locale(savedLang);
      Languages.ensureLoaded(savedLang);
      // 🔴 `Get.updateLocale` ilk kareden SONRA çağrılır: bu denetleyici
      // `runApp`'ten önce (main.dart) kuruluyor ve o an widget ağacı yok —
      // `forceAppUpdate` orada patlıyor. Açılış dili zaten `GetMaterialApp`'in
      // `locale:` alanından geliyor, bu çağrı yalnız pekiştirme.
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.updateLocale(localeFor(savedLang)));
    }
    filteredLanguages.value = List.from(allLanguages);
  }

  /// Dili değiştirir. `Get.updateLocale` uygulamayı **yeniden başlatmadan**
  /// bütün `.tr` metinlerini yeniden çizdiriyor.
  void changeLanguage(String languageCode) {
    selectedLocale.value = Locale(languageCode);
    // Sözlüğü değiştirmeden ÖNCE yükle: aksi hâlde bir kare boyunca ham
    // anahtar görünüyor.
    Languages.ensureLoaded(languageCode);
    Get.updateLocale(localeFor(languageCode));
    box.write('language', languageCode);
  }

  /// Arama kutusuna göre dil listesini süzer.
  void filterLanguages(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredLanguages.value = List.from(allLanguages);
    } else {
      filteredLanguages.value =
          allLanguages.where((lang) => lang['name']!.toLowerCase().contains(query.toLowerCase())).toList();
    }
  }
}
