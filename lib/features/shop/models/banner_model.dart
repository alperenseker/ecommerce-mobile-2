/// Ana sayfa afişi.
library;

import 'package:t_utils/t_utils.dart';

import '../../../utils/constants/enums.dart';

class BannerModel {
  String id;
  String imageUrl;
  String title;
  String description;
  DateTime? startDate;
  DateTime? endDate;
  int views;
  int clicks;
  bool isActive;
  bool isFeatured;

  // New properties for dynamic navigation
  BannerTargetType targetType;
  String? targetId;
  String? targetTitle;
  String? customUrl;
  DateTime createdAt;
  DateTime updateAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title = "",
    this.description = "",
    this.startDate,
    this.endDate,
    this.views = 0,
    this.clicks = 0,
    this.isActive = true,
    this.isFeatured = false,
    required this.targetType,
    this.targetId,
    this.targetTitle,
    this.customUrl,
    required this.createdAt,
    required this.updateAt,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);

  String get formattedUpdateDate => TFormatter.formatDate(updateAt);

  String get formattedStartDate => TFormatter.formatDate(startDate);

  String get formattedEndDate => TFormatter.formatDate(endDate);

  // Convert Coupon to Firestore format
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'targetType': targetType.name,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'customUrl': customUrl,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'startDate': startDate,
      'endDate': endDate,
      'clicks': clicks,
      'createdAt': createdAt,
      'updateAt': updateAt,
    };
  }

  // Retrieve Coupon from Firestore data
  static BannerModel fromJson(String id, Map<String, dynamic> data) {
    return BannerModel(
      id: id,
      imageUrl: data['imageUrl'],
      title: data['title'],
      description: data.containsKey('description') ? data['description'] : '',
      targetType: data.containsKey('targetType')
          ? BannerTargetType.values.firstWhere((e) => e.name == data['targetType'], orElse: () => BannerTargetType.homeScreen)
          : BannerTargetType.homeScreen,
      targetId: data['targetId'],
      targetTitle: data['targetTitle'],
      customUrl: data['customUrl'],
      isActive: data.containsKey('isActive') ? data['isActive'] : true,
      isFeatured: data.containsKey('isFeatured') ? data['isFeatured'] : true,
      startDate: data.containsKey('startDate') && data['startDate'] != null ? DateTime.tryParse(data['startDate'].toString()) : null,
      endDate: data.containsKey('endDate') && data['endDate'] != null ? DateTime.tryParse(data['endDate'].toString()) : null,
      clicks: data.containsKey('clicks') ? data['clicks'] : 0,
      createdAt: data.containsKey('createdAt') && data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updateAt: data.containsKey('updateAt') && data['updateAt'] != null
          ? DateTime.tryParse(data['updateAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Method to calculate Click-Through Rate (CTR) for banner performance
  double get clickThroughRate {
    if (views == 0) {
      return 0.0; // To avoid division by zero
    }
    return (clicks / views) * 100;
  }

  static BannerModel empty() => BannerModel(id: '', imageUrl: '', createdAt: DateTime.now(), updateAt: DateTime.now(), targetType: BannerTargetType.homeScreen);
}
