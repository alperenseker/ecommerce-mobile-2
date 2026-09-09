/// Sunucudan **çok dilli JSON** olarak gelen alanların çözücüsü.
///
/// Sözlük dosyalarıyla (`Languages/*.dart`) ilgisi yoktur: bu model
/// `[{"language":"ru","translation":"..."}]` biçimindeki bir alandan
/// kullanıcının diline uyan kaydı seçer.
///
/// Referanstan tek fark: referans `Get.locale!` yazıyordu ve yerel ayar
/// kurulmadan çağrılırsa çöküyordu; artık İngilizceye düşüyor.
library;

import 'dart:convert';

import 'package:get/get.dart';

class DatabaseTranslationModel {
  String language;
  String translation;

  DatabaseTranslationModel({required this.language, required this.translation});

  toJson() {
    return {
      'language': language,
      'translation': translation,
    };
  }

  factory DatabaseTranslationModel.translate(String encodedJson) {
    if (encodedJson.isEmpty) return DatabaseTranslationModel(language: "", translation: "");

    List<dynamic> list = json.decode(encodedJson);
    Map<String, dynamic> data = {};

    // Yerel ayar henüz kurulmamış olabilir (açılışın ilk karesi) — yedek 'en'.
    final currentLanguage = (Get.locale?.languageCode ?? 'en').toLowerCase();

    for (var element in list) {
      if (element['language'].toString().toLowerCase() == currentLanguage) {
        data = element;
        break;
      }
    }
    return DatabaseTranslationModel(
      language: data['language'] ?? "",
      translation: data['translation'] ?? data['name'] ?? "",
    );
  }
}
