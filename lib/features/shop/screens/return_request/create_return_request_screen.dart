/// İade / değişim talebi oluşturma.
///
/// Talep **tek bir siparişten** açılır: iade edilen mal bir şirkete geri
/// gidiyor ve sipariş zaten şirket başına bölünmüş durumda (bir alışverişte
/// iki şirket varsa müşteri iki ayrı talep açar).
///
/// ⚠️ **Sunucuda iade ucu yok** (`ApiReturnRepository` yer tutucu): "gönder"
/// düğmesi bugün "bu özellik henüz açık değil" mesajı veriyor. Form, kapılar
/// ve alan adları uç açıldığında çalışacak biçimde referansla birebir yazıldı.
///
/// ⚠️ **Görsel seçici yok**: ne referansta ne bu projede `image_picker` var ve
/// KURALLAR §6 yeni paket eklemeyi yasaklıyor. Kanıt görselleri **bağlantı
/// olarak** ekleniyor (`ReturnRequest.photoUrls`).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/return_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import 'widgets/return_status_badge.dart';

class CreateReturnRequestScreen extends StatefulWidget {
  const CreateReturnRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<CreateReturnRequestScreen> createState() => _CreateReturnRequestScreenState();
}

class _CreateReturnRequestScreenState extends State<CreateReturnRequestScreen> {
  late final ReturnController controller;
  final _descriptionController = TextEditingController();
  final _photoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReturnController());
    // Önceki bir talepten kalan seçimler bu siparişe taşınmasın.
    controller.resetForm();
    controller.initializeReturnRequest(widget.order);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showActions: false,
        showSkipButton: false,
        showBackArrow: true,
        title: Text(TTexts.returnRequest.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _orderSummary(context),
            const SizedBox(height: TSizes.spaceBtwItems),
            _returnTypeSection(context),
            const SizedBox(height: TSizes.spaceBtwItems),
            _itemSelectionSection(context),
            const SizedBox(height: TSizes.spaceBtwItems),
            _reasonSection(context),
            const SizedBox(height: TSizes.spaceBtwItems),
            _photoSection(context),
            const SizedBox(height: TSizes.spaceBtwSections),
            ElevatedButton(
              onPressed: controller.submitReturnRequest,
              child: Text(TTexts.submitReturnRequest.tr),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bölümler ────────────────────────────────────────────────────────────

  Widget _card(BuildContext context, {required Widget child}) {
    final dark = THelperFunctions.isDarkMode(context);
    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: child,
    );
  }

  Widget _orderSummary(BuildContext context) {
    return _card(
      context,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${TTexts.orderNumber.tr}: ${widget.order.displayId}',
                    style: Theme.of(context).textTheme.titleMedium),
                // Şirketi olmayan (eski) siparişte satır çizilmez.
                if (widget.order.hasCompany)
                  Text(
                    widget.order.companyLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showReturnPolicy(context),
            icon: const Icon(Iconsax.info_circle, size: TSizes.iconXs),
            label: Text(TTexts.returnPolicy.tr),
          ),
        ],
      ),
    );
  }

  Widget _returnTypeSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TTexts.returnType.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          Obx(() {
            // Referanstaki iki seçenek korunuyor: para iadesi ve değişim.
            const types = [ReturnType.returnForRefund, ReturnType.exchange];
            return Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              children: types.map((type) {
                final selected = controller.selectedReturnType.value == type;
                return ChoiceChip(
                  label: Text(returnTypeLabel(type)),
                  selected: selected,
                  onSelected: (_) => controller.selectedReturnType.value = type,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _itemSelectionSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TTexts.selectItemsToReturn.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.xs),
          Text(
            TTexts.selectItemsToReturnText.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.sm),
          if (widget.order.products.isEmpty)
            Text(
              TTexts.orderNoItems.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            )
          else
            Obx(() => Column(
                  children: widget.order.products.map((item) => _itemCheckbox(context, item)).toList(),
                )),
        ],
      ),
    );
  }

  Widget _itemCheckbox(BuildContext context, CartItemModel item) {
    final selected = controller.selectedItems.any((s) => s.productId == item.productId);
    final image = item.image ?? '';

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: selected,
      onChanged: (_) => controller.toggleItemSelection(item),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.quantity} × ${TFormatter.formatCurrency(item.unitPrice)}'),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: TColors.lightContainer,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        ),
        clipBehavior: Clip.antiAlias,
        // 🔴 Referans doğrudan `NetworkImage(item.image!)` çağırıyordu;
        // görseli olmayan kalemde ekran çöküyordu.
        child: image.isEmpty
            ? const Icon(Iconsax.image, size: TSizes.iconSm, color: TColors.darkGrey)
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Iconsax.image, size: TSizes.iconSm, color: TColors.darkGrey),
              ),
      ),
    );
  }

  Widget _reasonSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TTexts.reasonForReturn.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          Obx(() => DropdownButtonFormField<ReturnReason>(
                initialValue: controller.selectedReason.value,
                isExpanded: true,
                decoration: InputDecoration(labelText: TTexts.selectReason.tr),
                items: ReturnReason.values
                    .map((reason) => DropdownMenuItem(value: reason, child: Text(returnReasonLabel(reason))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectedReason.value = value;
                },
              )),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: TTexts.additionalDetails.tr,
              hintText: TTexts.additionalDetailsHint.tr,
            ),
            onChanged: (value) => controller.customDescription.value = value,
          ),
        ],
      ),
    );
  }

  /// Kanıt görselleri — bağlantı olarak eklenir (paket kısıtı; bkz. dosya başı).
  Widget _photoSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TTexts.returnPhotos.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.xs),
          Text(
            TTexts.returnPhotosHint.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _photoUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(hintText: TTexts.photoUrlHint.tr),
                ),
              ),
              const SizedBox(width: TSizes.sm),
              OutlinedButton(
                onPressed: () {
                  controller.addPhotoUrl(_photoUrlController.text);
                  _photoUrlController.clear();
                },
                child: Text(TTexts.addPhoto.tr),
              ),
            ],
          ),
          Obx(() {
            if (controller.photoUrls.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: TSizes.sm),
              child: Wrap(
                spacing: TSizes.sm,
                runSpacing: TSizes.sm,
                children: controller.photoUrls
                    .map((url) => InputChip(
                          label: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () => controller.removePhotoUrl(url),
                        ))
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showReturnPolicy(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(TTexts.returnPolicy.tr),
        content: SingleChildScrollView(child: Text(TTexts.returnPolicyText.tr)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(TTexts.close.tr)),
        ],
      ),
    );
  }
}
