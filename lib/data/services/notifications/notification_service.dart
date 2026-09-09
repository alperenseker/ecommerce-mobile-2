import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'notification_model.dart';

/// Yalnız **yerel** bildirim servisi.
///
/// Uzak bildirim (FCM) Firebase ile birlikte kaldırıldı. Sunucu tarafına bir
/// gönderim sağlayıcısı eklenirse jeton kaydı ve gelen mesaj işleme buraya geri
/// bağlanmalı.
///
/// ⚠️ FAZ 02'nin kapsamı dışındaydı; "referanstaki `data/**` dosyalarının hepsi
/// hedefte olsun" kabul kriteri gereği getirildi.
class TNotificationService extends GetxService {
  static TNotificationService get instance => Get.find();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<NotificationModel> notifications = [];

  /// Yerel bildirim kimliği sayacı.
  ///
  /// FAZ 26 — bir alışveriş şirket başına ayrı siparişlere bölünüyor ve her
  /// sipariş için bir bildirim üretiliyor. Bildirimler sabit `0` kimliğiyle
  /// gösterilseydi son bildirim öncekilerin ÜZERİNE yazar, kullanıcı üç
  /// siparişten yalnız birini görürdü.
  int _nextNotificationId = 0;

  @override
  void onInit() {
    super.onInit();
    _initializeLocalNotifications();
  }

  /// TODO: No push provider is configured; there is no device token to return.
  static Future<String> getToken() async => '';

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification_icon');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  Future<void> showLocalNotification({required String title, required String body, String? route, String? routeId}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id', 'channel_name', importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      _nextNotificationId++,
      title,
      body,
      platformChannelSpecifics,
      payload: '$route?id=$routeId',
    );
  }

  void addNotification({required String title, required String body, String? route, String? routeId}) {
    final notification = NotificationModel(
      id: UniqueKey().toString(),
      title: title,
      body: body,
      route: route ?? '',
      routeId: routeId ?? '',
      createdAt: DateTime.now(),
      seenBy: {},
      isBroadcast: false,
      type: '',
      recipientIds: [],
      senderId: '',
    );

    notifications.add(notification);
    showLocalNotification(title: title, body: body, route: route, routeId: routeId);
  }

  Future<void> _onSelectNotification(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
      Get.toNamed(notificationResponse.payload!);
    }
  }
}
