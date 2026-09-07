/// Yorum yazma / düzenleme ekranı.
///
/// [existingReview] verildiğinde düzenleme kipinde açılır: kayıtlı puan ve
/// metin doldurulur, gönderim `POST /reviews` yerine `PUT /reviews/{id}`
/// çağırır.
///
/// 🔴 Ekranın kendisi "bu ürünü aldın mı" diye bakmaz — şart sunucuda ve
/// **teslim edilmiş** sipariş üzerinden işliyor. Sunucu reddederse
/// [ReviewController] ham hata yerine "yalnız satın aldığınız ürünleri
/// değerlendirebilirsiniz" uyarısını gösterir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../common/widgets/star rating/star_rating.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/review_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_review_model.dart';

class ProductReviewsScreen extends StatefulWidget {
  const ProductReviewsScreen({super.key, required this.product, this.existingReview});

  final CartItemModel product;

  /// Doluysa ekran düzenleme kipinde açılır.
  final ReviewModel? existingReview;

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final ReviewController _reviewController = Get.put(ReviewController());
  late final TextEditingController _textController;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    // Controller paylaşımlı: yeni yorumda sıfırlanmazsa önceki taslak sızıyor.
    _reviewController.rating.value = existing?.rating.round() ?? 0;
    _reviewController.reviewText.value = existing?.reviewText ?? '';
    _textController = TextEditingController(text: existing?.reviewText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text((_isEdit ? TTexts.editReview : TTexts.writeReview).tr),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Ürün görseli
              Center(
                child: TRoundedImage(
                  imageUrl: widget.product.image ?? '',
                  isNetworkImage: (widget.product.image ?? '').isNotEmpty,
                  height: 140,
                  width: 140,
                  padding: const EdgeInsets.all(TSizes.sm),
                  borderRadius: TSizes.cardRadiusLg,
                  memCacheWidth: 420,
                  backgroundColor: dark ? TColors.darkSurface : TColors.lightContainer,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              if (widget.product.title.isNotEmpty)
                Text(
                  widget.product.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: TSizes.spaceBtwSections / 2),

              Text(
                TTexts.purchaseQuality.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                TTexts.outfitFeedback.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Yıldız seçici
              Center(
                child: Obx(
                  () => StarRating(
                    currentRating: _reviewController.rating.value,
                    onRatingChanged: (value) => _reviewController.rating.value = value,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Yorum metni
              TextField(
                controller: _textController,
                onChanged: (text) => _reviewController.updateReviewText(text),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: TTexts.shareThought.tr,
                  // Çok satırlı alanda tema yüksekliği (48px) metni kırpıyor.
                  contentPadding: const EdgeInsets.all(TSizes.md),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Eylemler
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text(TTexts.cancel.tr),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _isEdit
                          ? _reviewController.editReview(widget.existingReview!)
                          : _reviewController.submitReview(widget.product),
                      child: Text(TTexts.submit.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
