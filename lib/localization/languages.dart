/// Çeviri katmanının **yükleyicisi**.
///
/// Sözlüklerin kendisi `Languages/` altındaki 10 dosyadadır (~800 anahtar ×
/// 10 dil). Hepsini birden belleğe almak boşuna: kullanıcı yalnız birini
/// görüyor ve haritalar toplamda birkaç yüz KB tutuyor. Bu yüzden [keys]
/// açılışta **yalnız iki** harita kurar — **İngilizce (yedek)** ve
/// **kullanıcının kayıtlı dili**; dil değişince [ensureLoaded] o dili
/// `Get.addTranslations` ile ekler.
///
/// Yedek dil daima yüklü olduğu için, bir dilde eksik kalan anahtar ekranda
/// ham anahtar (`someKey.someOther`) olarak değil İngilizce olarak görünür.
/// (Bugün eksik anahtar yok: on dosyanın anahtar kümesi birebir aynı.)
library;

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'Languages/brazilian.dart';
import 'Languages/english.dart';
import 'Languages/french.dart';
import 'Languages/german.dart';
import 'Languages/kazakh.dart';
import 'Languages/portuguese.dart';
import 'Languages/russian.dart';
import 'Languages/spanish.dart';
import 'Languages/turkish.dart';
import 'Languages/vietnamese.dart';

class Languages extends Translations {
  /// Dil haritalarının **tembel üreticileri**, GetX çeviri anahtarına göre.
  ///
  /// Değer bir `Function()` — harita ancak çağrıldığında kurulur. Buraya
  /// doğrudan `English.language` yazılsaydı sınıf yüklenirken **on dilin
  /// tamamı** belleğe alınırdı ve tembel yüklemenin anlamı kalmazdı.
  ///
  /// Anahtar sırası dil ekranındaki sıradır: Kazakça · Rusça · Türkçe ·
  /// İngilizce, sonra diğerleri (`LanguageController.allLanguages`).
  static final Map<String, Map<String, String> Function()> _builders = {
    'kk': () => Kazakh.language,
    'ru': () => Russian.language,
    'tr': () => Turkish.language,
    'en_US': () => English.language,
    'fr': () => French.language,
    'de': () => German.language,
    'es': () => Spanish.language,
    'pt': () => Portuguese.language,
    'pt_BR': () => PortugueseBR.language,
    'vi': () => Vietnamese.language,
  };

  /// Depodaki dil kodunu (`en`) çeviri anahtarına (`en_US`) çevirir.
  /// Diğer kodlar anahtarlarıyla birebir aynıdır.
  static String _trKey(String code) => code == 'en' ? 'en_US' : code;

  /// Bir dilin sözlüğü **gerçekten var mı**. Dil ekranı, çevirisi olmayan
  /// bir dilde İngilizceye düşmek için bunu sorar.
  static bool hasTranslation(String code) => _builders.containsKey(_trKey(code));

  @override
  Map<String, Map<String, String>> get keys {
    final result = <String, Map<String, String>>{};

    // Yedek dil daima yüklü olmalı; çevirisi olmayan anahtar buraya düşer.
    final fallback = _builders['en_US'];
    if (fallback != null) result['en_US'] = fallback();

    // Artı kullanıcının kayıtlı dili — uygulama açılışta zaten çevrili gelsin,
    // diğer 8 harita hiç okunmasın.
    final saved = GetStorage().read<String>('language');
    if (saved != null) {
      final key = _trKey(saved);
      final builder = _builders[key];
      if (builder != null && key != 'en_US') result[key] = builder();
    }
    return result;
  }

  /// [languageCode] sözlüğünü **istek üzerine** belleğe alır.
  ///
  /// Dil değiştirilmeden ÖNCE çağrılır; yoksa ekran bir kare boyunca ham
  /// anahtar gösterir. Zaten yüklüyse hiçbir şey yapmaz.
  static void ensureLoaded(String languageCode) {
    final key = _trKey(languageCode);
    final builder = _builders[key];
    if (builder == null) return;
    if (Get.translations.containsKey(key)) return;
    Get.addTranslations({key: builder()});
  }
}
