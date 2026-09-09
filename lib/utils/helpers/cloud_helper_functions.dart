import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// [FutureBuilder] / [StreamBuilder] durumlarını tek yerden karşılayan
/// yardımcılar.
///
/// Ekranlar "yükleniyor / veri yok / hata" üçlüsünü kendi başlarına çizmesin
/// diye var: üçünden biri geçerliyse hazır widget döner, hiçbiri değilse
/// `null` döner ve çağıran asıl içeriği çizer.
class TCloudHelperFunctions {
  /// Tek kayıtlık isteğin durumu.
  static Widget? checkSingleRecordState<T>(AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return Center(child: Text(TTexts.noDataFound.tr));
    }

    if (snapshot.hasError) {
      return Center(child: Text(TTexts.somethingWentWrong.tr));
    }

    return null;
  }

  /// Liste döndüren isteğin durumu.
  static Widget? checkMultiRecordState<T>({required AsyncSnapshot<List<T>> snapshot, Widget? loader, Widget? error, Widget? nothingFound}) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (loader != null) return loader;
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
      if (nothingFound != null) return nothingFound;
      return Center(child: Text(TTexts.noDataFound.tr));
    }

    if (snapshot.hasError) {
      if (error != null) return error;
      return Center(child: Text(TTexts.somethingWentWrong.tr));
    }

    return null;
  }
}
