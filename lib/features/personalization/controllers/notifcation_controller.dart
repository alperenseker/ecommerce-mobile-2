/// Bildirim listesi ve detayının denetleyicisi.
///
/// 🔴 **LİSTE ALICIYA GÖRE SÜZÜLÜR.** `GET /notifications` süzgeç kabul
/// etmiyor (`?userId=` denendi, yok sayılıyor) ve **jetonsuz bile 200** dönüp
/// bütün kullanıcıların bildirimlerini veriyor. Süzülmezse müşteri
/// BAŞKASININ sipariş bildirimini görür ve "göster" düğmesi başkasının
/// siparişini açar. Ölçüt `RecipientIds`; `IsBroadcast`'e **güvenilmez** —
/// sunucu tek alıcılı bildirimlerde de `true` yazıyor (canlıda doğrulandı).
///
/// 🔴 **OKUNDU BİLGİSİ SUNUCUDA TUTULMUYOR.** `PUT /notifications/{id}`
/// 200 dönüyor ama `SeenBy` alanını yok sayıyor (canlıda doğrulandı). Çağrı
/// yine de yapılıyor — sunucu bir gün desteklerse kod hazır — ama okundu
/// işareti **oturum boyunca bellekte** yaşıyor.
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/notifications/api_notification_repository.dart';
import '../../../data/services/notifications/notification_model.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';

class NotificationController extends GetxController {
  /// 🔴 `static` **alan** değil getter: alan olsaydı `Get.find()` sınıf ilk
  /// yüklendiğinde bir kez çalışır, denetleyici henüz kayıtlı değilse patlar.
  static NotificationController get instance => Get.find();

  final isLoading = false.obs;
  final selectedNotification = NotificationModel.empty().obs;
  final selectedNotificationId = ''.obs;

  final repository = ApiNotificationRepository.instance;
  RxList<NotificationModel> notifications = RxList<NotificationModel>();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// Detay ekranının açılış işi: kayıt argümanla gelmediyse uçtan çeker,
  /// sonra okundu işaretler.
  Future<void> init() async {
    try {
      isLoading.value = true;

      if (selectedNotification.value.id.isEmpty) {
        if (selectedNotificationId.isEmpty) {
          Get.offNamed(TRoutes.notification);
        } else {
          selectedNotification.value = await repository.fetchSingleItem(selectedNotificationId.value);
        }
      }

      if (selectedNotification.value.id.isNotEmpty) await markNotificationAsViewed(selectedNotification.value);
    } catch (e) {
      if (kDebugMode) printError(info: e.toString());
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.unableToFetchNotification.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void listenToNotifications() {
    // REST API canlı akış vermiyor; bir kez çekilir.
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final result = await repository.fetchAllItems();
      notifications.value = onlyMine(result, AuthenticationRepository.instance.getUserID);
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.error.tr, message: '${TTexts.failToFetchNotification.tr} $e');
    }
  }

  /// Yalnız [userId] alıcısına yazılmış bildirimler. **Saf** fonksiyon —
  /// testle sabitlenir.
  ///
  /// Kimliksiz (misafir) kullanıcıda liste boştur: sunucudan gelen kayıtların
  /// hepsi başkasınındır.
  static List<NotificationModel> onlyMine(List<NotificationModel> all, String userId) {
    if (userId.isEmpty) return const [];
    return all.where((n) => n.recipientIds.contains(userId)).toList();
  }

  Future<void> markNotificationAsViewed(NotificationModel notification) async {
    try {
      final String notificationId = notification.id;
      final String currentUserId = AuthenticationRepository.instance.getUserID;
      if (notificationId.isEmpty || currentUserId.isEmpty) return;

      if (notification.seenBy.isEmpty || notification.seenBy[currentUserId] == false) {
        await repository.updateSingleField(notificationId, {currentUserId: true});

        // 🔴 `firstWhere` doğrudan çağrılamaz: derin bağlantıyla açılan bir
        // bildirim listede olmayabilir ve referanstaki kod orada istisna
        // fırlatıyordu.
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].seenBy[currentUserId] = true;
          notifications.refresh();
        }
        notification.seenBy[currentUserId] = true;
        selectedNotification.refresh();
      }
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.error.tr, message: '${TTexts.markNotificationAsSeen.tr} $e');
    }
  }

  /// Bildirim [userId] tarafından okundu mu.
  bool isSeen(NotificationModel notification, String userId) => notification.seenBy[userId] == true;
}
