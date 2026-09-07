/// Bildirim listesi ve bildirim detayının controller'ı.
///
/// ⚠️ Dosya adındaki yazım hatası ("notifcation") referansla aynı bırakıldı;
/// binding ve import yolları da öyle. Düzeltmek dosya eşliğini bozardı.
///
/// Not: REST API canlı akış (stream) desteklemiyor; referansta da olduğu gibi
/// liste **bir kez** çekiliyor, [listenToNotifications] yalnız yeniden çekiyor.
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

  /// Detay ekranının açılış işi.
  ///
  /// Bildirim listeden geldiyse argümanla gelir; derin bağlantıdan (yerel
  /// bildirime dokunma) geldiyse yalnız kimlik vardır ve kayıt uçtan çekilir.
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
    // REST API canlı akış desteklemiyor; bir kez çekilir.
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

  /// 🔴 Yalnız bu kullanıcıya ait bildirimler.
  ///
  /// `GET /notifications` **süzgeçsiz** ve jetonsuz bile 200 dönüyor: canlı
  /// sunucuda 14 kaydın hepsi, alıcısı kim olursa olsun geliyor (2026-09-04'te
  /// doğrulandı). Süzülmezse müşteri BAŞKASININ sipariş bildirimini görür ve
  /// "göster" düğmesi başkasının siparişine gider.
  ///
  /// `IsBroadcast` bayrağına GÜVENİLMEZ: sunucu tek alıcılı bildirimlerde de
  /// true yazıyor. Ölçüt `RecipientIds`: liste bu kullanıcıyı içeriyorsa ya da
  /// tamamen boşsa (gerçek duyuru) gösterilir.
  /// Saf fonksiyon (test edilebilir); oturum kimliği dışarıdan verilir.
  static List<NotificationModel> onlyMine(List<NotificationModel> all, String userId) {
    if (userId.isEmpty) return [];
    return all.where((n) => n.recipientIds.isEmpty || n.recipientIds.contains(userId)).toList();
  }

  /// Okundu işaretleme. Sunucuda okunma bilgisi kullanıcı kimliğine göre
  /// tutuluyor (`seenBy[userId]`), bu yüzden alan adı kimliğin kendisi.
  Future<void> markNotificationAsViewed(NotificationModel notification) async {
    try {
      final String notificationId = notification.id;
      final String currentUserId = AuthenticationRepository.instance.getUserID;

      if (notification.seenBy.isEmpty || notification.seenBy[currentUserId] == false) {
        await repository.updateSingleField(notificationId, {currentUserId: true});

        // Listedeki kopya da işaretlenir; ekran yeniden çekmeden gri olsun.
        // Bildirim listede yoksa (derin bağlantıyla açıldı) atlanır —
        // referanstaki `firstWhere` burada istisna fırlatıyordu.
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index].seenBy[currentUserId] = true;
          notifications.refresh();
        }
      }
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.error.tr, message: '${TTexts.markNotificationAsSeen.tr} $e');
    }
  }
}
