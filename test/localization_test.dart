// FAZ 11 — yerelleştirme.
//
// Bu dosya fazın kabul kriterlerini kalıcı olarak sabitler:
//   1. ON dilin anahtar kümesi BİREBİR aynı — bir dilde eksik anahtar,
//      o ekranda ham anahtar (`someKey.someOther`) demektir.
//   2. Hiçbir çeviri değeri anahtarın kendisi değildir (kopyala-yapıştır
//      sırasında değer yerine anahtar yazılmış olmasın).
//   3. Kodda `.tr` uygulanan HER `TTexts` sabitinin dört ana dilde
//      (kk · ru · tr · en) karşılığı vardır.
//   4. Sunucu bildirim başlıklarını çeviri ANAHTARI olarak gönderiyor;
//      dördü de sözlükte.
//   5. Tembel yükleme: açılışta bellekte yalnız İKİ dil haritası olur.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:tstore_ecommerce_app/localization/languages.dart';

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

/// Dosya adı → sözlük. Sıra dil ekranındaki sıradır.
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

/// Dört ana dil: bunlarda çeviri gerçekten o dilde olmalı.
const mainLanguages = ['kazakh', 'russian', 'turkish', 'english'];

void main() {
  group('Sözlük bütünlüğü', () {
    test('on dilin anahtar kümesi birebir aynı', () {
      final reference = English.language.keys.toSet();
      expect(reference.length, greaterThan(700), reason: 'İngilizce sözlük beklenenden küçük');

      for (final entry in dictionaries.entries) {
        final keys = entry.value.keys.toSet();
        expect(
          keys.difference(reference),
          isEmpty,
          reason: '${entry.key}.dart içinde İngilizcede olmayan anahtar var',
        );
        expect(
          reference.difference(keys),
          isEmpty,
          reason: '${entry.key}.dart içinde eksik anahtar var — ekranda ham anahtar görünür',
        );
      }
    });

    test('hiçbir değer ham çeviri anahtarı değil', () {
      // Ölçüt `değer == anahtar` DEĞİL: `TTexts.rememberMe` gibi bazı
      // sabitlerin değeri zaten okunabilir metin ('Remember Me') ve
      // İngilizce sözlükte aynısı yazılı — bu doğru. Ekranda kötü görünen,
      // `someKey` biçimindeki **camelCase** kimliklerin çeviri yerine
      // geçmesidir; testin aradığı da bu.
      final rawKey = RegExp(r'^[a-z][a-z0-9]*[A-Z][A-Za-z0-9]*\$');
      for (final entry in dictionaries.entries) {
        final leaks = entry.value.entries
            .where((e) => e.value == e.key && rawKey.hasMatch(e.key))
            .map((e) => e.key)
            .toList();
        expect(leaks, isEmpty, reason: '${entry.key}.dart: çeviri yerine ham anahtar yazılmış');
      }
    });

    test('hiçbir değer boş değil', () {
      for (final entry in dictionaries.entries) {
        final empties = entry.value.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key).toList();
        expect(empties, isEmpty, reason: '${entry.key}.dart: boş çeviri');
      }
    });

    test('sunucudan anahtar olarak gelen bildirim başlıkları sözlükte', () {
      // Canlı `GET /notifications` şu an bu dört başlığı ham anahtar olarak
      // gönderiyor; ekranda `.tr` uygulanıyor.
      const serverKeys = [
        'orderUpdateNowProcessing',
        'orderShippedOnItsWay',
        'orderDeliveredEnjoy',
        'orderCanceledSorry',
      ];
      for (final name in dictionaries.keys) {
        for (final key in serverKeys) {
          expect(dictionaries[name], contains(key), reason: '$name.dart: $key yok');
        }
      }
    });
  });

  group('Kodda çevrilen her metnin karşılığı var', () {
    test('lib/ içindeki her `TTexts.x.tr` dört ana dilde bulunuyor', () {
      final textStrings = File('lib/utils/constants/text_strings.dart').readAsStringSync();

      // TTexts sabitinin ADI → DEĞERİ. Sözlük anahtarı değerdir.
      final constants = <String, String>{};
      for (final m in RegExp(
        '''static const (?:String )?([A-Za-z0-9_]+) *= *['"](.*?)['"] *;''',
      ).allMatches(textStrings)) {
        constants[m.group(1)!] = m.group(2)!;
      }
      expect(constants.length, greaterThan(700));

      // `.tr` / `.trParams` uygulanan sabitleri topla.
      final used = <String>{};
      final pattern = RegExp(r'TTexts\.\s*([A-Za-z0-9_]+)\s*\)?\s*\.(?:tr|trParams)\b');
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('/localization/')) continue;
        for (final m in pattern.allMatches(file.readAsStringSync())) {
          used.add(m.group(1)!);
        }
      }
      expect(used.length, greaterThan(300), reason: 'Çevrilen metin sayısı beklenenden az');

      for (final language in mainLanguages) {
        final dictionary = dictionaries[language]!;
        final missing = used
            .where((name) => constants.containsKey(name))
            .map((name) => constants[name]!)
            .where((key) => !dictionary.containsKey(key))
            .toList()
          ..sort();
        expect(missing, isEmpty, reason: '$language.dart: ekranda kullanılan ama sözlükte olmayan anahtarlar');
      }
    });

    test('lib/ içindeki her `\'düz metin\'.tr` dört ana dilde bulunuyor', () {
      // FAZ 03 kayıt akışı çeviriyi `TTexts` sabitiyle değil doğrudan
      // İngilizce metinle yazmış (`'Confirm Company'.tr`). GetX için bu da
      // geçerli bir anahtar; sözlükte karşılığı yoksa metin İngilizce kalır.
      final literal = RegExp(r"'([^'\\]{2,80})'\.tr\b");
      final used = <String>{};
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('/localization/')) continue;
        for (final m in literal.allMatches(file.readAsStringSync())) {
          used.add(m.group(1)!);
        }
      }
      expect(used, isNotEmpty);

      for (final language in mainLanguages) {
        final dictionary = dictionaries[language]!;
        final missing = used.where((key) => !dictionary.containsKey(key)).toList()..sort();
        expect(missing, isEmpty, reason: '$language.dart: düz metin anahtarının karşılığı yok');
      }
    });
  });

  group('Tembel yükleme', () {
    setUp(() async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      // `GetStorage` dosyayı belge klasörüne yazıyor; testte platform kanalı
      // yok, bu yüzden geçici bir klasör döndürülüyor.
      final tempDir = Directory.systemTemp.createTempSync('faz11_storage');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );
      await GetStorage.init();
      Get.clearTranslations();
    });

    test('on dilin de sözlüğü tanımlı', () {
      for (final code in ['kk', 'ru', 'tr', 'en', 'fr', 'de', 'es', 'pt', 'pt_BR', 'vi']) {
        expect(Languages.hasTranslation(code), isTrue, reason: '$code için sözlük yok');
      }
      // Sözlüğü olmayan bir dil seçilirse ekran İngilizceye düşmeli.
      expect(Languages.hasTranslation('zz'), isFalse);
    });

    test('kayıtlı dil yokken açılışta bellekte YALNIZ İngilizce var', () async {
      await GetStorage().remove('language');
      final keys = Languages().keys;
      expect(keys.keys, ['en_US']);
    });

    test('kayıtlı dil varken açılışta bellekte YALNIZ iki harita var', () async {
      await GetStorage().write('language', 'kk');
      final keys = Languages().keys;
      expect(keys.keys.toSet(), {'en_US', 'kk'});
      await GetStorage().remove('language');
    });

    test('ensureLoaded seçilen dili ekler, ikinci çağrıda yeniden kurmaz', () {
      Get.addTranslations(Languages().keys);
      expect(Get.translations.containsKey('tr'), isFalse);

      Languages.ensureLoaded('tr');
      expect(Get.translations['tr'], isNotNull);

      final firstMap = Get.translations['tr'];
      Languages.ensureLoaded('tr');
      expect(identical(Get.translations['tr'], firstMap), isTrue,
          reason: 'Zaten yüklü dilin haritası yeniden kurulmamalı');
    });

    test('İngilizce `en_US` anahtarıyla, diğerleri kendi koduyla kayıtlı', () {
      Get.addTranslations(Languages().keys);
      Languages.ensureLoaded('en');
      Languages.ensureLoaded('pt_BR');
      expect(Get.translations.containsKey('en_US'), isTrue);
      expect(Get.translations.containsKey('pt_BR'), isTrue);
    });
  });
}
