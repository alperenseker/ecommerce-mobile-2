/// Mağaza ekranındaki tek "Süzgeç" girişi ve açtığı sayfa altı sayfası.
///
/// Sıralama · fiyat aralığı · (çoklu) kategori tek sayfada toplanır ve
/// "Uygula"ya basılınca birlikte uygulanır; böylece ızgara her dokunuşta
/// değil, bir kez yeniden çizilir.
///
/// 🔴 ÇOKLU KATEGORİ = **VEYA**: iki kategori seçiliyse sonuç ikisinin
/// TOPLAMIDIR. Bir üst kategoriyi seçmek **alt ağacını** da işaretler.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/categories_controller.dart';
import '../../../controllers/store_controller.dart';
import '../../../models/category_model.dart';

class TStoreFilterBar extends StatelessWidget {
  const TStoreFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StoreController.instance;

    return Obx(
      () => _FilterChip(
        label: TTexts.filter.tr,
        badgeCount: controller.activeFilterCount,
        highlighted: controller.activeFilterCount > 0,
        onTap: () => _openFilterSheet(context, controller),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, StoreController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
      ),
      builder: (_) => _StoreFilterSheet(controller: controller),
    );
  }
}

/// Birleşik süzgeç sayfası: sıralama · fiyat aralığı · kategoriler.
class _StoreFilterSheet extends StatefulWidget {
  const _StoreFilterSheet({required this.controller});

  final StoreController controller;

  @override
  State<_StoreFilterSheet> createState() => _StoreFilterSheetState();
}

class _StoreFilterSheetState extends State<_StoreFilterSheet> {
  late StoreSort _sort = widget.controller.sort.value;
  late final Set<String> _selectedCategories = {...widget.controller.selectedCategoryIds};
  late final TextEditingController _minCtrl =
      TextEditingController(text: widget.controller.minPrice.value?.toStringAsFixed(0) ?? '');
  late final TextEditingController _maxCtrl =
      TextEditingController(text: widget.controller.maxPrice.value?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  /// [id] ve bütün alt dalları — bir üst kategoriyi seçmek alt ağacını da seçer.
  List<String> _withDescendants(String id) => CategoryController.instance.descendantIds(id);

  /// [id]'nin bütün atalarını seçimden çıkarır: bir alt kategori seçimden
  /// çıkınca "hepsi" anlamına gelen üst kategori işaretli kalmasın.
  void _removeAncestors(String id) {
    final all = CategoryController.instance.allCategories;
    var parentId = all.where((c) => c.id == id).map((c) => c.parentId).firstOrNull ?? '';
    while (parentId.isNotEmpty) {
      _selectedCategories.remove(parentId);
      parentId = all.where((c) => c.id == parentId).map((c) => c.parentId).firstOrNull ?? '';
    }
  }

  void _toggleCategory(String id) {
    final ids = _withDescendants(id);
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.removeAll(ids);
        _removeAncestors(id);
      } else {
        _selectedCategories.addAll(ids);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _sort = StoreSort.name;
      _selectedCategories.clear();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  void _apply() {
    widget.controller.sort.value = _sort;
    widget.controller.setSelectedCategories(_selectedCategories);
    widget.controller.setPriceRange(double.tryParse(_minCtrl.text), double.tryParse(_maxCtrl.text));
    Get.back();
  }

  /// Tek sıralama seçeneği satırı (radyo davranışı).
  Widget _sortRow(StoreSort option, bool dark) {
    final selected = _sort == option;
    return InkWell(
      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      onTap: () => setState(() => _sort = option),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.sm / 1.5),
        child: Row(
          children: [
            Icon(
              selected ? Iconsax.record_circle5 : Iconsax.record_circle,
              size: 22,
              color: selected ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderPrimary),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Text(
              option.labelKey.tr,
              style: Theme.of(context).textTheme.bodyLarge!.apply(
                    color: selected ? TColors.primary : null,
                    fontWeightDelta: selected ? 1 : 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kare onay kutusu. Elle çiziliyor: hazır ikon seçilmemiş hâlde yarım
  /// kırpılıyordu.
  Widget _tickBox(bool selected) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? TColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusXs),
        border: Border.all(
          color: selected ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderPrimary),
          width: 1.5,
        ),
      ),
      child: selected ? const Icon(Icons.check, size: 15, color: TColors.white) : null,
    );
  }

  /// Seçilebilir yaprak kategori satırı.
  Widget _leafTile(CategoryModel category, double indent) {
    final selected = _selectedCategories.contains(category.id);
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent, right: TSizes.sm),
      dense: true,
      onTap: () => _toggleCategory(category.id),
      title: Text(category.name),
      trailing: _tickBox(selected),
    );
  }

  /// Özyinelemeli kategori düğümü: üst düğüm hem açılır hem kendisi seçilebilir.
  /// Girinti derinlikle artar; **derinlik sınırı yoktur** (Foral 4 seviye).
  Widget _categoryNode(CategoryModel category, int depth) {
    final children = CategoryController.instance.getChildren(category.id);
    final indent = depth * TSizes.lg;

    if (children.isEmpty) return _leafTile(category, indent);

    final selected = _selectedCategories.contains(category.id);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: indent, right: TSizes.sm),
        childrenPadding: EdgeInsets.zero,
        // Onay kutusuna dokunmak kategoriyi seçer; satırın geri kalanı
        // alt dalları açıp kapatır.
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleCategory(category.id),
          child: _tickBox(selected),
        ),
        title: Text(
          category.name,
          style: depth == 0
              ? Theme.of(context).textTheme.titleSmall!.apply(fontWeightDelta: 1)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        children: children.map((child) => _categoryNode(child, depth + 1)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.md, TSizes.sm, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(TTexts.filter.tr, style: Theme.of(context).textTheme.titleLarge),
                  TextButton(onPressed: _clearAll, child: Text(TTexts.clearAll.tr)),
                ],
              ),
            ),
            const Divider(height: 1),

            // -- Gövde: sıralama · fiyat · kategoriler
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, TSizes.spaceBtwItems, TSizes.defaultSpace, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Sıralama
                    Text(TTexts.sortBy.tr, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    ...StoreSort.values.map((option) => _sortRow(option, dark)),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Fiyat aralığı
                    Text(TTexts.priceRange.tr, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: TTexts.lowestPrice.tr,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md),
                            ),
                          ),
                        ),
                        const SizedBox(width: TSizes.spaceBtwItems),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: TTexts.highestPrice.tr,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Kategoriler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(TTexts.categories.tr, style: Theme.of(context).textTheme.titleMedium),
                        if (_selectedCategories.isNotEmpty)
                          Text('${_selectedCategories.length}',
                              style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.primary)),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    if (CategoryController.instance.rootCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                        child: Center(child: Text(TTexts.noDataFound.tr)),
                      )
                    else
                      ...CategoryController.instance.rootCategories.map((c) => _categoryNode(c, 0)),
                    const SizedBox(height: TSizes.spaceBtwItems),
                  ],
                ),
              ),
            ),

            // -- Uygula (sabit)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _apply, child: Text(TTexts.apply.tr)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etkin süzgeç sayısını rozetle gösteren tek çip.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final int badgeCount;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final borderColor = highlighted ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderPrimary);
    final fgColor = highlighted ? TColors.primary : (dark ? TColors.light : TColors.darkerGrey);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: TSizes.inputFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
        decoration: BoxDecoration(
          color: highlighted ? (dark ? TColors.darkAccent : TColors.accent) : Colors.transparent,
          borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.setting_4, size: 18, color: fgColor),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.apply(color: fgColor, fontWeightDelta: 1),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Container(
                padding: const EdgeInsets.all(TSizes.xs),
                decoration: const BoxDecoration(color: TColors.primary, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TColors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
