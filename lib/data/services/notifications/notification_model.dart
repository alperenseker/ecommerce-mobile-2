import '../../../utils/formatters/formatter.dart';

/// Yerel bildirim kaydının modeli (başlık, gövde, okundu bilgisi).
class NotificationModel {
  String id; // Unique ID for the notification
  final String title; // Notification title
  final String body; // Notification body
  final String senderId; // ID of the sender (e.g., system, admin, or user)
  final List<String> recipientIds; // List of IDs of recipients (can be one or multiple)
  final String type; // Notification type (e.g., order, message, promotion, etc.)
  final DateTime createdAt; // Timestamp when notification was created
  final DateTime? seenAt; // Timestamp when the notification was seen (optional)
  final Map<String, bool> seenBy; // Tracks who has seen it {userId: true/false}
  final String route; // Route for deep linking in the app
  final String routeId; // Route for deep linking in the app
  final bool isBroadcast; // If it's sent to multiple recipients (true if broadcast)

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.senderId,
    required this.recipientIds,
    required this.type,
    required this.createdAt,
    this.seenAt,
    required this.seenBy,
    required this.route,
    required this.routeId,
    required this.isBroadcast,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);

  factory NotificationModel.fromJson(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map.containsKey('title') ? map['title'] ?? '' : '',
      body: map.containsKey('body') ? map['body'] ?? '' : '',
      senderId: map.containsKey('senderId') ? map['senderId'] ?? '' : '',
      recipientIds: map.containsKey('recipientIds') ? List<String>.from(map['recipientIds'] ?? []) : [],
      type: map.containsKey('type') ? map['type'] ?? '' : '',
      // 🔴 Referans burada Firestore `Timestamp.toDate()` çağırıyordu; bu
      // sunucu tarihi **ISO metin** olarak gönderiyor (`"2026-07-01T05:31:19Z"`)
      // ve `.toDate()` metin üzerinde `NoSuchMethodError` fırlatıp bildirim
      // listesini komple çökertiyordu. Artık iki biçim de okunuyor.
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      seenAt: _toDate(map['seenAt']),
      seenBy: map.containsKey('seenBy') ? Map<String, bool>.from(map['seenBy'] ?? {}) : {},
      route: map.containsKey('route') ? map['route'] ?? '' : '',
      routeId: map.containsKey('routeId') ? map['routeId'] ?? '' : '',
      isBroadcast: map.containsKey('isBroadcast') ? map['isBroadcast'] ?? false : false,
    );
  }

  static NotificationModel empty() => NotificationModel(
      id: '',
      createdAt: DateTime.now(),
      title: '',
      type: '',
      body: '',
      isBroadcast: true,
      recipientIds: [],
      route: '',
      routeId: '',
      seenBy: {},
      senderId: '');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'senderId': senderId,
      'recipientIds': recipientIds,
      'type': type,
      'createdAt': createdAt,
      'seenAt': seenAt,
      'seenBy': seenBy,
      'route': route,
      'routeId': routeId,
      'isBroadcast': isBroadcast,
    };
  }
}

/// Sunucudan gelen tarihi okur.
///
/// Üç biçim gelebiliyor: ISO metin (bu API'nin yaptığı), hazır [DateTime] ve
/// Firestore `Timestamp` (referanstan kalan `toDate()` arayüzü). Tanınmayan
/// değerde `null` döner — tek bir bozuk tarih bütün listeyi düşürmesin.
DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  try {
    return (value as dynamic).toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}
