/// Dil tercihini `GetStorage`'da tutan yardımcı denetleyici.
///
/// ⚠️ **Uygulamanın dil kapısı bu sınıf DEĞİL, `LanguageController`'dır.**
/// İkisi ayrı depolama anahtarı kullanıyor: burada `'Language'` (büyük L),
/// dil ekranında `'language'` (küçük l) — referanstaki ayrım korundu.
/// Dosya KURALLAR §4 gereği ("hiçbir dosya eksilmez") taşındı; dil
/// değiştirmek için `LanguageController.changeLanguage` çağrılır.
///
/// Referanstan iki fark: Kazakça ile Türkçe dalları eklendi (referans sekiz
/// dil biliyordu) ve yerel ayar değişmeden önce `Languages.ensureLoaded`
/// çağrılıyor — tembel yükleme yüzünden sözlük o an bellekte olmayabilir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../utils/constants/text_strings.dart';
import 'languages.dart';

class TLocalizationHelper extends GetxController {
  static TLocalizationHelper get instance => Get.find();
  final storage = GetStorage();
  final RxString currentLanguage = TTexts.english.obs;

  @override
  void onInit() {
    super.onInit();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    await GetStorage.init();
    final lang = storage.read('Language') ?? TTexts.english;
    currentLanguage.value = lang;
    _updateLocale(lang);
  }

  Future<void> switchLanguage(String value) async {
    currentLanguage.value = value;
    await storage.write('Language', value);
    _updateLocale(value);
  }

  void _updateLocale(String value) {
    // Sözlük tembel yükleniyor: yerel ayarı değiştirmeden ÖNCE haritayı
    // belleğe al, yoksa bir kare boyunca ham anahtar görünür.
    final locale = _localeFor(value);
    if (locale == null) return;
    Languages.ensureLoaded(locale.countryCode == 'BR' ? 'pt_BR' : locale.languageCode);
    Get.updateLocale(locale);
  }

  Locale? _localeFor(String value) {
    if (value == TTexts.english) return const Locale('en', 'US');
    if (value == TTexts.french) return const Locale('fr', 'CA');
    if (value == TTexts.german) return const Locale('de', 'DE');
    if (value == TTexts.portuguese) return const Locale('pt', 'PT');
    if (value == TTexts.brazilian) return const Locale('pt', 'BR');
    if (value == TTexts.vietnamese) return const Locale('vi', 'VN');
    if (value == TTexts.spanish) return const Locale('es', 'ES');
    if (value == TTexts.russian) return const Locale('ru', 'RU');
    if (value == TTexts.turkish) return const Locale('tr', 'TR');
    if (value == TTexts.kazakh) return const Locale('kk', 'KZ');
    return null;
  }
}
