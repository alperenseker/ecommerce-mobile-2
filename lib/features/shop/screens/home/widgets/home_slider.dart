/// Ana sayfanın üst slider'ı.
///
/// TASARIM.md §7 / FAZ 04: **3 sahne, otomatik ilerler, dokunulunca durur,
/// nokta göstergesi.** Web'deki `pages/home.js` slider'ı da aynı davranışta
/// (fare üstündeyken durur, dokunmada kaydırma).
///
/// 🔴 Otomatik ilerleme dokunulduğunda durmalı: kullanıcı bir sahneyi
/// okurken sahnenin altından kayması en sık gelen şikâyet.
library;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

/// Tek sahne: arka plan görseli, ürün görseli ve tanıtım metni.
class _Slide {
  const _Slide({
    required this.background,
    required this.foreground,
    required this.title,
    this.subtitle,
    this.subtitleAccent,
    this.description,
    this.textOnRight = true,
    this.foregroundPadding = const EdgeInsets.all(TSizes.md),
  });

  final String background;
  final String foreground;

  /// Kalın ana satır.
  final String title;

  /// 🔴 Bu alanlar metin DEĞİL, çeviri anahtarıdır (`TTexts.slider*`); liste
  /// `const` kalabilsin diye `.tr` çizim sırasında uygulanır.
  /// Başlığın üstündeki ince satır; [subtitleAccent] marka renginde eklenir.
  final String? subtitle;
  final String? subtitleAccent;

  /// Başlığın altındaki küçük satır.
  final String? description;

  /// Metin blokunun sağda mı (ürün solda) yoksa tersi mi durduğu.
  final bool textOnRight;

  /// Ürün görselinin çevresindeki boşluk — büyük dolgu = küçük ürün.
  final EdgeInsets foregroundPadding;
}

class THomeSlider extends StatefulWidget {
  const THomeSlider({super.key});

  @override
  State<THomeSlider> createState() => _THomeSliderState();
}

class _THomeSliderState extends State<THomeSlider> {
  static const List<_Slide> _slides = [
    _Slide(
      background: TImages.sliderImage1,
      foreground: TImages.sliderForeground1,
      subtitle: TTexts.sliderSubtitle1,
      title: TTexts.sliderTitle1,
      textOnRight: true,
    ),
    _Slide(
      background: TImages.sliderImage2,
      foreground: TImages.sliderForeground2,
      subtitle: TTexts.sliderSubtitle2,
      subtitleAccent: TTexts.sliderSubtitle2Accent,
      title: TTexts.sliderTitle2,
      description: TTexts.sliderDescription2,
      textOnRight: false,
      // window.png büyük çiziliyor, biraz küçültmek için dolgusu fazla.
      foregroundPadding: EdgeInsets.all(TSizes.lg + TSizes.sm),
    ),
    _Slide(
      background: TImages.sliderImage3,
      foreground: TImages.sliderForeground3,
      subtitle: TTexts.sliderSubtitle3,
      title: TTexts.sliderTitle3,
      textOnRight: true,
    ),
  ];

  final CarouselSliderController _slider = CarouselSliderController();
  int _current = 0;

  /// Dokunma sırasında otomatik ilerleme durur; parmak kalkınca geri başlar.
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
          // Dokunma başlayınca durdur, bırakılınca/iptal olunca devam ettir.
          onPointerDown: (_) => _pause(),
          onPointerUp: (_) => _resume(),
          onPointerCancel: (_) => _resume(),
          child: CarouselSlider(
            carouselController: _slider,
            options: CarouselOptions(
              height: 170,
              viewportFraction: 1,
              autoPlay: _autoPlay,
              autoPlayInterval: const Duration(seconds: 6),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enableInfiniteScroll: true,
              onPageChanged: (index, _) => setState(() => _current = index),
            ),
            items: _slides.map(_buildSlide).toList(),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        AnimatedSmoothIndicator(
          activeIndex: _current,
          count: _slides.length,
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

  Widget _buildSlide(_Slide slide) {
    final product = Expanded(
      child: Padding(
        padding: slide.foregroundPadding,
        child: Image.asset(slide.foreground, fit: BoxFit.contain),
      ),
    );
    final text = Expanded(child: _buildText(slide));

    return ClipRRect(
      borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      child: Container(
        width: double.infinity,
        color: TColors.lightContainer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(slide.background, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
              child: Row(
                children: slide.textOnRight ? [product, text] : [text, product],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(_Slide slide) {
    final theme = Theme.of(context);
    final align = slide.textOnRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = slide.textOnRight ? TextAlign.right : TextAlign.left;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: align,
      children: [
        if (slide.subtitle != null)
          RichText(
            textAlign: textAlign,
            text: TextSpan(
              style: theme.textTheme.bodySmall!.apply(color: TColors.darkerGrey),
              children: [
                TextSpan(text: slide.subtitle!.tr),
                if (slide.subtitleAccent != null)
                  TextSpan(
                    text: slide.subtitleAccent!.tr,
                    style: theme.textTheme.bodySmall!.apply(color: TColors.primary, fontWeightDelta: 2),
                  ),
              ],
            ),
          ),
        Text(
          slide.title.tr,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall!.apply(color: TColors.dark),
        ),
        if (slide.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              slide.description!.tr,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
          ),
        const SizedBox(height: TSizes.sm),
        // TASARIM.md §6 ikincil düğme: beyaz zemin + çerçeve, BÜYÜK HARF DEĞİL.
        OutlinedButton(
          onPressed: () => Get.toNamed(TRoutes.store),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(TTexts.shopNow.tr, style: theme.textTheme.labelLarge!.apply(color: TColors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 12, color: TColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}
