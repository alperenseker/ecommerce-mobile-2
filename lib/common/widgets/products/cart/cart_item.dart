/// Salt okunur sepet kalemi satırı (görsel · marka · ad · adet · seçili
/// varyasyon).
///
/// Sepet ekranı miktar adımlayıcılı kendi kartını çiziyor; bu widget ödeme
/// özeti gibi kalemlerin **değiştirilemediği** yerler içindir
/// (`TCartItems(showAddRemoveButtons: false)`).
library;

import 'package:flutter/material.dart';

import '../../../../features/shop/models/cart_item_model.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../images/t_rounded_image.dart' show TRoundedImage;
import '../../texts/t_brand_title_text_with_verified_icon.dart';
import '../../texts/t_product_title_text.dart';

class TCartItem extends StatelessWidget {
  const TCartItem({
    super.key,
    required this.item,
  });

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        /// 1 — Görsel
        TRoundedImage(
          width: 60,
          height: 60,
          isNetworkImage: true,
          imageUrl: item.image ?? '',
          padding: const EdgeInsets.all(TSizes.sm),
          backgroundColor: dark ? TColors.darkerGrey : TColors.light,
        ),
        const SizedBox(width: TSizes.spaceBtwItems),

        /// 2 — Marka, ad, adet ve seçili varyasyon
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Marka ve ad
              (item.brandName ?? '').isNotEmpty ? TBrandTitleWithVerifiedIcon(title: item.brandName!) : const SizedBox.shrink(),
              Row(
                children: [
                  Flexible(child: TProductTitleText(title: item.title, maxLines: 1)),
                  const SizedBox(width: TSizes.sm),
                  Text('x${item.quantity}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),

              /// Öznitelikler (renk seçiliyse yuvarlak örnek çizilir)
              Text.rich(
                TextSpan(
                  children: (item.selectedVariation ?? {})
                      .entries
                      .map((e) {
                        final label = TextSpan(text: '${e.key}: ', style: Theme.of(context).textTheme.bodySmall);

                        final value = (e.key == 'Colors')
                            ? WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: THelperFunctions.restoreColorFromValue(e.value),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                ),
                              )
                            : TextSpan(text: '${e.value} ', style: Theme.of(context).textTheme.bodyLarge);

                        final space = TextSpan(text: ' ', style: Theme.of(context).textTheme.bodySmall);

                        return [label, value, space]; // returns List<InlineSpan>
                      })
                      .expand((spans) => spans) // flattens to List<InlineSpan>
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
