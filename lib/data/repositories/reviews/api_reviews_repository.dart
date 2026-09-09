import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/product_model.dart';
import '../../../features/shop/models/product_review_model.dart';
import 'reviews_repository.dart';

/// Değerlendirme uçları (`reviews/...`).
class ApiReviewsRepository extends TApiRepositoryController<ReviewModel>
    implements ReviewRepository {

  static ApiReviewsRepository get instance => Get.find();

  ApiReviewsRepository() : super(
    fromJson: (json) => ReviewModel.fromJson(
      json['ReviewId']?.toString() ?? json['id']?.toString() ?? json['reviewId']?.toString() ?? '',
      json,
    ),
    toJson: (review) => review.toJson(),
    getId: (review) => review.id,
  );

  @override
  String getEndpoint() => 'reviews';

  // ============================================================================
  // GET /reviews/product/{productId}
  // ============================================================================
  @override
  Future<({
    List<ReviewModel>   reviews,
    ReviewSummaryModel? summary,
    int                 total,
    int                 page,
    int                 pageSize,
  })> getProductReviews(
    String productId, {
    int    page     = 1,
    int    pageSize = 10,
    int?   rating,
    String sort     = 'newest',
  }) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/product/$productId',
        queryParameters: {
          'page':     page,
          'pageSize': pageSize,
          if (rating != null) 'rating': rating,
          'sort':     sort,
        },
      );

      if (response.data['Success'] == true || response.data['success'] == true) {
        final data        = response.data as Map<String, dynamic>;
        final summaryJson = data['Summary'] as Map<String, dynamic>?;
        final list        = (data['Data'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return ReviewModel.fromJson(m['ReviewId']?.toString() ?? m['id']?.toString() ?? m['reviewId']?.toString() ?? '', m);
                })
                .toList() ??
            [];

        return (
          reviews:  list,
          summary:  summaryJson != null ? ReviewSummaryModel.fromJson(summaryJson) : null,
          total:    data['Total']    as int? ?? 0,
          page:     data['Page']     as int? ?? page,
          pageSize: data['PageSize'] as int? ?? pageSize,
        );
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to fetch product reviews';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // GET /reviews/{reviewId}
  // ============================================================================
  @override
  Future<ReviewModel> getReview(String reviewId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$reviewId');

      if (response.data['Success'] == true || response.data['success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return ReviewModel.fromJson(d['ReviewId']?.toString() ?? d['id']?.toString() ?? reviewId, d);
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to fetch review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // GET /reviews/user/{userId}
  // ============================================================================
  @override
  Future<({
    List<ReviewModel> reviews,
    int               total,
    int               page,
    int               pageSize,
  })> getUserReviews(
    String userId, {
    int page     = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/user/$userId',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data['Success'] == true || response.data['success'] == true) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['Data'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return ReviewModel.fromJson(m['ReviewId']?.toString() ?? m['id']?.toString() ?? m['reviewId']?.toString() ?? '', m);
                })
                .toList() ??
            [];

        return (
          reviews:  list,
          total:    data['Total']    as int? ?? 0,
          page:     data['Page']     as int? ?? page,
          pageSize: data['PageSize'] as int? ?? pageSize,
        );
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to fetch user reviews';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // POST /reviews — ReviewRepository.submitReview
  // ============================================================================
  @override
  Future<ReviewModel> submitReview({
    required ProductModel product,
    required double       rating,
    String?               comment,
    bool                  isApproved = false,
  }) async {
    try {
      final response = await dio.post(
        getEndpoint(),
        data: {
          'productId': product.id,
          'rating':    rating.round(),
          if (comment != null) 'body': comment,
        },
      );

      if (response.data['Success'] == true || response.data['success'] == true) {
        final d = response.data['Data'] as Map<String, dynamic>;
        return ReviewModel.fromJson(d['ReviewId']?.toString() ?? d['id']?.toString() ?? '', d);
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to submit review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // POST /reviews (detaylı)
  // ============================================================================
  @override
  Future<String> createReview({
    required String   productId,
    required String   userId,
    required int      rating,
    String?           title,
    String?           body,
    List<String>?     images,
  }) async {
    try {
      final response = await dio.post(getEndpoint(), data: {
        'productId': productId,
        'userId':    userId,   // backend reads UserId from body, not from JWT
        'rating':    rating,
        if (title  != null) 'title':  title,
        if (body   != null) 'body':   body,
        if (images != null) 'images': images,
      });

      if (response.data['Success'] == true || response.data['success'] == true) {
        final data = response.data['Data'] as Map<String, dynamic>?;
        return data?['ReviewId'] as String? ?? data?['reviewId'] as String? ?? '';
      } else {
        final msg = response.data['Message'] ?? response.data['message'] ??
            response.data['Errors'] ?? response.data['errors'] ?? 'Failed to create review';
        throw msg.toString();
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // PUT /reviews/{reviewId}
  // ============================================================================
  @override
  Future<void> updateReview({
    required String   reviewId,
    required int      rating,
    String?           title,
    String?           body,
    List<String>?     images,
  }) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/$reviewId',
        data: {
          'rating': rating,
          if (title  != null) 'title':  title,
          if (body   != null) 'body':   body,
          if (images != null) 'images': images,
        },
      );

      if (response.data['Success'] != true && response.data['success'] != true) {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to update review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // DELETE /reviews/{reviewId} — ReviewRepository.deleteReview
  // ============================================================================
  @override
  Future<void> deleteReview({
    required ReviewModel review,
    required String      productId,
  }) async {
    try {
      final response = await dio.delete('${getEndpoint()}/${review.id}');

      if (response.data['Success'] != true && response.data['success'] != true) {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to delete review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // POST /reviews/{reviewId}/vote
  // ============================================================================
  @override
  Future<void> voteReview({
    required String reviewId,
    required String userId,
    required bool   isHelpful,
  }) async {
    try {
      final response = await dio.post(
        '${getEndpoint()}/$reviewId/vote',
        data: {'userId': userId, 'isHelpful': isHelpful},
      );

      if (response.data['Success'] != true && response.data['success'] != true) {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to vote review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // PATCH /reviews/{reviewId}/moderate
  // ============================================================================
  @override
  Future<void> moderateReview({
    required String reviewId,
    required String status,
    String?         adminNote,
    String?         moderatedBy,
  }) async {
    try {
      final response = await dio.patch(
        '${getEndpoint()}/$reviewId/moderate',
        data: {
          'status': status,
          if (adminNote   != null) 'adminNote':   adminNote,
          if (moderatedBy != null) 'moderatedBy': moderatedBy,
        },
      );

      if (response.data['Success'] != true && response.data['success'] != true) {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to moderate review';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ============================================================================
  // GET /reviews/pending
  // ============================================================================
  @override
  Future<({
    List<ReviewModel> reviews,
    int               total,
    int               page,
    int               pageSize,
  })> getPendingReviews({int page = 1, int pageSize = 20}) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/pending',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data['Success'] == true || response.data['success'] == true) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['Data'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return ReviewModel.fromJson(m['ReviewId']?.toString() ?? m['id']?.toString() ?? m['reviewId']?.toString() ?? '', m);
                })
                .toList() ??
            [];

        return (
          reviews:  list,
          total:    data['Total']    as int? ?? 0,
          page:     data['Page']     as int? ?? page,
          pageSize: data['PageSize'] as int? ?? pageSize,
        );
      } else {
        throw response.data['Message'] ?? response.data['message'] ?? 'Failed to fetch pending reviews';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
