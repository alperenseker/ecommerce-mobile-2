/// "Yeni gelenler" ile "öne çıkanlar" arasındaki tanıtım afişi slider'ı.
///
/// Görseller `assets/slider2/` (1.png, 2.png, 3.png), hepsi 1024x702. Alttaki
/// yumuşak geçiş fotoğrafı yuvarlatılmış köşeye bağlar ve üstündeki metni
/// okunur kılar. Üstteki [THomeSlider] gibi dokunulunca durur.
library;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class _Banner {
  const _Banner({required this.image, required this.titleKey, required this.subtitleKey});

  final String image;
  final String titleKey;
  final String subtitleKey;
}

class TPromoBannerSlider extends StatefulWidget {
  const TPromoBannerSlider({super.key});

  static const _banners = [
    _Banner(image: 'assets/slider2/1.png', titleKey: TTexts.promoBanner1Title, subtitleKey: TTexts.promoBanner1Subtitle),
    _Banner(image: 'assets/slider2/2.png', titleKey: TTexts.promoBanner2Title, subtitleKey: TTexts.promoBanner2Subtitle),
    _Banner(image: 'assets/slider2/3.png', titleKey: TTexts.promoBanner3Title, subtitleKey: TTexts.promoBanner3Subtitle),
  ];

  @override
  State<TPromoBannerSlider> createState() => _TPromoBannerSliderState();
}

class _TPromoBannerSliderState extends State<TPromoBannerSlider> {
  final CarouselSliderController _slider = CarouselSliderController();
  int _current = 0;
  bool _autoPlay = true;

  void _pause() {
    if (!_autoPlay) return;
    setState(() => _autoPlay = false);
  }

  void _resume() {
    if (_autoPlay) return;
    setState(() => _autoPlay = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Listener(
          onPointerDown: (_) => _pause(),
          onPointerUp: (_) => _resume(),
          onPointerCancel: (_) => _resume(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            child: AspectRatio(
              aspectRatio: 1024 / 702,
              child: CarouselSlider(
                carouselController: _slider,
                options: CarouselOptions(
                  viewportFraction: 1,
                  autoPlay: _autoPlay,
                  autoPlayInterval: const Duration(seconds: 6),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  enableInfiniteScroll: true,
                  onPageChanged: (index, _) => setState(() => _current = index),
                ),
                items: TPromoBannerSlider._banners.map(_buildBanner).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        AnimatedSmoothIndicator(
          activeIndex: _current,
          count: TPromoBannerSlider._banners.length,
          onDotClicked: (index) => _slider.animateToPage(index),
          effect: const ExpandingDotsEffect(
            activeDotColor: TColors.primary,
            dotColor: TColors.grey,
            dotHeight: 6,
            dotWidth: 6,
            spacing: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(_Banner banner) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(banner.image, fit: BoxFit.cover, width: double.infinity),

        // Fotoğraf yuvarlatılmış köşede sert bitmesin ve üstündeki yazı
        // okunsun diye yumuşak geçiş.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [TColors.dark.withValues(alpha: 0.55), Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
        ),

        Positioned(
          left: TSizes.md,
          right: TSizes.md,
          bottom: TSizes.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                banner.titleKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
              ),
              const SizedBox(height: 2),
              Text(
                banner.subtitleKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall!.apply(color: TColors.white),
              ),
              const SizedBox(height: TSizes.sm),
              OutlinedButton(
                onPressed: () => Get.toNamed(TRoutes.store),
                style: OutlinedButton.styleFrom(
                  // 🔴 Zemin AÇIKÇA saydam yapılmalı: ikincil düğme teması
                  // (TASARIM.md §6) zemini beyaz veriyor ve buradaki yazı da
                  // beyaz olduğu için düğme fotoğrafın üstünde boş bir beyaz
                  // dikdörtgen olarak çıkıyordu.
                  backgroundColor: Colors.transparent,
                  foregroundColor: TColors.white,
                  side: const BorderSide(color: TColors.white),
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(TTexts.shopNow.tr,
                        style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 12, color: TColors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
