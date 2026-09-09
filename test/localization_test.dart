// FAZ 11 — yerelleştirmenin iş kuralları (ağa çıkmaz).
//
// Sınanan üç söz:
//   · ON dilin anahtar kümesi BİREBİR aynı — bir dile anahtar eklenip
//     ötekine eklenmezse o dilde ekranda ham anahtar görünür,
//   · tembel yükleme çalışıyor: açılışta bellekte yalnız İKİ harita var
//     (yedek İngilizce + kayıtlı dil),
//   · ekranda `.tr` ile çağrılan her anahtarın sözlükte karşılığı var —
//     kaynak kodu tarayarak; yani kabul kriterindeki "ham anahtar görünmesin"
//     kuralı derleme zamanında değil, bu testte kilitleniyor.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/localization/Languages/brazilian.dart';
import 'package:tstore_ecommerce_app/localization/Languages/english.dart';
import 'package:tstore_ecommerce_app/localization/Languages/french.dart';
import 'package:tstore_ecommerce_app/localization/Languages/german.dart';
import 'package:tstore_ecommerce_app/localization/Languages/kazakh.dart';
import 'package:tstore_ecommerce_app/localization/Languages/portuguese.dart';
import 'package:tstore_ecommerce_app/localization/Languages/russian.dart';
import 'package:tstore_ecommerce_app/localization/Languages/spanish.dart';
import 'package:tstore_ecommerce_app/localization/Languages/turkish.dart';
import 'package:tstore_ecommerce_app/localization/Languages/vietnamese.dart';
import 'package:tstore_ecommerce_app/localization/languages.dart';
import 'package:tstore_ecommerce_app/localization/database_translation_model.dart';

/// Sözlükler: ekranda göründükleri sırayla (Kazakça · Rusça · Türkçe ·
/// İngilizce · sonra diğerleri).
final Map<String, Map<String, String>> dictionaries = {
  'kazakh': Kazakh.language,
  'russian': Russian.language,
  'turkish': Turkish.language,
  'english': English.language,
  'french': French.language,
  'german': German.language,
  'spanish': Spanish.language,
  'portuguese': Portuguese.language,
  'brazilian': PortugueseBR.language,
  'vietnamese': Vietnamese.language,
};

/// `lib/` altındaki bütün Dart kaynakları.
List<File> _libFiles() {
  final dir = Directory('lib');
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

/// Dosyanın **yorumsuz** kaynağı: satır (`//`) ve blok (`/* */`) yorumları
/// atılır, yoksa yorumda duran eski bir anahtar taramayı yanıltır.
String _code(File file) {
  final withoutBlocks = file.readAsStringSync().replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return withoutBlocks
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

void main() {
  group('sözlük bütünlüğü', () {
    test('on dil de aynı anahtar kümesini taşıyor', () {
      final reference = English.language.keys.toSet();
      expect(reference, isNotEmpty);

      for (final entry in dictionaries.entries) {
        final keys = entry.value.keys.toSet();
        expect(
          keys.difference(reference),
          isEmpty,
          reason: '${entry.key}.dart İngilizcede olmayan anahtar taşıyor',
        );
        expect(
          reference.difference(keys),
          isEmpty,
          reason: '${entry.key}.dart bu anahtarları eksik bırakmış',
        );
      }
    });

    test('hiçbir sözlükte boş çeviri yok', () {
      for (final entry in dictionaries.entries) {
        final empty = entry.value.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key);
        expect(empty, isEmpty, reason: '${entry.key}.dart boş değer taşıyor');
      }
    });

    test('dört ana dil gerçekten çevrili: değer anahtarın kendisi değil', () {
      // Yedi dil adı ("English", "Model", "SKU"…) her dilde aynı kalabilir;
      // ölçüt, sözlüğün ezici çoğunluğunun anahtardan farklı olması.
      for (final name in ['kazakh', 'russian', 'turkish']) {
        final dict = dictionaries[name]!;
        final sameAsKey = dict.entries.where((e) => e.value == e.key).length;
        expect(
          sameAsKey / dict.length,
          lessThan(0.05),
          reason: '$name.dart çevirilerinin çoğu anahtarın kendisi',
        );
      }
    });
  });

  group('tembel yükleme', () {
    setUpAll(() async {
      // GetStorage disk üzerinde çalışıyor; testte path_provider sahte.
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.createTempSync('faz11').path,
      );
      await GetStorage.init();
      Get.testMode = true;
    });

    tearDown(() async {
      await GetStorage().remove('language');
      Get.clearTranslations();
    });

    test('kayıtlı dil yokken yalnız yedek İngilizce yüklenir', () async {
      await GetStorage().remove('language');
      final keys = Languages().keys;
      expect(keys.keys, ['en_US']);
    });

    test('kayıtlı dil varken bellekte tam İKİ harita olur', () async {
      await GetStorage().write('language', 'kk');
      final keys = Languages().keys;
      expect(keys.length, 2);
      expect(keys.keys.toSet(), {'en_US', 'kk'});
    });

    test('kayıtlı dil İngilizce ise ikinci harita açılmaz', () async {
      await GetStorage().write('language', 'en');
      final keys = Languages().keys;
      expect(keys.keys, ['en_US']);
    });

    test('ensureLoaded seçilen dili istek üzerine ekler', () async {
      await GetStorage().remove('language');
      Get.addTranslations(Languages().keys);
      Languages.ensureLoaded('tr');
      Get.locale = const Locale('tr');
      // Türkçe sözlükten bir anahtar: yüklenmemiş olsaydı ham anahtar dönerdi.
      expect('cartTotal'.tr, Turkish.language['cartTotal']);
    });

    test('on dilin hepsi hasTranslation ile tanınıyor', () {
      for (final code in ['en', 'fr', 'ru', 'de', 'pt', 'pt_BR', 'vi', 'es', 'tr', 'kk']) {
        expect(Languages.hasTranslation(code), isTrue, reason: '$code tanınmıyor');
      }
      expect(Languages.hasTranslation('zz'), isFalse);
    });
  });

  group('ekranda ham anahtar kalmasın', () {
    test('kodda .tr ile çağrılan her düz metin anahtarı sözlükte var', () {
      final pattern = RegExp(r"'((?:\\.|[^'\\]){1,140})'\.tr\b");
      final missing = <String>{};

      for (final file in _libFiles()) {
        if (file.path.contains('${Platform.pathSeparator}localization${Platform.pathSeparator}')) continue;
        for (final match in pattern.allMatches(_code(file))) {
          final key = match.group(1)!;
          if (!English.language.containsKey(key)) missing.add(key);
        }
      }

      expect(missing, isEmpty, reason: 'sözlükte karşılığı olmayan ham anahtarlar');
    });

    test('ekranda .tr ile çağrılan her TTexts sabiti sözlükte var', () {
      // `TTexts` sabitlerinin DEĞERİ harita anahtarıdır; sabit adından değere
      // gitmek için kaynak dosyayı okuyoruz (yansıma yok).
      final source = File('lib/utils/constants/text_strings.dart').readAsStringSync();
      final decl = RegExp(
        // \u0022 = çift tırnak; ham dizeyi kapatmasın diye kaçış kodu.
        r"static const (?:String )?([A-Za-z0-9_]+)\s*=\s*(['\u0022])(.*?)\2\s*;",
        dotAll: true,
      );
      final values = {for (final m in decl.allMatches(source)) m.group(1)!: m.group(3)!};
      expect(values.length, greaterThan(800));

      // Marka adı ve şablondan kalan kişi adı bilerek çevrilmiyor.
      const untranslated = {'appName', 'homeAppbarSubTitle'};

      final used = RegExp(r'TTexts\.([A-Za-z0-9_]+)\.tr\b');
      final missing = <String>{};
      for (final file in _libFiles()) {
        if (file.path.contains('${Platform.pathSeparator}localization${Platform.pathSeparator}')) continue;
        for (final m in used.allMatches(_code(file))) {
          final name = m.group(1)!;
          if (untranslated.contains(name)) continue;
          final value = values[name];
          if (value == null || !English.language.containsKey(value)) missing.add(name);
        }
      }
      expect(missing, isEmpty, reason: 'sözlükte karşılığı olmayan TTexts sabitleri');
    });

    test('sunucunun bildirim başlıkları çevrili', () {
      // Canlı `GET /notifications` bu dört başlığı çeviri anahtarı olarak
      // gönderiyor; ekran `notification.title.tr` çiziyor.
      for (final key in [
        'orderUpdateNowProcessing',
        'orderShippedOnItsWay',
        'orderDeliveredEnjoy',
        'orderCanceledSorry',
      ]) {
        expect(English.language.containsKey(key), isTrue, reason: '$key sözlükte yok');
      }
    });
  });

  group('DatabaseTranslationModel', () {
    test('yerel ayar kurulmadan çağrılınca çökmez, İngilizceye düşer', () {
      Get.locale = null;
      final model = DatabaseTranslationModel.translate(
        '[{"language":"en","translation":"Handle"},{"language":"ru","translation":"Ручка"}]',
      );
      expect(model.translation, 'Handle');
    });

    test('boş metin boş model döndürür', () {
      expect(DatabaseTranslationModel.translate('').translation, '');
    });
  });
}
