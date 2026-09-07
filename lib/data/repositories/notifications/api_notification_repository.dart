/// Bildirim uçları (`notifications`).
///
/// ⚠️ Bu uç anonim çağrıda da **200** döner (boş liste ile); "401 gelirse
/// oturum yok" varsayımı yapma.
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../services/notifications/notification_model.dart';
import 'notification_repository.dart';

class ApiNotificationRepository
    extends TApiRepositoryController<NotificationModel>
    implements NotificationRepository {
  static ApiNotificationRepository get instance => Get.find();

  ApiNotificationRepository()
      : super(
          fromJson: (json) => NotificationModel.fromJson(
            // Sunucu kimliği **`Id`** diye gönderiyor; yalnız `id` okunduğu
            // için her bildirim boş kimlikle kuruluyordu ve "okundu"
            // işaretlemesi hedefini bulamıyordu.
            (json['id'] ?? json['Id'] ?? json['NotificationId'] ?? '').toString(),
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

  /// 🔴 Bu metot **uygulanmak zorunda**: temel sınıftaki hâli
  /// `UnimplementedError` fırlatıyor ve `NotificationController` tam olarak
  /// bunu çağırıyordu — bildirim listesi bu yüzden her zaman boştu
  /// (`FAZ 02`'nin `ApiAttributeRepository` için yazdığı tuzağın aynısı).
  ///
  /// Uç **süzgeçsiz** döner (jetonsuz bile 200); alıcıya göre süzme
  /// `NotificationController.onlyMine` içindedir, burada değil.
  @override
  Future<List<NotificationModel>> fetchAllItems() async {
    try {
      final response = await dio.get(getEndpoint());

      if (isSuccess(response.data)) {
        final data = dataOf(response.data);
        final List<dynamic> rows = data is List ? data : <dynamic>[];
        return rows.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      }
      throw messageOf(response.data) ?? 'Failed to fetch notifications';
    } catch (e) {
      throw handleException(e);
    }
  }
}
