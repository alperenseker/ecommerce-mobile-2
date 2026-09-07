import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/text_strings.dart';

/// Generic helper functions for handling [FutureBuilder]/[StreamBuilder] state.
class TCloudHelperFunctions {
  /// Helper function to check the state of a single async record.
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

  /// Helper function to check the state of multiple (list) async records.
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
