/// Sıralanabilir ürün ızgarası (marka ekranı gibi yerlerde kullanılır).
///
/// Sıralama seçenekleri ve kuralı [AllProductsController] üzerinden gelir;
/// 🔴 fiyatı gizli/olmayan ürün YÖN NE OLURSA OLSUN sona gider.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../features/shop/controllers/all_products_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/sizes.dart';
import '../../layouts/grid_layout.dart';
import '../product_cards/product_card_vertical.dart';

class TSortableProducts extends StatelessWidget {
  const TSortableProducts({
    super.key,
    required this.products,
  });

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductsController());

    /// Ürünleri build sırasında değil, kare çizildikten sonra ata: build
    /// içinde `Rx` yazmak "setState during build" hatası veriyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.products.clear();
      controller.assignProducts(products);
    });

    return Column(
      children: [
        /// Sıralama seçici
        Obx(
          () => DropdownButtonFormField<AllProductsSort>(
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.sort)),
            initialValue: controller.selectedSortOption.value,
            onChanged: (value) => controller.sortProducts(value!),
            items: AllProductsSort.values
                .map((option) => DropdownMenuItem(value: option, child: Text(option.labelKey.tr)))
                .toList(),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        Obx(
          () => TGridLayout(
            itemCount: controller.products.length,
            itemBuilder: (_, index) =>
                TProductCardVertical(product: controller.products[index], isNetworkImage: true),
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + TSizes.defaultSpace),
      ],
    );
  }
}
