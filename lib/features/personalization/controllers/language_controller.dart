/// Dil seçimi: seçili yerel ayar, arama süzgeci ve kalıcı kayıt.
///
/// 🔴 Diller **istek üzerine** yüklenir: `Languages.ensureLoaded` yalnız
/// seçilen dilin sözlüğünü belleğe alır (bkz. `localization/languages.dart`).
/// Sözlüğü olmayan bir dil seçilirse İngilizceye düşülür — ekranda ham
/// çeviri anahtarı görünmesin.
///
/// Depolama anahtarı `'language'` referanstakiyle aynıdır ve ePay servisi de
/// (`data/services/epay/epay_service.dart`) aynı anahtarı okuyor; değiştirme.
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

  /// Görünüm sırası: Kazakça · Rusça · Türkçe · İngilizce, sonra diğerleri.
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
  /// dil İngilizceye düşer.
  Locale _localeFor(String languageCode) =>
      Languages.hasTranslation(languageCode) ? Locale(languageCode) : const Locale('en', 'US');

  @override
  void onInit() {
    super.onInit();
    final String? savedLang = box.read<String>('language');
    if (savedLang != null) {
      selectedLocale.value = Locale(savedLang);
      Languages.ensureLoaded(savedLang);
      Get.updateLocale(_localeFor(savedLang));
    }
    filteredLanguages.value = List.from(allLanguages);
  }

  /// Dili değiştirir. Sözlük **önce** yüklenir, sonra yerel ayar güncellenir;
  /// aksi hâlde ekran bir kare boyunca ham anahtar gösterir.
  void changeLanguage(String languageCode) {
    selectedLocale.value = Locale(languageCode);
    Languages.ensureLoaded(languageCode);
    Get.updateLocale(_localeFor(languageCode));
    box.write('language', languageCode);
  }

  /// Arama kutusu: dil adına göre süzer.
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
