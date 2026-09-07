/// Varyantlı ürünlerde **Model + Renk** seçici.
///
/// 🔴 Her varyant AYRI BİR ÜRÜNDÜR: seçim sepete bir "seçenek" eklemez,
/// ilgili ürünün detayını açar ([ProductVariantController.selectVariantProduct]).
/// Kuralların tamamı controller'da; burada yalnız çizim var.
///
/// TASARIM.md §6: seçili çip dolu indigo, seçilmeyen beyaz + ince çerçeve.
/// Stokta olmayan seçenek **sönük ve üstü çizili**.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/product_variant_controller.dart';
import '../../../models/product_variants_model.dart';

class TProductVariantSelector extends StatelessWidget {
  const TProductVariantSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductVariantController.instance;

    return Obx(() {
      // Tek üyeli grupta (ya da varyantı olmayan üründe) seçici çizilmez.
      if (!controller.hasVariants || !controller.hasSelectableVariants) {
        return const SizedBox.shrink();
      }

      final dark = THelperFunctions.isDarkMode(context);

      /// -- Liste modu: renksiz elle kurulmuş varyantlar. Renk yuvarlağı
      ///    anlamsız kalıyor; resim + isim + fiyat satırları gösteriliyor.
      if (controller.useVariantList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TSectionHeading(title: TTexts.variation.tr, showActionButton: false),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            ...controller.variants.value.variants.map((v) {
              final selected = controller.displayProduct.value.id == v.productId;
              final enabled = controller.isVariantOrderable(v);
              return Padding(
                padding: const EdgeInsets.only(bottom: TSizes.sm),
                child: _VariantListRow(
                  variant: v,
                  selected: selected,
                  enabled: enabled,
                  dark: dark,
                  onTap: enabled ? () => controller.selectVariantProduct(v.productId) : null,
                ),
              );
            }),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Model seçici
          if (controller.hasMultipleDesigns) ...[
            _SelectorLabel(
              label: TTexts.model.tr,
              value: controller.selectedDesign.value,
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              children: controller.variants.value.designOptions.map((option) {
                final selected = controller.selectedDesign.value == option.value;
                final available = controller.isDesignAvailable(option);
                return _ModelChip(
                  label: option.value,
                  selected: selected,
                  enabled: available,
                  dark: dark,
                  onTap: available ? () => controller.selectDesign(option.value) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],

          /// -- Renk seçici. Model seçiliyse yalnız **o modele ait** renkler
          ///    (`DesignColorMap`); yoksa kullanıcı var olmayan bir Model+Renk
          ///    birleşimini seçebilirdi. Tek yuvarlak göstermeye değmez.
          if (controller.hasMultipleColors) ...[
            _SelectorLabel(
              label: TTexts.color.tr,
              value: controller.selectedColor.value,
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              // Renk koduna göre tekilleştirilmiş: hepsi '9016' olan bir grup
              // tek yuvarlağa iner (web `renderColorButtons` ile aynı).
              children: controller.dedupedColorsForSelectedDesign.map((option) {
                final selected = controller.selectedColor.value == option.color;
                final available = controller.isColorAvailable(option);
                return _ColorSwatch(
                  label: option.color,
                  color: controller.colorFor(option.color),
                  selected: selected,
                  enabled: available,
                  onTap: available ? () => controller.selectColor(option.color) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        ],
      );
    });
  }
}

/// "Model: ALFA" biçimindeki seçici başlığı.
///
/// 🔴 Burada [TSectionHeading] KULLANILMAZ: içi `Expanded`lı bir `Row` ve
/// başka bir `Row`un çocuğu olunca sonsuz genişlik isteyip düzeni patlatıyor
/// (referanstaki hâli tam olarak böyle yazılmıştı).
class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        if (value.isNotEmpty) ...[
          const SizedBox(width: TSizes.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
            ),
          ),
        ],
      ],
    );
  }
}

/// Liste modunun tek satırı: solda kare görsel, ortada ad, sağda fiyat.
/// Stokta olmayan satır sönük ve adı üstü çizili.
class _VariantListRow extends StatelessWidget {
  const _VariantListRow({
    required this.variant,
    required this.selected,
    required this.enabled,
    required this.dark,
    required this.onTap,
  });

  final VariantItem variant;
  final bool selected;
  final bool enabled;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected
        ? TColors.primary
        : (dark ? TColors.darkBorder : TColors.borderSecondary);
    final Color bg = selected
        ? TColors.accent
        : (dark ? TColors.darkSurface : TColors.white);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: dark && selected ? TColors.darkSurface : bg,
            border: Border.all(color: border, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          ),
          child: Row(
            children: [
              TRoundedImage(
                imageUrl: variant.mainImage,
                isNetworkImage: variant.mainImage.isNotEmpty,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                borderRadius: TSizes.xs,
                memCacheWidth: 132,
                memCacheHeight: 132,
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  variant.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.apply(
                        decoration: enabled ? null : TextDecoration.lineThrough,
                      ),
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                variant.isPriceHidden
                    ? TTexts.priceOnRequest.tr
                    : '₸${variant.price.toStringAsFixed(2)}',
                style: variant.isPriceHidden
                    ? Theme.of(context).textTheme.bodySmall!
                    : Theme.of(context).textTheme.bodyMedium!.apply(fontWeightDelta: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model çipi.
class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? TColors.primary
        : (dark ? TColors.darkSurface : TColors.white);
    final Color border = selected
        ? TColors.primary
        : (dark ? TColors.darkBorder : TColors.borderPrimary);
    final Color textColor = selected
        ? TColors.white
        : (enabled ? (dark ? TColors.white : TColors.textPrimary) : TColors.darkGrey);

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.apply(
                  color: textColor,
                  fontWeightDelta: 1,
                  decoration: enabled ? null : TextDecoration.lineThrough,
                ),
          ),
        ),
      ),
    );
  }
}

/// Renk yuvarlağı. Stokta olmayan renkte çapraz çizgi (üstü çizili karşılığı).
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Çok açık renklerde (ör. 9016 beyaza yakın) beyaz onay işareti kaybolur.
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? TColors.white
        : TColors.black;

    return Tooltip(
      message: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: selected ? 38 : 34,
            height: selected ? 38 : 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? TColors.primary : TColors.borderPrimary,
                width: selected ? 3 : 1,
              ),
            ),
            child: !enabled
                ? Center(child: Icon(Icons.close, size: 16, color: onColor))
                : (selected ? Center(child: Icon(Icons.check, size: 18, color: onColor)) : null),
          ),
        ),
      ),
    );
  }
}
