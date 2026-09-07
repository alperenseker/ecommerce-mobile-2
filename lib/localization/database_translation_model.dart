/// Sunucudan **çok dilli JSON** olarak gelen tek bir metnin modeli.
///
/// Bazı alanlar (kategori/ürün adı gibi) veritabanında
/// `[{"language":"ru","translation":"…"}, …]` biçiminde saklanıyor.
/// [DatabaseTranslationModel.translate] bu dizinin içinden **o anki dile**
/// uyanı seçer; sözlük dosyalarıyla (`Languages/`) ilgisi yoktur — onlar
/// uygulamanın kendi metinleri içindir.
///
/// KURALLAR §4 gereği referanstan taşındı; referansta da hiçbir yerden
/// çağrılmıyor.
library;

import 'dart:convert';

import 'package:get/get.dart';

class DatabaseTranslationModel {
  String language;
  String translation;

  DatabaseTranslationModel({required this.language, required this.translation});

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'translation': translation,
    };
  }

  /// Dizinin içinden o anki dilin kaydını çıkarır.
  ///
  /// Eşleşme yoksa `translation` yerine `name` alanına düşülür (sunucu bazı
  /// kayıtlarda çeviri yerine ham adı yazıyor); o da yoksa boş metin döner —
  /// ekranda ham JSON görünmesin.
  factory DatabaseTranslationModel.translate(String encodedJson) {
    if (encodedJson.isEmpty) return DatabaseTranslationModel(language: '', translation: '');

    final List<dynamic> list = json.decode(encodedJson);
    Map<String, dynamic> data = {};

    // 🔴 `Get.locale` null olabilir (çeviri katmanı kurulmadan çağrılırsa);
    // referanstaki `Get.locale!` bu durumda çöküyordu.
    final languageCode = Get.locale?.languageCode.toLowerCase() ?? 'en';

    for (var element in list) {
      if (element['language'].toString().toLowerCase() == languageCode) {
        data = element;
        break;
      }
    }
    return DatabaseTranslationModel(
      language: data['language'] ?? '',
      translation: data['translation'] ?? data['name'] ?? '',
    );
  }
}
