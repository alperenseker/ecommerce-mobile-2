/// Bir kategorinin alt kategorileri; her alt kategori için yatay ürün rafı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/product_cards/product_card_horizontal.dart';
import '../../../../common/widgets/shimmers/horizontal_product_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/cloud_helper_functions.dart';
import '../../controllers/categories_controller.dart';
import '../../models/category_model.dart';
import '../all_products/all_products.dart';

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoryController());
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(category.name),
        showActions: false,
        showSkipButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Alt kategoriler
              FutureBuilder(
                future: controller.getSubCategories(category.id),
                builder: (_, snapshot) {
                  const loader = THorizontalProductShimmer();
                  final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
                  if (widget != null) return widget;

                  final subCategories = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: subCategories.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, index) {
                      final subCategory = subCategories[index];

                      /// Alt kategorinin ürünleri
                      return FutureBuilder(
                        future: controller.getCategoryProducts(categoryId: subCategory.id),
                        builder: (_, snapshot) {
                          final widget =
                              TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
                          if (widget != null) return widget;

                          final products = snapshot.data!;
                          return Column(
                            children: [
                              /// Alt kategori başlığı
                              TSectionHeading(
                                title: subCategory.name,
                                showActionButton: true,
                                // Süzme sunucuda `categoryId` ile yapılır; ürün
                                // listesi yanıtı kategori kimliği taşımıyor.
                                onPressed: () => Get.to(() => AllProducts(
                                      title: subCategory.name,
                                      futureMethod:
                                          controller.getCategoryProducts(categoryId: subCategory.id),
                                    )),
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems / 2),

                              /// Alt kategori ürünleri
                              SizedBox(
                                height: TSizes.productCardHorizontalHeight,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: products.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: TSizes.spaceBtwItems),
                                  itemBuilder: (context, index) =>
                                      TProductCardHorizontal(product: products[index]),
                                ),
                              ),
                              const SizedBox(height: TSizes.spaceBtwSections),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
