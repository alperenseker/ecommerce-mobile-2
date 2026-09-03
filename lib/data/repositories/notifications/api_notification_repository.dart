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
            json['id']?.toString() ?? '',
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
}
