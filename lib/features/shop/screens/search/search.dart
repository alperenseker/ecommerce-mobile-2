/// Arama ekranı.
///
/// 🔴 En az [TSearchController.minQueryLength] (2) karakter yazılmadan arama
/// başlamaz; tek harf bütün kataloğu döndürüp listeyi anlamsızlaştırıyordu.
/// Eşleşme ad / stok kodu / açıklama üzerinde yapılır.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/search_controller.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  final controller = Get.put(TSearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.search.tr, style: Theme.of(context).textTheme.headlineSmall),
        showActions: false,
        showSkipButton: false,
        showBackArrow: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Arama kutusu
          Padding(
            padding: const EdgeInsets.fromLTRB(
                TSizes.defaultSpace, TSizes.sm, TSizes.defaultSpace, TSizes.spaceBtwItems),
            child: TextField(
              controller: controller.textController,
              autofocus: true,
              onChanged: controller.search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                hintText: TTexts.searchInStore.tr,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md),
                suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
                suffixIcon: Obx(() {
                  if (controller.query.value.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Iconsax.close_circle, size: 18),
                    onPressed: controller.clearSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          /// -- Sonuçlar
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const TDelayedLoader();
              }

              // Yeterli sorgu yoksa arama yapılmaz; sade bir yönlendirme çizilir.
              if (!controller.hasEnoughQuery) {
                return const _SearchHint();
              }

              final all = controller.matchedProducts;
              if (all.isEmpty) {
                return Center(
                  child: Text(TTexts.noDataFound.tr, style: Theme.of(context).textTheme.bodyMedium),
                );
              }

              final visible = controller.visibleCount.value;
              final shown = visible >= all.length ? all : all.sublist(0, visible);
              final hasMore = visible < all.length;

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        TSizes.defaultSpace, TSizes.defaultSpace, TSizes.defaultSpace, TSizes.spaceBtwItems),
                    sliver: SliverToBoxAdapter(
                      child: Text('${all.length} ${TTexts.products.tr}',
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: TSizes.productCardHeight,
                        mainAxisSpacing: TSizes.gridViewSpacing,
                        crossAxisSpacing: TSizes.gridViewSpacing,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => TProductCardVertical(product: shown[index]),
                        childCount: shown.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.spaceBtwSections,
                          TSizes.defaultSpace, TSizes.defaultSpace),
                      child: hasMore
                          ? SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: controller.showMore,
                                icon: const Icon(Iconsax.arrow_down_1, size: 16),
                                label: Text(TTexts.loadMore.tr),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Kullanıcı henüz yeterince yazmadan görünen boş durum (TASARIM.md §6).
class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: TColors.lightContainer, shape: BoxShape.circle),
            child: const Icon(Iconsax.search_normal, size: 32, color: TColors.darkGrey),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(TTexts.searchInStore.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TSizes.xs),
          Text(
            '${TSearchController.minQueryLength}+',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
