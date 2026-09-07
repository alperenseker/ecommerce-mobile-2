// FAZ 12 — bildirim listesinin CANLI yanıt biçimiyle çözülmesi ve alıcıya
// göre süzülmesi.
//
// Neden bu test var: bildirim listesi uygulamada **hiç çalışmıyordu** ve bu
// ancak gerçek bir hesapla ekran açılınca görüldü. Üç kusur üst üste binmişti
// (üçü de burada sabitlendi):
//   1. `ApiNotificationRepository.fetchAllItems` uygulanmamıştı; temel sınıfın
//      hâli `UnimplementedError` fırlatıyordu.
//   2. Kimlik yalnız `json['id']` okunuyordu; sunucu **`Id`** gönderiyor.
//   3. Tarih Firestore `Timestamp` sanılıp `.toDate()` çağrılıyordu; sunucu
//      **ISO dize** gönderiyor ve çağrı NoSuchMethodError atıyordu.
//
// Aşağıdaki JSON, `GET /api/notifications` yanıtından (2026-09-07, canlı
// sunucu, royalprof@gmail.com) birebir alınmış bir satırdır.
import 'package:flutter_test/flutter_test.dart';
import 'package:tstore_ecommerce_app/data/services/notifications/notification_model.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/notifcation_controller.dart';

/// Repository'nin PascalCase → camelCase eşlemesinin aynısı.
/// (`ApiNotificationRepository`nin `fromJson` haritası ile aynı kurallar.)
NotificationModel decode(Map<String, dynamic> json) => NotificationModel.fromJson(
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
    );

const me = 'user_00e05f87d7c3';
const other = 'user_c42a09511394';

Map<String, dynamic> liveRow({String recipient = me, String id = 'cd290039-da3a-4596-986e-5e350f5e25ad'}) => {
      'Id': id,
      'Title': 'orderCanceledSorry',
      'Body': 'Unfortunately, your order #ORD-20260625-00001 has been canceled.',
      'SenderId': 'user_8f65726899e5',
      'RecipientIds': [recipient],
      'Type': 'Order Update 94a1304b-a785-4662-8014-4e5d7bd01cd6',
      'SeenBy': <String, dynamic>{},
      'Route': '/orderDetail',
      'RouteId': '94a1304b-a785-4662-8014-4e5d7bd01cd6',
      'IsBroadcast': true,
      'CreatedAt': '2026-06-25T06:46:03.589336Z',
    };

void main() {
  group('NotificationModel — canlı yanıt biçimi', () {
    test('PascalCase satır çözülüyor ve kimlik BOŞ KALMIYOR', () {
      final n = decode(liveRow());

      expect(n.id, 'cd290039-da3a-4596-986e-5e350f5e25ad');
      expect(n.title, 'orderCanceledSorry');
      expect(n.recipientIds, [me]);
      expect(n.route, '/orderDetail');
      expect(n.isBroadcast, isTrue);
    });

    test('ISO dize tarih çözülüyor — .toDate() çağrısı ARTIK YOK', () {
      final n = decode(liveRow());

      expect(n.createdAt.year, 2026);
      expect(n.createdAt.month, 6);
      expect(n.createdAt.day, 25);
      expect(n.seenAt, isNull);
    });

    test('tarih epoch (ms) ya da DateTime olarak da gelebilir', () {
      final epoch = DateTime.utc(2026, 3, 4).millisecondsSinceEpoch;
      final byInt = decode(liveRow()..['CreatedAt'] = epoch);
      expect(byInt.createdAt.toUtc(), DateTime.utc(2026, 3, 4));

      final dt = DateTime.utc(2025, 1, 2);
      final byDateTime = decode(liveRow()..['CreatedAt'] = dt);
      expect(byDateTime.createdAt, dt);
    });

    test('çözülemeyen tarih ÇÖKERTMEZ, bugüne düşer', () {
      final n = decode(liveRow()..['CreatedAt'] = 'not-a-date');
      expect(n.createdAt, isA<DateTime>());
    });
  });

  group('NotificationController.onlyMine', () {
    test('canlı listede yalnız bana ait kayıtlar kalır', () {
      // Canlı dağılım: 14 kaydın 5'i bu kullanıcıya ait.
      final all = [
        ...List.generate(9, (i) => decode(liveRow(recipient: other, id: 'o$i'))),
        ...List.generate(5, (i) => decode(liveRow(recipient: me, id: 'm$i'))),
      ];

      final mine = NotificationController.onlyMine(all, me);

      expect(all.length, 14);
      expect(mine.length, 5);
      expect(mine.every((n) => n.recipientIds.contains(me)), isTrue);
    });

    test('IsBroadcast true olsa da BAŞKASININ bildirimi gösterilmez', () {
      final foreign = decode(liveRow(recipient: other));
      expect(foreign.isBroadcast, isTrue, reason: 'sunucu tek alıcıda da true yazıyor');

      expect(NotificationController.onlyMine([foreign], me), isEmpty);
    });

    test('alıcısı olmayan kayıt gerçek duyurudur, gösterilir', () {
      final broadcast = decode(liveRow()..['RecipientIds'] = <String>[]);
      expect(NotificationController.onlyMine([broadcast], me), hasLength(1));
    });

    test('oturum yoksa liste boş', () {
      expect(NotificationController.onlyMine([decode(liveRow())], ''), isEmpty);
    });
  });
}
