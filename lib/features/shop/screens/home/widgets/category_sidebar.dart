/// Kategori yan menüsü (drawer).
///
/// 🔴 Ağaç **değişken derinliktedir** ve özyinelemeli çizilir: canlıda Foral
/// 4 seviye (Foral → Фурнитура → ДВЕРНЫЕ/ОКОННЫЕ → 11 yaprak), Fores 2,
/// Stark Alpha 1. Sabit iki seviye basmak Foral'ın yapraklarını gizler.
///
/// TASARIM.md §6: beyaz zemin, gölgesiz; başlık koyu turuncu yerine sade
/// beyaz + 1px çizgi.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/categories_controller.dart';
import '../../../models/category_model.dart';
import '../../all_products/all_products.dart';

class TCategorySidebar extends StatelessWidget {
  const TCategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoryController());
    final dark = THelperFunctions.isDarkMode(context);

    return Drawer(
      backgroundColor: dark ? TColors.darkBackground : TColors.white,
      child: Column(
        children: [
          const _SidebarHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final roots = controller.rootCategories;
              if (roots.isEmpty) {
                return Center(child: Text(TTexts.noDataFound.tr));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                itemCount: roots.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: dark ? TColors.darkBorder : TColors.borderSecondary,
                ),
                itemBuilder: (_, index) => _CategoryNode(category: roots[index], depth: 0),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Menünün başlığı — burasının kategori gezgini olduğu belli olsun diye.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.md, TSizes.sm, TSizes.md),
        decoration: BoxDecoration(
          color: dark ? TColors.darkSurface : TColors.white,
          border: Border(
            bottom: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: dark ? TColors.darkAccent : TColors.accent,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
              ),
              child: const Icon(Iconsax.category, color: TColors.primary, size: TSizes.iconMd - 4),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Text(TTexts.categories.tr, style: Theme.of(context).textTheme.headlineSmall),
            ),
            IconButton(
              icon: const Icon(Iconsax.close_circle, color: TColors.darkGrey),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ağacın tek düğümü. Çocuğu varsa açılır liste, yoksa dokunulabilir yaprak.
/// Kendini özyinelemeli çağırır — derinlik sınırı yoktur.
class _CategoryNode extends StatelessWidget {
  const _CategoryNode({required this.category, required this.depth});

  final CategoryModel category;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    final children = controller.getChildren(category.id);
    final dark = THelperFunctions.isDarkMode(context);
    final indent = TSizes.defaultSpace + (depth * TSizes.lg);

    if (children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: indent, right: TSizes.defaultSpace),
        dense: depth > 0,
        leading: Icon(Iconsax.minus, size: 14, color: TColors.darkGrey),
        title: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
        onTap: () {
          Navigator.of(context).pop();
          Get.to(
            () => AllProducts(
              title: category.name,
              futureMethod: controller.getCategoryProducts(categoryId: category.id),
            ),
          );
        },
      );
    }

    final isTopLevel = depth == 0;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: indent, right: TSizes.sm),
        leading: isTopLevel
            ? Container(
                padding: const EdgeInsets.all(TSizes.xs),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkAccent : TColors.accent,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: const Icon(Iconsax.category_2, color: TColors.primary, size: 20),
              )
            : Icon(Iconsax.folder_2, size: 18, color: TColors.darkGrey),
        title: Text(
          category.name,
          style: isTopLevel
              ? Theme.of(context).textTheme.titleMedium!.apply(fontWeightDelta: 1)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        childrenPadding: EdgeInsets.zero,
        children: children.map((child) => _CategoryNode(category: child, depth: depth + 1)).toList(),
      ),
    );
  }
}
