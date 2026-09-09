/// Uygulamanın çeviri kaynağı.
///
/// On dilin sözlüğü birlikte ~400 KB metin tutuyor; kullanıcı yalnız birini
/// görüyor. Bu yüzden [keys] açılışta **hepsini** değil yalnız
///   * İngilizceyi (yedek dil) ve
///   * kayıtlı dili
/// döndürür. Kullanıcı dili değiştirdiğinde [ensureLoaded] o dilin haritasını
/// `Get.addTranslations` ile **istek üzerine** ekler — böylece ekranda bir an
/// için ham anahtar görünmez.
///
/// 🔴 [_builders] değerleri **fonksiyondur**, sabit harita değil. Doğrudan
/// `English.language` yazılırsa Dart sınıf yüklenirken on sözlüğü birden
/// belleğe alır ve tembel yükleme anlamını yitirir — bu satırları sabit
/// haritaya çevirme.
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
  /// Her çeviri haritasının **tembel** üreticisi, GetX çeviri anahtarına göre.
  static final Map<String, Map<String, String> Function()> _builders = {
    'en_US': () => English.language,
    'fr': () => French.language,
    'ru': () => Russian.language,
    'de': () => German.language,
    'pt': () => Portuguese.language,
    'pt_BR': () => PortugueseBR.language,
    'vi': () => Vietnamese.language,
    'es': () => Spanish.language,
    'tr': () => Turkish.language,
    'kk': () => Kazakh.language,
  };

  /// Depodaki dil kodunu (`'en'`) GetX çeviri anahtarına (`'en_US'`) çevirir;
  /// diğerleri anahtarlarıyla birebir eşleşir.
  static String _trKey(String code) => code == 'en' ? 'en_US' : code;

  /// [languageCode] için bir sözlük kayıtlı mı.
  static bool hasTranslation(String languageCode) => _builders.containsKey(_trKey(languageCode));

  @override
  Map<String, Map<String, String>> get keys {
    final result = <String, Map<String, String>>{};

    // Yedek dil her zaman yüklü olmalı.
    final fallback = _builders['en_US'];
    if (fallback != null) result['en_US'] = fallback();

    // Artı kayıtlı dil — uygulama diğer sekiz haritayı hiç okumadan çevrili
    // açılsın diye.
    final saved = GetStorage().read<String>('language');
    if (saved != null) {
      final key = _trKey(saved);
      final builder = _builders[key];
      if (builder != null && key != 'en_US') result[key] = builder();
    }
    return result;
  }

  /// [languageCode] sözlüğünü, dil değiştirilmeden **önce** GetX'e yükler.
  static void ensureLoaded(String languageCode) {
    final key = _trKey(languageCode);
    final builder = _builders[key];
    if (builder != null) Get.addTranslations({key: builder()});
  }
}
