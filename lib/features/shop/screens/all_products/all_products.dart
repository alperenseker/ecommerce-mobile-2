/// "Tüm ürünler" ekranı — bir süzgeçle gelen ürün listesini sıralanabilir
/// ızgarada gösterir. Ana sayfanın "daha fazla" düğmeleri ve kategori menüsü
/// buraya bağlanır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/cloud_helper_functions.dart';
import '../../controllers/all_products_controller.dart';
import '../../models/product_model.dart';

/// Ürün listesini özel sıralama/süzme ile gösteren ekran.
class AllProducts extends StatelessWidget {
  const AllProducts({super.key, required this.title, this.futureMethod});

  /// Ekran başlığı.
  final String title;

  /// Ürünleri getiren gelecek (future). Verilmezse tüm katalog gelir.
  final Future<List<ProductModel>>? futureMethod;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductsController());

    return Scaffold(
      appBar: TAppBar(
        title: Text(title),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: FutureBuilder(
            future: futureMethod ?? controller.fetchProductsByQuery(null),
            builder: (_, snapshot) {
              const loader = TVerticalProductShimmer();
              final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);

              if (widget != null) return widget;

              final products = snapshot.data!;
              return TSortableProductList(products: products);
            },
          ),
        ),
      ),
    );
  }
}

/// Sıralanabilir ürün listesi.
class TSortableProductList extends StatelessWidget {
  const TSortableProductList({
    super.key,
    required this.products,
  });

  /// Gösterilecek ürünler.
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductsController());
    // Listeyi build sırasında değil, kare çizildikten sonra ata: build içinde
    // `Rx` yazmak "setState during build" hatası veriyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.assignProducts(products));

    return Column(
      children: [
        /// -- Sıralama
        Obx(
          () => DropdownButtonFormField<AllProductsSort>(
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Iconsax.sort)),
            initialValue: controller.selectedSortOption.value,
            onChanged: (value) => controller.sortProducts(value!),
            items: AllProductsSort.values
                .map((option) => DropdownMenuItem<AllProductsSort>(
                      value: option,
                      child: Text(option.labelKey.tr),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        /// -- Ürün ızgarası
        Obx(
          () => TGridLayout(
            itemCount: controller.products.length,
            itemBuilder: (_, index) => TProductCardVertical(product: controller.products[index]),
          ),
        ),

        /// Alt gezinme çubuğunun altında kalmasın diye boşluk
        SizedBox(height: TDeviceUtils.getBottomNavigationBarHeight() + TSizes.defaultSpace),
      ],
    );
  }
}
