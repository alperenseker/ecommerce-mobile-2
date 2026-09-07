/// Dil adına göre yerel ayar kuran **yardımcı controller** (referansla eşlik).
///
/// 🔴 Uygulamada kullanılan dil kapısı bu DEĞİL,
/// `features/personalization/controllers/language_controller.dart`'tır.
/// Bu dosya referansta da hiçbir yerden çağrılmıyor; KURALLAR §4 gereği
/// (hiçbir fonksiyon eksilmez) birebir taşındı.
///
/// ⚠️ Depolama anahtarı referansta `'Language'` (büyük L) — dil ekranının
/// kullandığı `'language'` anahtarı DEĞİL. Referanstaki bu ayrım korundu;
/// iki sınıf aynı anda kullanılırsa dil seçimi iki ayrı yerde tutulur ve
/// birbirini görmez. Bu yüzden yeni bir yerden buraya bağlanma, dil
/// değiştirmek için `LanguageController.changeLanguage` çağır.
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

  /// Dil adını yerel ayara çevirir ve **önce sözlüğü yükler**.
  ///
  /// Referansta `Languages.ensureLoaded` çağrısı yoktu çünkü orada on dilin
  /// tamamı açılışta belleğe alınıyordu. Bu projede sözlükler tembel
  /// yükleniyor; çağrı olmadan ekran bir kare boyunca ham anahtar gösterirdi.
  ///
  /// Kazakça ve Türkçe dalları referansta **yoktu** (şablondan kalma bir
  /// eksik). Bu uygulamanın ilk iki dili onlar olduğu için eklendi.
  void _updateLocale(String value) {
    Locale? locale;
    if (value == TTexts.english) {
      locale = const Locale('en', 'US');
    } else if (value == TTexts.french) {
      locale = const Locale('fr', 'CA');
    } else if (value == TTexts.german) {
      locale = const Locale('de', 'DE');
    } else if (value == TTexts.portuguese) {
      locale = const Locale('pt', 'PT');
    } else if (value == TTexts.brazilian) {
      locale = const Locale('pt', 'BR');
    } else if (value == TTexts.vietnamese) {
      locale = const Locale('vi', 'VN');
    } else if (value == TTexts.spanish) {
      locale = const Locale('es', 'ES');
    } else if (value == TTexts.russian) {
      locale = const Locale('ru', 'RU');
    } else if (value == TTexts.turkish) {
      locale = const Locale('tr', 'TR');
    } else if (value == TTexts.kazakh) {
      locale = const Locale('kk', 'KZ');
    }
    if (locale == null) return;
    Languages.ensureLoaded(locale.languageCode);
    Get.updateLocale(locale);
  }
}
