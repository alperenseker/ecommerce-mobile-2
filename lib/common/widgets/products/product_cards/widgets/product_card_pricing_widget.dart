/// Kartın fiyat bloğu: (varsa) üstü çizili eski fiyat + güncel fiyat.
///
/// 🔴 Fiyat gizliyse eski fiyat da gösterilmez — yalnızca ana fiyatı gizlemek
/// indirimli fiyatı sızdırırdı.
library;

import 'package:flutter/material.dart';

import '../../../../../features/shop/controllers/product/product_controller.dart';
import '../../../../../features/shop/models/product_model.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../texts/t_product_price_text.dart';

class PricingWidget extends StatelessWidget {
  const PricingWidget({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    // NOT: Düz bir Column döndürülür (Flexible DEĞİL). Çağıran zaten bunu
    // kendi Row'unun içinde Flexible ile sarıyor; burada da Flexible dönmek
    // "Incorrect use of ParentDataWidget" hatası veriyordu.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Eski fiyat — yalnız indirim varsa ve fiyat gizli değilse.
        if (!product.isPriceHidden &&
            product.productType == ProductType.simple &&
            (product.salePrice ?? 0) > 0)
          Text(
            '₸${product.price}',
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .apply(decoration: TextDecoration.lineThrough, color: TColors.darkGrey),
          ),

        /// Güncel fiyat (indirim varsa indirimli olan).
        TProductPriceText(
          price: ProductController.instance.getProductPrice(product),
          priceHidden: product.isPriceHidden,
        ),
      ],
    );
  }
}
