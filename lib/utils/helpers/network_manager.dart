import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../constants/text_strings.dart';
import '../popups/loaders.dart';

/// Ağ bağlantısını izler ve bağlantı koptuğunda kullanıcıyı uyarır.
///
/// `GetxController` olarak kurulu, çünkü bağlantı akışına açılışta abone olup
/// uygulama kapanana kadar dinlemesi gerekiyor. İstek atan her repository
/// çağrı öncesi [isConnected] ile bakıyor.
class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxList<ConnectivityResult> _connectionStatus = <ConnectivityResult>[].obs;

  /// Bağlantı akışına abone olur.
  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Bağlantı değişince durumu günceller; bağlantı yoksa uyarı gösterir.
  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _connectionStatus.value = result;
    if (result.contains(ConnectivityResult.none)) {
      TLoaders.customToast(message: TTexts.noInternetAccess.tr);
    }
  }

  /// Bağlantı var mı? Bağlıysa `true`, değilse `false`.
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.any((element) => element == ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Aboneliği kapatır.
  @override
  void onClose() {
    super.onClose();
    _connectivitySubscription.cancel();
  }
}
