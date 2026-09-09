import 'package:t_utils/utils/constants/enums.dart';
import '../../../utils/formatters/formatter.dart';

/// Sipariş geçmişindeki tek olay (durum değişikliği, not, ödeme).
class OrderActivity {
  final ActivityType activityType; // Enum: Type of activity
  final DateTime activityDate; // Date when the activity occurred
  final String description; // Description of the activity
  final String? performedBy; // Optional: Who performed the activity (admin, user, system)

  OrderActivity({
    required this.activityType,
    required this.activityDate,
    required this.description,
    this.performedBy,
  });

  String get formattedDate => TFormatter.formatDateAndTime(activityDate);

  // Convert OrderActivity to JSON
  Map<String, dynamic> toJson() {
    return {
      'activityType': activityType.name,
      'activityDate': activityDate,
      'description': description,
      'performedBy': performedBy,
    };
  }

  // Retrieve OrderActivity from JSON
  static OrderActivity fromJson(Map<String, dynamic> data) {
    return OrderActivity(
      activityType: data.containsKey('activityType')
          ? ActivityType.values.firstWhere((e) => e.name == data['activityType'], orElse: () => ActivityType.orderCreated)
          : ActivityType.orderCreated,
      activityDate:
          data.containsKey('activityDate') && data['activityDate'] != null ? data['activityDate'].toDate() : DateTime.now(),
      description: data.containsKey('description') ? data['description'] ?? '' : '',
      performedBy: data.containsKey('performedBy') ? data['performedBy'] ?? '' : null,
    );
  }

  // Check if OrderActivity is empty
  bool isEmpty() {
    return description.isEmpty && performedBy == null;
  }
}
