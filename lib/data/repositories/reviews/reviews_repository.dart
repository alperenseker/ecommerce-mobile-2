/// Değerlendirme repository'sinin arayüzü.
library;

import '../../../features/shop/models/product_model.dart';
import '../../../features/shop/models/product_review_model.dart';

abstract class ReviewRepository {
  Future<({
    List<ReviewModel> reviews,
    ReviewSummaryModel? summary,
    int total,
    int page,
    int pageSize,
  })> getProductReviews(
    String productId, {
    int page,
    int pageSize,
    int? rating,
    String sort,
  });

  Future<ReviewModel> getReview(String reviewId);

  Future<({
    List<ReviewModel> reviews,
    int total,
    int page,
    int pageSize,
  })> getUserReviews(
    String userId, {
    int page,
    int pageSize,
  });

  Future<ReviewModel> submitReview({
    required ProductModel product,
    required double rating,
    String? comment,
    bool isApproved,
  });

  Future<String> createReview({
    required String productId,
    required String userId,
    required int rating,
    String? title,
    String? body,
    List<String>? images,
  });

  Future<void> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    String? body,
    List<String>? images,
  });

  Future<void> deleteReview({
    required ReviewModel review,
    required String productId,
  });

  Future<void> voteReview({
    required String reviewId,
    required String userId,
    required bool isHelpful,
  });

  Future<void> moderateReview({
    required String reviewId,
    required String status,
    String? adminNote,
    String? moderatedBy,
  });

  Future<({
    List<ReviewModel> reviews,
    int total,
    int page,
    int pageSize,
  })> getPendingReviews({int page, int pageSize});
}

class ReviewSummaryModel {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewSummaryModel({
    required this.averageRating,
    required this.totalReviews,
    this.ratingDistribution = const {},
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final dist = <int, int>{};
    final rawDist = json['RatingDistribution'] ?? json['ratingDistribution'];
    if (rawDist != null) {
      (rawDist as Map<String, dynamic>).forEach((k, v) {
        dist[int.tryParse(k) ?? 0] = (v as num).toInt();
      });
    }
    return ReviewSummaryModel(
      averageRating: (json['averageRating'] ?? json['AverageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? json['TotalReviews'] ?? 0,
      ratingDistribution: dist,
    );
  }
}
