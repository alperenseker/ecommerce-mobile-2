/// Köşeleri yuvarlatılmış (ağ ya da yerel) görsel.
///
/// 🔴 `memCacheWidth` boş bırakılmamalı: tam çözünürlüklü bir fotoğraf kart
/// başına ~9MB çözülüyor, bir ızgara dolusu kart cihazın belleğini bitiriyor.
/// Ekranda kaplayacağı piksel ölçüsünü geçin.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../shimmers/shimmer.dart';

class TRoundedImage extends StatelessWidget {
  const TRoundedImage({
    super.key,
    this.border,
    this.padding,
    this.onPressed,
    this.width,
    this.height,
    this.applyImageRadius = true,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.isNetworkImage = false,
    this.borderRadius = TSizes.borderRadiusSm,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final double? width, height;
  final String imageUrl;
  final bool applyImageRadius;
  final BoxBorder? border;
  final Color? backgroundColor;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final bool isNetworkImage;
  final VoidCallback? onPressed;
  final double borderRadius;

  /// Ağ görselinin bellekteki çözülmüş boyutunu sınırlar. Bkz. dosya başlığı.
  final int? memCacheWidth, memCacheHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          border: border,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: applyImageRadius ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
          child: isNetworkImage && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  fit: fit,
                  imageUrl: imageUrl,
                  memCacheWidth: memCacheWidth,
                  memCacheHeight: memCacheHeight,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      TShimmerEffect(width: width ?? double.infinity, height: height ?? 158),
                  errorWidget: (context, url, error) =>
                      Image(fit: fit, image: const AssetImage(TImages.productImageFallback)),
                )
              : Image(
                  fit: fit,
                  // URL'si boş ağ görseli yer tutucu görsele düşer.
                  image: AssetImage(!isNetworkImage && imageUrl.isNotEmpty ? imageUrl : TImages.productImageFallback),
                ),
        ),
      ),
    );
  }
}
