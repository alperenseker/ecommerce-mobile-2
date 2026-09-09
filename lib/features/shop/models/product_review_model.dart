import '../../../utils/formatters/formatter.dart';

/// Ürün değerlendirmesi (puan, yorum, oy sayısı).
class ReviewModel {
  String id;
  String productId;
  String productName;
  String productImage;
  String userId;
  String userName;
  String? userProfileImage;
  double rating;
  String title;
  String reviewText;
  List<String>? mediaUrls;
  DateTime createdAt;
  DateTime updatedAt;
  bool isApproved;
  bool isVerifiedPurchase;
  int helpfulCount;
  int notHelpfulCount;

  ReviewModel({
    required this.id,
    required this.productId,
    this.productName = '',
    this.productImage = '',
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.rating,
    this.title = '',
    this.reviewText = '',
    this.mediaUrls,
    this.isApproved = true,
    required this.createdAt,
    required this.updatedAt,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
  });

  String get formattedDate => TFormatter.formatDate(createdAt);
  String get formattedUpdatedAtDate => TFormatter.formatDate(updatedAt);

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'userId': userId,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'rating': rating,
        'title': title,
        'reviewText': reviewText,
        'mediaUrls': mediaUrls,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isApproved': isApproved,
      };

  // Returns first non-null, non-empty string from keys (PascalCase first).
  static String? _pick(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final v = data[key];
      if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory ReviewModel.fromJson(String id, Map<String, dynamic> json) {
    final resolvedId = _pick(json, ['ReviewId', 'reviewId', 'id']) ?? id;

    // Backend may split name into UserName + UserSurname.
    final firstName = _pick(json, ['UserName', 'userName', 'username']) ?? '';
    final lastName = _pick(json, ['UserSurname', 'userSurname']) ?? '';
    final fullName = lastName.isNotEmpty ? '$firstName $lastName'.trim() : firstName;

    // Backend Status = 'approved'/'pending'/'rejected'; map to bool.
    final status = _pick(json, ['Status', 'status']) ?? '';
    final isApprovedBool = status == 'approved' ||
        (json['IsApproved'] as bool?) == true ||
        (json['isApproved'] as bool?) == true;

    final List<String> parsedMediaUrls = () {
      final raw = json['Images'] ?? json['images'] ?? json['mediaUrls'] ?? json['MediaUrls'];
      if (raw is List) return List<String>.from(raw.map((e) => e.toString()));
      return <String>[];
    }();

    return ReviewModel(
      id: resolvedId,
      productId: _pick(json, ['ProductId', 'productId', 'productid']) ?? '',
      productName: _pick(json, ['ProductName', 'productName']) ?? '',
      productImage: _pick(json, ['ProductImage', 'productImage']) ?? '',
      userId: _pick(json, ['UserId', 'userId', 'userid']) ?? '',
      userName: fullName,
      userProfileImage: _pick(json, ['UserProfileImage', 'userProfileImage']),
      rating: ((json['Rating'] ?? json['rating'] ?? 0) as num).toDouble(),
      title: _pick(json, ['Title', 'title']) ?? '',
      reviewText: _pick(json, ['Body', 'body', 'ReviewText', 'reviewText']) ?? '',
      mediaUrls: parsedMediaUrls,
      createdAt: _parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: _parseDate(json['UpdatedAt'] ?? json['updatedAt']),
      isApproved: isApprovedBool,
      isVerifiedPurchase: (json['IsVerifiedPurchase'] ?? json['isVerifiedPurchase'] ?? false) as bool,
      helpfulCount: ((json['HelpfulCount'] ?? json['helpfulCount'] ?? 0) as num).toInt(),
      notHelpfulCount: ((json['NotHelpfulCount'] ?? json['notHelpfulCount'] ?? 0) as num).toInt(),
    );
  }

  static ReviewModel empty() => ReviewModel(
        id: '',
        rating: 0,
        createdAt: DateTime.now(),
        productId: '',
        userId: '',
        userName: '',
        updatedAt: DateTime.now(),
      );
}
