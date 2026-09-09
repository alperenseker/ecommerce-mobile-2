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

  /// Levhanın üst köşe yarıçapı — kart yarıçapından belirgin biçimde geniş;
  /// alttan gelen katman böylece sayfadan ayrışıyor.
  static const double _sheetRadius = 24.0;

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
      // Levha çentiğin/durum çubuğunun altına girmesin.
      useSafeArea: true,
      barrierColor: TColors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
      ),
      // Varsayılan açılış sert ve kısa (250ms, lineer'e yakın); levha
      // "zıplayarak" geliyordu. Girişte yavaşlayarak duran daha uzun bir
      // hareket, kapanışta daha kısa olanı — el altından çıkıp geri giden
      // bir kâğıt gibi.
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        reverseDuration: const Duration(milliseconds: 220),
        reverseCurve: Curves.easeInCubic,
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

  /// Bölüm başlığı — bütün bölümlerde aynı ağırlık ve aynı üst boşluk.
  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (trailing != null)
            Text(
              trailing,
              style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.primary),
            ),
        ],
      ),
    );
  }

  /// Sıralama seçenekleri.
  ///
  /// 🔴 Radyo listesi DEĞİL çip ızgarası: altı seçenek alt alta 240px yer
  /// kaplıyordu ve levhanın yarısını yiyip fiyatla kategorileri kaydırmanın
  /// arkasına itiyordu. Çipler iki-üç satıra sığıyor, seçili olan mağaza
  /// ekranındaki kategori çipleriyle aynı dili konuşuyor.
  Widget _sortChips() {
    return Wrap(
      spacing: TSizes.sm,
      runSpacing: TSizes.sm,
      children: StoreSort.values
          .map(
            (option) => _ChoiceChip(
              label: option.labelKey.tr,
              selected: _sort == option,
              onTap: () => setState(() => _sort = option),
            ),
          )
          .toList(),
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
    // Kök satırlar da kutunun çerçevesine yapışmasın diye taban boşluk var.
    final indent = TSizes.md + depth * TSizes.lg;

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

  /// Fiyat kutusu — mağazadaki hap arama kutusuyla aynı köşe dili.
  Widget _priceField(TextEditingController controller, String label, bool dark) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TSizes.inputFieldHeight / 2),
      borderSide: BorderSide(color: dark ? TColors.darkBorder : TColors.borderPrimary),
    );
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: label,
        prefixText: '₸ ',
        prefixStyle: Theme.of(context).textTheme.bodyLarge!.apply(color: TColors.darkGrey),
        filled: true,
        fillColor: dark ? TColors.dark : TColors.lightGrey,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + TSizes.xs),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: TColors.primary, width: 1.5),
        ),
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
            //
            // Altındaki çizgi kalktı: tutamaç zaten levhanın başladığı yeri
            // söylüyor, çizgi başlığı ayrı bir çubuk gibi gösteriyordu.
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.sm, TSizes.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(TTexts.filter.tr, style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(TTexts.clearAll.tr),
                  ),
                ],
              ),
            ),

            // -- Gövde: sıralama · fiyat · kategoriler
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Sıralama
                    _sectionTitle(TTexts.sortBy.tr),
                    _sortChips(),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Fiyat aralığı
                    _sectionTitle(TTexts.priceRange.tr),
                    Row(
                      children: [
                        Expanded(child: _priceField(_minCtrl, TTexts.lowestPrice.tr, dark)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                          child: Container(
                            width: TSizes.md,
                            height: 1.5,
                            color: dark ? TColors.darkBorder : TColors.borderPrimary,
                          ),
                        ),
                        Expanded(child: _priceField(_maxCtrl, TTexts.highestPrice.tr, dark)),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Kategoriler
                    _sectionTitle(
                      TTexts.categories.tr,
                      trailing: _selectedCategories.isEmpty ? null : '${_selectedCategories.length}',
                    ),
                    if (CategoryController.instance.rootCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                        child: Center(child: Text(TTexts.noDataFound.tr)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                          border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
                        ),
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
                        child: Column(
                          children: CategoryController.instance.rootCategories
                              .map((c) => _categoryNode(c, 0))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                  ],
                ),
              ),
            ),

            // -- Uygula (sabit)
            //
            // Üstündeki çizgi, kaydırılan gövdenin düğmenin altından geçtiğini
            // belli ediyor.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: dark ? TColors.darkBorder : TColors.borderSecondary),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _apply, child: Text(TTexts.apply.tr)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Süzgeç levhasındaki tek seçim çipi (sıralama seçenekleri).
///
/// Mağaza şeridindeki kategori çipiyle aynı dil: seçiliyken indigo çerçeve,
/// yumuşak indigo zemin ve indigo yazı.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Material(
      color: selected
          ? (dark ? TColors.darkAccent : TColors.accent)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(
          color: selected ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderSecondary),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 15, color: TColors.primary),
                const SizedBox(width: TSizes.xs + 2),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge!.apply(
                  color: selected ? TColors.primary : (dark ? TColors.light : TColors.darkerGrey),
                  fontWeightDelta: selected ? 1 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etkin süzgeç sayısını rozetle gösteren süzgeç düğmesi.
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

  /// Yanındaki hap arama kutusuyla aynı ölçü: kare değil, aynı yükseklikte
  /// yuvarlak bir düğme; ikisi tek şerit gibi okunsun.
  ///
  /// 🔴 Etiket kaldırıldı: hap arama kutusunun yanında "Süzgeç" yazısı
  /// aramaya kalan genişliği yiyordu. Ne olduğunu ikon + rozet anlatıyor,
  /// adı da uzun basışta ipucu olarak çıkıyor.
  static const double _size = 52.0;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final borderColor = highlighted ? TColors.primary : (dark ? TColors.darkBorder : TColors.borderPrimary);
    final fgColor = highlighted ? TColors.primary : (dark ? TColors.light : TColors.darkerGrey);

    final icon = Icon(Iconsax.setting_4, size: 20, color: fgColor);

    return Tooltip(
      message: label,
      child: Material(
        color: highlighted
            ? (dark ? TColors.darkAccent : TColors.accent)
            : (dark ? TColors.darkSurface : TColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_size / 2),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Center(
              child: badgeCount > 0
                  ? Badge(
                      backgroundColor: TColors.primary,
                      textColor: TColors.white,
                      label: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      child: icon,
                    )
                  : icon,
            ),
          ),
        ),
      ),
    );
  }
}
