/// Ana sayfa.
///
/// TASARIM.md §7'deki düzen:
///   1. beyaz sade başlık
///   2. slider (3 sahne, otomatik, dokununca durur)
///   3. arama kutusu — slider'ın ALTINDA, başlık kabının içinde
///   4. **yeni gelenler** — 5 ürün + "daha fazla"
///   5. tanıtım afişi slider'ı (referans mobilin bölümü, korundu)
///   6. **öne çıkanlar** — 5 ürün + "daha fazla"
///   7. **ana kategoriler** (Fores, Foral, Stark…) — her biri 5 ürün +
///      "daha fazla"; düğme mağazayı o kategori süzgeciyle açar.
///
/// 🔴 Bloklar IZGARA değil RAF: web'de de öyle (`pages/home.js`). Her bloğu
/// alt alta ızgara dizmek sayfayı metrelerce uzatıyor ve kullanıcı ikinci
/// bloğu hiç görmüyor.
///
/// 🔴 Ürünü olmayan kategori **hiç çizilmez** — boş blok kullanıcıya "burada
/// bir şey yok" demekten başka bir işe yaramıyor.
///
/// Web'de kaldırılanlar burada da yok: 4'lü kargo şeridi, kutulu kategori
/// ızgarası, bülten bloğu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../data/repositories/product/api_products_repository.dart';
import '../../../../home_menu.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/categories_controller.dart';
import '../../controllers/product/product_controller.dart';
import '../../controllers/store_controller.dart';
import '../../models/product_model.dart';
import '../all_products/all_products.dart';
import 'widgets/header_search_container.dart';
import 'widgets/home_appbar.dart';
import 'widgets/home_slider.dart';
import 'widgets/promo_banner_slider.dart';

/// Her blokta gösterilecek ürün sayısı; gerisi "daha fazla"nın ardında.
const int _rowSize = 5;

/// En çok kaç ana kategori bloğu çizilir.
const int _categoryRows = 4;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.put(ProductController());
    final categoryController = Get.put(CategoryController());

    return Scaffold(
      // Yan menü kabuğun (`HomeMenu`) Scaffold'unda; buradan çizilseydi yüzen
      // alt gezinme çubuğu menünün üstünde kalırdı.
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- 1-3. Başlık + slider + arama
            TPrimaryHeaderContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const THomeAppBar(),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),

                  /// -- 2. Slider (arama kutusunun ÜSTÜNDE)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                    child: THomeSlider(),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// -- 3. Arama
                  TSearchContainer(text: TTexts.searchInStore.tr),
                  const SizedBox(height: TSizes.spaceBtwItems),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -- 4. Yeni gelenler
                  Obx(() {
                    if (productController.isLoading.value) return const _RowShimmer();
                    return _ProductRow(
                      title: TTexts.newArrivals.tr,
                      products: productController.newArrivalProducts.take(_rowSize).toList(),
                      onMore: () => Get.to(
                        () => AllProducts(
                          title: TTexts.newArrivals.tr,
                          futureMethod: ApiProductRepository.instance
                              .fetchAllItems()
                              .then((p) => p.where((x) => x.isNewArrival).toList()),
                        ),
                      ),
                    );
                  }),

                  /// -- 5. Tanıtım afişi
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                    child: TPromoBannerSlider(),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- 6. Öne çıkanlar
                  Obx(() {
                    if (productController.isLoading.value) return const _RowShimmer();
                    return _ProductRow(
                      title: TTexts.popularProducts.tr,
                      products: productController.featuredProducts.take(_rowSize).toList(),
                      onMore: () => Get.to(
                        () => AllProducts(
                          title: TTexts.popularProducts.tr,
                          futureMethod: ApiProductRepository.instance
                              .fetchAllItems()
                              .then((p) => p.where((x) => x.isFeatured).toList()),
                        ),
                      ),
                    );
                  }),

                  /// -- 7. Ana kategoriler
                  Obx(() {
                    if (productController.isLoading.value || categoryController.isLoading.value) {
                      return const _RowShimmer();
                    }
                    final rows = _mainCategoryRows(productController, categoryController);
                    if (rows.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rows
                          .map(
                            (row) => _ProductRow(
                              title: row.name,
                              products: row.products,
                              onMore: () => _openStoreWithCategory(row.id),
                            ),
                          )
                          .toList(),
                    );
                  }),

                  // Yüzen alt çubuk gövdenin ÜSTÜNDE duruyor (`HomeMenu`,
                  // `extendBody: true`): Scaffold çubuğun yüksekliğini
                  // gövdenin MediaQuery dolgusuna yazıyor, son blok o kadar
                  // pay alıyor ki çubuğun altında saklı kalmasın.
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + TSizes.defaultSpace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ana (ilk seviye) kategoriler ve her birinden [_rowSize] ürün.
  ///
  /// Kategorinin **alt ağacındaki** ürünler de sayılır (`descendantIds`);
  /// müşteri markayı arıyor, alt dalı mağaza ekranında seçiyor. Ürünü olmayan
  /// dal listeye hiç girmez, en dolu olanlar öne alınır.
  List<_CategoryRow> _mainCategoryRows(ProductController products, CategoryController categories) {
    final rows = <_CategoryRow>[];
    for (final root in categories.rootCategories) {
      final ids = categories.descendantIds(root.id).toSet();
      final matched = products.allProducts.where((p) => ids.contains(p.categoryId)).toList();
      if (matched.isEmpty) continue;
      rows.add(_CategoryRow(
        id: root.id,
        name: root.name,
        products: matched.take(_rowSize).toList(),
        total: matched.length,
      ));
    }
    rows.sort((a, b) => b.total.compareTo(a.total));
    return rows.take(_categoryRows).toList();
  }

  /// Mağaza sekmesini o kategorinin süzgeciyle açar.
  void _openStoreWithCategory(String categoryId) {
    final store = Get.isRegistered<StoreController>() ? StoreController.instance : Get.put(StoreController());
    store.openWithCategory(categoryId);
    AppScreenController.instance.selectedMenu.value = 1;
  }
}

/// Ana sayfadaki bir kategori bloğunun verisi.
class _CategoryRow {
  const _CategoryRow({required this.id, required this.name, required this.products, required this.total});

  final String id;
  final String name;
  final List<ProductModel> products;
  final int total;
}

/// Başlık + yatay ürün rafı + "daha fazla" düğmesi.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.title, required this.products, required this.onMore});

  final String title;
  final List<ProductModel> products;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    // Boş blok çizilmez.
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: TSectionHeading(title: title, onPressed: onMore),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        SizedBox(
          height: TSizes.productCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: TSizes.spaceBtwItems / 2),
            itemBuilder: (_, index) => SizedBox(
              width: 170,
              child: TProductCardVertical(product: products[index]),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onMore, child: Text(TTexts.moreProducts.tr)),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
      ],
    );
  }
}

/// Blok yüklenirken görünen iskelet.
class _RowShimmer extends StatelessWidget {
  const _RowShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, TSizes.spaceBtwSections),
      child: TVerticalProductShimmer(itemCount: 2),
    );
  }
}
