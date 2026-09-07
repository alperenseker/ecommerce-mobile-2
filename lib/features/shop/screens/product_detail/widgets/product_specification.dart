/// Özellik tablosu.
///
/// 🔴 Yalnız **DOLU** alanlar çizilir; boş satır tabloyu kirletiyor ve
/// ürünün eksik girilmiş gibi görünmesine yol açıyor. Hiç veri yoksa bölüm
/// tamamen gizlenir. Web `pages/product.js` → `specsHtml` ile aynı liste ve
/// aynı sıra: ürün kodu · barkod · şirket · ölçü · ağırlıklar · en/boy/derinlik
/// · hacim · koli içi adet · KDV (+ stok durumu, referans mobilden).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/erp_source_helper.dart';
import '../../../controllers/product/product_controller.dart';
import '../../../models/product_model.dart';

class TProductSpecification extends StatelessWidget {
  const TProductSpecification({super.key, required this.product, this.showHeading = true});

  final ProductModel product;

  /// Sekmeli düzende başlık sekmenin kendisidir; ikinci kez yazılmaz.
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          TSectionHeading(title: TTexts.specifications.tr, showActionButton: false),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],
        ...rows,
      ],
    );
  }

  List<Widget> _buildRows() {
    final entries = <MapEntry<String, String>>[];

    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        entries.add(MapEntry(label, value));
      }
    }

    // Birimli sayı; değer boş ya da sıfırsa satır hiç eklenmez.
    String? measure(double? value, String unit) {
      if (value == null || value == 0) return null;
      return '${_fmt(value)} $unit';
    }

    add(TTexts.sku.tr, product.sku);
    add(TTexts.barcode.tr, product.barcode);
    // Şirket (1C kaynağı). Kod çözülemezse boş döner ve satır çizilmez.
    add(TTexts.company.tr, TErpSource.label(product.erpSource));
    add(TTexts.stockStatus.tr, ProductController.instance.getProductStockStatus(product));
    add(TTexts.size.tr, product.size);
    add(TTexts.unitWeight.tr, measure(product.weight, 'kg'));
    add(TTexts.weightNet.tr, measure(product.weightNet, 'kg'));
    add(TTexts.weightGross.tr, measure(product.weightGross, 'kg'));
    add(TTexts.width.tr, measure(product.width, 'mm'));
    add(TTexts.height.tr, measure(product.height, 'mm'));
    add(TTexts.depth.tr, measure(product.depth, 'mm'));
    add(TTexts.volume.tr, (product.volume == null || product.volume == 0) ? null : _fmt(product.volume!));
    add(TTexts.unitsPerBox.tr,
        (product.unitsPerBox == null || product.unitsPerBox == 0) ? null : product.unitsPerBox.toString());
    // Sunucu KDV'yi metin gönderiyor ("18"); "0" da anlamlı olmadığı için elenir.
    final vat = (product.vatRate ?? '').trim();
    add(TTexts.vat.tr, (vat.isEmpty || vat == '0') ? null : '$vat%');

    return entries.map((e) => _SpecRow(label: e.key, value: e.value)).toList();
  }

  /// Sondaki ".0"ı atar: 100.0 -> "100", 0.315 -> "0.315".
  static String _fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
