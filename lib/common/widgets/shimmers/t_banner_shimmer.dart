/// Ana sayfa afiş/slider alanı için yükleme parıltısı.
library;

import 'package:flutter/widgets.dart';

import 'shimmer.dart';

class TBannerShimmer extends StatelessWidget {
  const TBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const TShimmerEffect(width: double.infinity, height: 190);
  }
}
