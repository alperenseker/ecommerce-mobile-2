/// Değerlendirme akışı: liste, puan dağılımı, yorum yazma ve düzenleme.
///
/// 🔴 SATIN ALMA ŞARTI sunucudadır: `POST /reviews` yalnız kullanıcının
/// **teslim edilmiş** siparişinde geçen ürünler için kabul edilir. İstemci bu
/// kuralı taklit etmez (sipariş geçmişi burada yok); sunucu reddedince ham
/// hata yerine anlaşılır bir uyarı gösterilir — web `review.service.js` de
/// aynı şeyi yapıyor.
library;

import 'package:get/get.dart';

import '../../../common/widgets/success_screen/success_screen.dart';
import '../../../data/repositories/reviews/api_reviews_repository.dart';
import '../../../data/repositories/reviews/reviews_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/cart_item_model.dart';
import '../models/product_review_model.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final reviewRepository = ApiReviewsRepository.instance;

  /// Kullanıcı kimliği yorum gövdesine gidiyor (sunucu `UserId`yi gövdeden
  /// okuyor). Referansta burada koşulsuz `Get.put(UserController())` var; o
  /// hâli uygulama genelindeki controller'ı HER seferinde yenisiyle
  /// değiştiriyor ve kullanıcı kaydını gereksiz yere yeniden çekiyordu.
  /// Kayıtlıysa var olan kullanılır.
  final userController = Get.isRegistered<UserController>()
      ? UserController.instance
      : Get.put(UserController());

  RxInt rating = 0.obs;
  var reviewText = ''.obs;

  /// Kullanıcının daha önce değerlendirdiği ürün kimlikleri.
  final reviewedProductIds = <String>{}.obs;

  /// productId -> kullanıcının kendi yorumu. Düzenleme ekranı kayıtlı puanı ve
  /// metni buradan doldurur (`PUT /reviews/{id}` için `reviewId` gerekiyor).
  final reviewedReviews = <String, ReviewModel>{}.obs;

  /// Bir ürünün yorumları — yalnız liste.
  Future<List<ReviewModel>> fetchReview(String productId) async {
    final result = await reviewRepository.getProductReviews(productId);
    return result.reviews;
  }

  /// Ürün detayının "yorumlar" sekmesi: liste + özet birlikte.
  ///
  /// Özet (`Summary`) sunucudan geliyor ve **bütün** yorumları kapsıyor;
  /// sayfadaki 20 yorumdan hesaplanan ortalama yanıltıcı olurdu. Özet
  /// gelmezse gelen sayfadan hesaplanır (web `Review.distribution`).
  Future<({List<ReviewModel> reviews, ReviewSummaryModel summary, int total})> fetchProductReviews(
    String productId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await reviewRepository.getProductReviews(
      productId,
      page: page,
      pageSize: pageSize,
    );
    return (
      reviews: result.reviews,
      summary: result.summary ?? distributionOf(result.reviews),
      total: result.total,
    );
  }

  /// Gelen yorumlardan puan dağılımı çıkarır (özet yoksa yedek yol).
  ReviewSummaryModel distributionOf(List<ReviewModel> reviews) {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var sum = 0.0;
    for (final review in reviews) {
      final star = review.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
      sum += star;
    }
    return ReviewSummaryModel(
      averageRating: reviews.isEmpty ? 0 : sum / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: counts,
    );
  }

  /// Sipariş detayı açılınca bir kez çağrılır: hangi ürünler zaten
  /// değerlendirilmiş, onu bilmek için.
  Future<void> loadUserReviewedProducts() async {
    try {
      final userId = userController.user.value.id;
      if (userId.isEmpty) return;
      final result = await reviewRepository.getUserReviews(userId, pageSize: 100);
      reviewedProductIds.assignAll(result.reviews.map((r) => r.productId).toSet());
      reviewedReviews.assignAll({for (final r in result.reviews) r.productId: r});
    } catch (_) {
      // Kritik değil — hata hâlinde düğme görünür kalır.
    }
  }

  bool hasReviewed(String productId) => reviewedProductIds.contains(productId);

  /// Kullanıcının bir ürüne yazdığı yorum (yoksa null).
  ReviewModel? userReviewFor(String productId) => reviewedReviews[productId];

  void updateReviewText(String text) {
    reviewText.value = text;
  }

  Future<void> submitReview(CartItemModel item) async {
    if (rating.value == 0) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.giveRating.tr);
      return;
    }

    try {
      // POST /reviews — puan ortalamasını sunucu hesaplıyor.
      final newReviewId = await reviewRepository.createReview(
        productId: item.productId,
        userId: userController.user.value.id,
        rating: rating.value,
        body: reviewText.value.isEmpty ? null : reviewText.value,
      );

      // Ekran anında güncellensin diye yerelde de işaretle (ve düzenleme akışı
      // puanı/metni/`reviewId`yi elinin altında bulsun).
      reviewedProductIds.add(item.productId);
      reviewedReviews[item.productId] = ReviewModel(
        id: newReviewId,
        productId: item.productId,
        userId: userController.user.value.id,
        userName: '',
        rating: rating.value.toDouble(),
        reviewText: reviewText.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (rating.value != 0) await userController.updateUserPointsPerRating();
      if (reviewText.value.isNotEmpty) await userController.updateUserPointsPerReview();

      TLoaders.successSnackBar(title: TTexts.success.tr, message: TTexts.reviewSubmitted.tr);

      Get.off(() => SuccessScreen(
            image: TImages.orderCompletedAnimation,
            title: TTexts.reviewSubmit.tr,
            subTitle: TTexts.yourReviewSubmitted.tr,
            onPressed: () => Get.back(),
          ));
    } catch (e) {
      _showReviewError(e);
    }
  }

  /// Var olan yorumu günceller (`PUT /reviews/{reviewId}`).
  /// [existing] kullanıcının şu anki yorumu ([userReviewFor]).
  Future<void> editReview(ReviewModel existing) async {
    if (rating.value == 0) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.giveRating.tr);
      return;
    }
    if (existing.id.isEmpty) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.reviewSubmitted.tr);
      return;
    }

    try {
      await reviewRepository.updateReview(
        reviewId: existing.id,
        rating: rating.value,
        body: reviewText.value.isEmpty ? null : reviewText.value,
      );

      // Sipariş ekranı yeni puanı/metni görsün diye yerel kopyayı tazele.
      existing.rating = rating.value.toDouble();
      existing.reviewText = reviewText.value;
      existing.updatedAt = DateTime.now();
      reviewedReviews[existing.productId] = existing;
      reviewedReviews.refresh();

      TLoaders.successSnackBar(title: TTexts.success.tr, message: TTexts.reviewSubmitted.tr);

      Get.off(() => SuccessScreen(
            image: TImages.orderCompletedAnimation,
            title: TTexts.reviewSubmit.tr,
            subTitle: TTexts.yourReviewSubmitted.tr,
            onPressed: () => Get.back(),
          ));
    } catch (e) {
      _showReviewError(e);
    }
  }

  /// Sunucu hatasını okunabilir uyarıya çevirir.
  ///
  /// Sunucu satın alma şartını 400 + serbest metinle bildiriyor; ham İngilizce
  /// mesajı kullanıcıya basmak yerine üç durumu ayırıyoruz (web
  /// `review.service.js` ile aynı eşleme).
  void _showReviewError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('purchase') ||
        message.contains('order') ||
        message.contains('deliver')) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.reviewNeedPurchase.tr);
    } else if (message.contains('already') || message.contains('exists')) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.reviewAlreadyExists.tr);
    } else {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.reviewFailed.tr);
    }
  }
}
