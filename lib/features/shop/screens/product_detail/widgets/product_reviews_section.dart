/// Bir ürünün değerlendirme bloğu: özet (ortalama + dağılım çubukları),
/// yorum listesi ve "yorum yaz / düzenle" düğmesi.
///
/// Hem ürün detayının **yorumlar sekmesinde** hem de tam ekran listede
/// ([SingleProductReviewsScreen]) aynı blok kullanılır — iki yerde iki farklı
/// yorum ekranı olmasın diye.
///
/// 🔴 Yorum yazmak SATIN ALMA ŞARTINA bağlı ve şartı **sunucu** uyguluyor
/// (bkz. [ReviewController]). İstemci burada kapı tutmaz; misafiri giriş
/// ekranına yollar, giriş yapmış kullanıcı deneyebilir ve satın almamışsa
/// sunucunun reddi anlaşılır bir uyarıya çevrilir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/shimmers/review_shimmer.dart';
import '../../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../../data/repositories/reviews/reviews_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/review_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_review_model.dart';
import '../../review/review_screen.dart';
import 't_review_card.dart';
import '../../product_reviews/widgets/progress_indicator_and_rating.dart';

class TProductReviewsSection extends StatefulWidget {
  const TProductReviewsSection({super.key, required this.product, this.pageSize = 20});

  final ProductModel product;
  final int pageSize;

  @override
  State<TProductReviewsSection> createState() => _TProductReviewsSectionState();
}

class _TProductReviewsSectionState extends State<TProductReviewsSection> {
  late final ReviewController _controller = Get.put(ReviewController());

  /// Tek seferlik istek: `FutureBuilder`'a doğrudan `fetch...()` vermek her
  /// yeniden çizimde yeni istek atıyor (sekme değişimi, klavye vb.).
  late Future<({List<ReviewModel> reviews, ReviewSummaryModel summary, int total})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TProductReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Varyant seçilince ekrandaki ürün değişiyor; yorumlar da yeni ürünün.
    if (oldWidget.product.id != widget.product.id) {
      _future = _load();
    }
  }

  Future<({List<ReviewModel> reviews, ReviewSummaryModel summary, int total})> _load() =>
      _controller.fetchProductReviews(widget.product.id, pageSize: widget.pageSize);

  /// Yorum yazma ekranını açar. Değerlendirme ekranı sepet kalemi modelini
  /// istiyor (referansta da öyle); ürünü ona çeviriyoruz.
  void _openWriteReview() {
    final authRepo = AuthenticationRepository.instance;
    if (authRepo.isGuestUser) {
      authRepo.showSignInRequiredPopup();
      return;
    }

    final existing = _controller.userReviewFor(widget.product.id);
    Get.to(() => ProductReviewsScreen(
          product: CartItemModel(
            productId: widget.product.id,
            quantity: 1,
            title: widget.product.title,
            image: widget.product.thumbnail,
            price: widget.product.price,
          ),
          existingReview: existing,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return FutureBuilder(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                child: TReviewCardShimmer(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _EmptyReviews(
            message: TTexts.noReviewsYet.tr,
            onWrite: _openWriteReview,
          );
        }

        final data = snapshot.data!;
        if (data.reviews.isEmpty) {
          return _EmptyReviews(message: TTexts.noReviewsYet.tr, onWrite: _openWriteReview);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Özet: ortalama + 5→1 dağılım çubukları
            TOverallProductRating(summary: data.summary),
            const SizedBox(height: TSizes.spaceBtwItems),
            Divider(color: dark ? TColors.darkBorder : TColors.borderSecondary, height: 1),
            const SizedBox(height: TSizes.spaceBtwItems),

            /// Yorumlar
            ListView.separated(
              itemCount: data.reviews.length,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) => ReviewCard(reviewModel: data.reviews[index]),
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 2),
                child: Divider(
                  color: dark ? TColors.darkBorder : TColors.borderSecondary,
                  height: 1,
                ),
              ),
            ),

            /// Toplam sayfadan fazlaysa bunu söyle — sessizce kırpma.
            if (data.total > data.reviews.length) ...[
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                '${data.reviews.length} / ${data.total}',
                style: Theme.of(context).textTheme.bodySmall!.apply(color: TColors.darkGrey),
              ),
            ],

            const SizedBox(height: TSizes.spaceBtwItems),
            _WriteReviewButton(
              isEdit: _controller.hasReviewed(widget.product.id),
              onPressed: _openWriteReview,
            ),
          ],
        );
      },
    );
  }
}

/// Hiç yorum yokken: web'deki boş durum kutusu (ikon + metin + tek düğme).
class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.message, required this.onWrite});

  final String message;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      children: [
        const SizedBox(height: TSizes.spaceBtwItems),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.lightContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.star, color: TColors.darkGrey),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        _WriteReviewButton(isEdit: false, onPressed: onWrite),
      ],
    );
  }
}

class _WriteReviewButton extends StatelessWidget {
  const _WriteReviewButton({required this.isEdit, required this.onPressed});

  final bool isEdit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Iconsax.edit, size: TSizes.iconSm),
        label: Text((isEdit ? TTexts.editReview : TTexts.writeReview).tr),
      ),
    );
  }
}
