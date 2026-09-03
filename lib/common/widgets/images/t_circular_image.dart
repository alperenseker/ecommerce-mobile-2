/// Daire görsel (avatar, marka logosu).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../shimmers/shimmer.dart';

class TCircularImage extends StatelessWidget {
  const TCircularImage({
    super.key,
    this.width = 56,
    this.height = 56,
    this.overlayColor,
    this.backgroundColor,
    required this.image,
    this.fit = BoxFit.cover,
    this.padding = TSizes.sm,
    this.isNetworkImage = false,
    this.placeholderIcon,
    this.placeholderIconColor,
  });

  final BoxFit? fit;
  final String image;
  final bool isNetworkImage;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;

  /// Ağ görseli yoksa varlık görseli yerine bu ikon çizilir (ör. profil
  /// resmi olmayan kullanıcı için [Icons.person]).
  final IconData? placeholderIcon;

  /// [placeholderIcon] rengi. [overlayColor]'dan ayrı tutuluyor ki gerçek bir
  /// fotoğrafı asla renklendirmesin.
  final Color? placeholderIconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? (THelperFunctions.isDarkMode(context) ? TColors.darkSurface : TColors.white),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Center(
          child: isNetworkImage
              ? CachedNetworkImage(
                  fit: fit,
                  color: overlayColor,
                  imageUrl: image,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      const TShimmerEffect(width: 55, height: 55, radius: 55),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : placeholderIcon != null
                  ? Icon(
                      placeholderIcon,
                      size: width * 0.6,
                      color: placeholderIconColor ?? TColors.darkGrey,
                    )
                  : Image(
                      fit: fit,
                      image: AssetImage(image),
                      color: overlayColor,
                    ),
        ),
      ),
    );
  }
}
