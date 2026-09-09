import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../services/notifications/notification_model.dart';
import 'notification_repository.dart';

/// Bildirim uçları (`notifications`).
///
/// ⚠️ Bu uç anonim çağrıda da **200** döner (boş liste ile); "yetkisizse 401
/// gelir" varsayımıyla kod yazma.
class ApiNotificationRepository
    extends TApiRepositoryController<NotificationModel>
    implements NotificationRepository {
  static ApiNotificationRepository get instance => Get.find();

  ApiNotificationRepository()
      : super(
          fromJson: (json) => NotificationModel.fromJson(
            // Sunucu kimliği **`Id`** yazıyor; referans yalnız `id` okuyordu
            // ve bütün bildirimler boş kimlikle geliyordu (detay/okundu kırıktı).
            (json['Id'] ?? json['id'] ?? json['NotificationId'] ?? '').toString(),
            {
              'title': json['title'] ?? json['Title'] ?? '',
              'body': json['body'] ?? json['Body'] ?? '',
              'senderId': json['senderId'] ?? json['SenderId'] ?? '',
              'recipientIds': (json['recipientIds'] ?? json['RecipientIds'] ?? []) is List
                  ? List<String>.from(json['recipientIds'] ?? json['RecipientIds'] ?? [])
                  : [],
              'type': json['type'] ?? json['Type'] ?? '',
              'createdAt': json['createdAt'] ?? json['CreatedAt'],
              'seenAt': json['seenAt'] ?? json['SeenAt'],
              'seenBy': json['seenBy'] ?? json['SeenBy'] ?? {},
              'route': json['route'] ?? json['Route'] ?? '',
              'routeId': json['routeId'] ?? json['RouteId'] ?? '',
              'isBroadcast': json['isBroadcast'] ?? json['IsBroadcast'] ?? false,
            },
          ),
          toJson: (item) => {
            'Title': item.title,
            'Body': item.body,
            'SenderId': item.senderId,
            'RecipientIds': item.recipientIds,
            'Type': item.type,
            'Route': item.route,
            'RouteId': item.routeId,
            'IsBroadcast': item.isBroadcast,
          },
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'notifications';

  /// GET `notifications` — **süzgeçsiz**.
  ///
  /// 🔴 Uç kullanıcı süzgeci kabul etmiyor (`?userId=` denendi, yok sayılıyor)
  /// ve jetonsuz çağrıda bile bütün kullanıcıların kayıtlarını 200 ile
  /// döndürüyor. Alıcıya göre süzme **`NotificationController.onlyMine`**
  /// içinde yapılır; burada ham liste döner.
  @override
  Future<List<NotificationModel>> fetchAllItems() async {
    try {
      final response = await dio.get(getEndpoint());

      if (isSuccess(response.data)) {
        final data = dataOf(response.data);
        if (data is! List) return [];
        return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      }
      throw messageOf(response.data) ?? 'Failed to fetch notifications';
    } catch (e) {
      throw handleException(e);
    }
  }

  /// GET `notifications/{id}` — derin bağlantıyla açılan bildirim için.
  @override
  Future<NotificationModel> fetchSingleItem(String id) async {
    try {
      final response = await dio.get('${getEndpoint()}/$id');

      if (isSuccess(response.data)) {
        final data = dataOf(response.data);
        if (data is! Map) throw 'Notification not found';
        return fromJson(Map<String, dynamic>.from(data));
      }
      throw messageOf(response.data) ?? 'Failed to fetch notification';
    } catch (e) {
      throw handleException(e);
    }
  }

  /// PUT `notifications/{id}` — okundu bilgisini yazar.
  ///
  /// 🔴 **Sunucu `SeenBy` alanını şu an YOK SAYIYOR**: çağrı 200 dönüyor ama
  /// kayıt değişmiyor (canlıda doğrulandı). Çağrı yine de yapılıyor — sunucu
  /// desteklediği gün istemci hazır olsun — ama okundu işareti pratikte
  /// oturum boyunca **bellekte** yaşıyor.
  ///
  /// [json] `{userId: true}` biçiminde gelir (referanstaki Firestore alan
  /// yolu); burada sunucunun beklediği `SeenBy` zarfına sarılır.
  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final response = await dio.put('${getEndpoint()}/$id', data: {'SeenBy': json});

      if (!isSuccess(response.data)) {
        throw messageOf(response.data) ?? 'Failed to update notification';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
