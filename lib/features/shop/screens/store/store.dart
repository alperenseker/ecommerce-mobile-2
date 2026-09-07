/// Mağaza ekranı — kataloğun tamamı, süzgeçli.
///
/// 🔴 Sayfa boyutu SABİT 48 ([StoreController.pageSize]); kullanıcıya "kaç
/// ürün" diye sorulmaz (web'de de o seçici kaldırıldı).
///
/// 🔴 Kategori seçimi **VEYA** mantığıyla çalışır: A ve B seçiliyse sonuç
/// ikisinin toplamıdır ve seçilen kategorinin alt ağacı otomatik dâhildir.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/profile_action_icon.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../home_menu.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/categories_controller.dart';
import '../../controllers/store_controller.dart';
import 'widgets/store_filter_bar.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeController = Get.put(StoreController());
    final categoryController = Get.put(CategoryController());

    return PopScope(
      canPop: false,
      // Geri tuşu uygulamadan çıkmak yerine ana sekmeye döner.
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        AppScreenController.instance.selectedMenu.value = 0;
      },
      child: Scaffold(
        appBar: TAppBar(
          title: Text(TTexts.tStore.tr, style: Theme.of(context).textTheme.headlineSmall),
          actions: const [TProfileActionIcon()],
          showActions: true,
          showSkipButton: false,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Arama kutusu + süzgeç düğmesi
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TSizes.defaultSpace, TSizes.sm, TSizes.defaultSpace, TSizes.spaceBtwItems / 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: storeController.searchTextController,
                      onChanged: storeController.search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                        hintText: TTexts.searchInStore.tr,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md),
                        // Sorgu varken temizleme (X) düğmesi çıkar.
                        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
                        suffixIcon: Obx(() {
                          if (storeController.searchQuery.value.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Iconsax.close_circle, size: 18),
                            onPressed: storeController.clearSearch,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems / 2),
                  const TStoreFilterBar(),
                ],
              ),
            ),

            /// -- Kategori sekmeleri (kök kategoriler, çoklu seçim)
            _CategoryTabs(storeController: storeController, categoryController: categoryController),
            const Divider(height: 1),

            /// -- Ürünler
            Expanded(
              child: Obx(() {
                if (storeController.isLoading.value) {
                  return const SingleChildScrollView(
                    padding: EdgeInsets.all(TSizes.defaultSpace),
                    child: TVerticalProductShimmer(),
                  );
                }

                // Eşleşen tüm küme; başlık toplamı, ızgara ilk [visibleCount]
                // tanesini gösterir, "daha fazla" 48 ürün daha açar.
                final all = storeController.matchedProducts;

                // 🔴 Yüklenemedi ≠ sonuç yok. Ağ kesikken burada
                // "Veri Bulunamadı!" yazıyordu; müşteri kataloğun boş
                // olduğunu sanıyordu. Yeniden deneme yolu da veriliyor.
                if (all.isEmpty && storeController.loadFailed.value) {
                  return TEmptyState(
                    icon: Iconsax.wifi_square,
                    title: TTexts.noInternetAccess.tr,
                    message: TTexts.checkInternetConnection.tr,
                    actionText: TTexts.tryAgain.tr,
                    // Kategoriler de aynı kesintide boş kalmış olabilir
                    // (çipler hiç çizilmiyordu); ikisi birden tazelenir.
                    onAction: () {
                      categoryController.fetchCategories();
                      storeController.loadScope();
                    },
                  );
                }

                if (all.isEmpty) {
                  return Center(
                    child: Text(TTexts.noDataFound.tr, style: Theme.of(context).textTheme.bodyMedium),
                  );
                }

                final visible = storeController.visibleCount.value;
                final shown = visible >= all.length ? all : all.sublist(0, visible);
                final hasMore = visible < all.length;

                // Tembel ızgara: yalnız görünen kartlar kurulur, ekran dışına
                // çıkanlar geri dönüştürülür — bellek sabit kalır.
                return CustomScrollView(
                  controller: storeController.scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.defaultSpace,
                          TSizes.defaultSpace, TSizes.spaceBtwItems),
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

                    /// -- Daha fazla (yüklü listenin sonraki 48'ini açar).
                    /// SliverFillRemaining, ürünler ekranı doldurmadığında
                    /// düğmeyi dibe yaslar; doldurduğunda ızgaranın peşine takar.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TSizes.defaultSpace,
                          TSizes.spaceBtwSections,
                          TSizes.defaultSpace,
                          TSizes.defaultSpace + MediaQuery.of(context).viewPadding.bottom,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: hasMore
                              ? SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: storeController.showMore,
                                    icon: const Icon(Iconsax.arrow_down_1, size: 16),
                                    label: Text(TTexts.loadMore.tr),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kök kategorilerin yatay sekme şeridi.
///
/// Çoklu seçim: birden fazla sekme aynı anda seçilebilir ve sonuç ikisinin
/// **toplamıdır** (VEYA). Alt ağaç `StoreController` tarafında ekleniyor.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.storeController, required this.categoryController});

  final StoreController storeController;
  final CategoryController categoryController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final roots = categoryController.rootCategories;
      if (categoryController.isLoading.value || roots.isEmpty) return const SizedBox.shrink();

      final selected = storeController.selectedCategoryIds;
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          itemCount: roots.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: TSizes.sm),
          itemBuilder: (_, index) {
            if (index == 0) {
              // 🔴 `clearFilter` bir PARÇA: on sözlükte de "… selected ·
              // Clear" biçiminde yazılı ve önüne SAYI gelmesi gerekiyor.
              // Tek başına basıldığında ekranda "selected · Clear" diye
              // anlamsız bir çip çıkıyordu. Süzgeç boşken çip zaten "tümü"
              // rolünde (seçili çizilir ve dokununca süzgeci temizler).
              return _Tab(
                label: selected.isEmpty
                    ? TTexts.allCategories.tr
                    : '${selected.length} ${TTexts.clearFilter.tr}',
                selected: selected.isEmpty,
                onTap: storeController.clearCategoryFilter,
              );
            }
            final category = roots[index - 1];
            return _Tab(
              label: category.name,
              selected: selected.contains(category.id),
              onTap: () => storeController.toggleCategory(category.id),
            );
          },
        ),
      );
    });
  }
}

/// Tek kategori sekmesi (hap görünümlü çip).
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
        decoration: BoxDecoration(
          color: selected ? (dark ? TColors.darkAccent : TColors.accent) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.apply(
                color: selected ? TColors.primary : (dark ? TColors.light : TColors.darkerGrey),
              ),
        ),
      ),
    );
  }
}
