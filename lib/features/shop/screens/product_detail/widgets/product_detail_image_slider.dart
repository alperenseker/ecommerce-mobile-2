/// Ürün detayının görsel galerisi: kaydırılabilir büyük görsel + küçük resim
/// şeridi + tam ekran büyütme.
///
/// TASARIM.md §6: görsel **açık gri altlıkta** (`lightContainer`), yumuşak
/// köşeli, gölgesiz. Referanstaki koyu kavisli başlık (`TCurvedEdgesWidget`)
/// kalktı — TASARIM.md §7 bu kavisi bütün ekranlardan kaldırıyor.
///
/// Sağ üstteki kalp/karşılaştır düğmeleri kart üstündekilerle **aynı**
/// widget'lar; bkz. `common/widgets/products/favourite_icon/`.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../common/widgets/products/compare_icon/compare_icon.dart';
import '../../../../../common/widgets/products/favourite_icon/favourite_icon.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/images_controller.dart';
import '../../../models/product_model.dart';

class TProductImageSlider extends StatefulWidget {
  const TProductImageSlider({super.key, required this.product, this.isNetworkImage = true});

  final ProductModel product;
  final bool isNetworkImage;

  @override
  State<TProductImageSlider> createState() => _TProductImageSliderState();
}

class _TProductImageSliderState extends State<TProductImageSlider> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Küçük resme dokununca büyük görseli oraya kaydır (ve tersi).
  void _jumpTo(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ImagesController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      color: dark ? TColors.dark : TColors.white,
      child: Column(
        children: [
          Stack(
            children: [
              /// Büyük görsel — parmakla kaydırılır, dokununca tam ekran açılır.
              Obx(() {
                final images = controller.images.isEmpty
                    ? [widget.product.thumbnail]
                    : controller.images.toList();

                return SizedBox(
                  height: 340,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) => controller.selectedProductImage.value = images[index],
                    itemBuilder: (_, index) => GestureDetector(
                      onTap: () => controller.showEnlargedImage(images[index]),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(
                          TSizes.defaultSpace,
                          TSizes.appBarHeight + TSizes.md,
                          TSizes.defaultSpace,
                          TSizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? TColors.darkSurface : TColors.lightContainer,
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                        ),
                        padding: const EdgeInsets.all(TSizes.md),
                        child: _image(images[index]),
                      ),
                    ),
                  ),
                );
              }),

              /// Başlık çubuğu ikonları (geri · karşılaştır · favori)
              TAppBar(
                showBackArrow: true,
                actions: [
                  TCompareIcon(productId: widget.product.id, product: widget.product),
                  const SizedBox(width: TSizes.sm),
                  TFavouriteIcon(productId: widget.product.id, productModel: widget.product),
                ],
                showActions: true,
                showSkipButton: false,
              ),
            ],
          ),

          /// Küçük resim şeridi — tek görselli üründe hiç çizilmez.
          Obx(() {
            final images = controller.images;
            if (images.length < 2) return const SizedBox(height: TSizes.sm);

            return Padding(
              padding: const EdgeInsets.only(bottom: TSizes.md),
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: images.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                  separatorBuilder: (_, _) => const SizedBox(width: TSizes.sm),
                  itemBuilder: (_, index) => Obx(() {
                    final selected = controller.selectedProductImage.value == images[index];
                    return TRoundedImage(
                      isNetworkImage: widget.isNetworkImage,
                      width: 68,
                      height: 68,
                      fit: BoxFit.contain,
                      imageUrl: images[index],
                      padding: const EdgeInsets.all(TSizes.xs),
                      borderRadius: TSizes.borderRadiusSm,
                      backgroundColor: dark ? TColors.darkSurface : TColors.lightContainer,
                      // Küçük resim ekranda 68px; tam çözünürlük çözmeye gerek yok.
                      memCacheWidth: 204,
                      onPressed: () {
                        controller.selectedProductImage.value = images[index];
                        _jumpTo(index);
                      },
                      border: Border.all(
                        color: selected
                            ? TColors.primary
                            : (dark ? TColors.darkBorder : TColors.borderSecondary),
                        width: selected ? 2 : 1,
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _image(String image) {
    if (!widget.isNetworkImage || image.isEmpty) {
      return Image(
        image: AssetImage(
          !widget.isNetworkImage && image.isNotEmpty ? image : TImages.productImageFallback,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (_, _, progress) => Center(
        child: CircularProgressIndicator(value: progress.progress, color: TColors.primary),
      ),
      errorWidget: (_, _, _) => Image.asset(TImages.productImageFallback),
    );
  }
}
