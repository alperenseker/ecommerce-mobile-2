/// Sipariş özeti: numara, şirket, alışveriş numarası, tarih, tutar, durum
/// **ve kalemler**.
///
/// 🔴 Durum HAM değerdir (`OrderModel.statusKey`): `t_utils`'in `OrderStatus`
/// enum'unda `confirmed` yok ve backend ödeme sonrası siparişi o duruma
/// geçiriyor; enum'a çevrilirse ödenmiş sipariş "beklemede" görünürdü.
///
/// 🔴 Kardeş siparişlerin numarası/tutarı GÖSTERİLMEZ: müşteri onları zaten
/// "Siparişlerim"de ve grup görünümünde görüyor; burada kaçta kaçı olduğu
/// yeterli (izolasyon matrisi).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_utils/utils/constants/enums.dart';

import '../../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/formatters/formatter.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../controllers/review_controller.dart';
import '../../../../models/cart_item_model.dart';
import '../../../../models/order_model.dart';
import '../../../review/review_screen.dart';
import '../../widgets/order_badges.dart';
import 'heading_with_icon.dart';

class OrderStatusWidget extends StatelessWidget {
  const OrderStatusWidget({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TRoundedContainer(
          showBorder: true,
          radius: TSizes.cardRadiusMd,
          backgroundColor: dark ? TColors.darkContainer : TColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THeadingWithIcon(title: TTexts.orderSummary.tr, icon: Iconsax.shopping_bag),
              const SizedBox(height: TSizes.spaceBtwItems),

              _row(context, TTexts.orderId.tr, order.displayId),

              /// Siparişin şirketi. Şirketi olmayan (eski) siparişte satır
              /// hiç çizilmez; ad uydurulmaz.
              if (order.hasCompany) _row(context, TTexts.company.tr, order.companyLabel),

              /// Bu siparişin ait olduğu alışveriş numarası.
              if (order.groupNumber.isNotEmpty) ...[
                _row(context, TTexts.purchaseNumber.tr, order.groupNumber),
                if (order.isPartOfSplitPurchase)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      TTexts.partOfPurchase.trParams({'count': '${order.groupOrderCount}'}),
                      style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
                    ),
                  ),
              ],

              _row(context, TTexts.placeOn.tr, order.formattedOrderDate),
              _row(context, TTexts.grandTotal.tr, TFormatter.formatCurrency(order.totalAmount)),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TTexts.orderStatus.tr,
                      style: theme.textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                    ),
                    TStatusBadge.order(status: order.statusKey),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// -- Kalemler
        TRoundedContainer(
          showBorder: true,
          radius: TSizes.cardRadiusMd,
          backgroundColor: dark ? TColors.darkContainer : TColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              THeadingWithIcon(title: TTexts.orderItems.tr, icon: Iconsax.shopping_cart),
              const SizedBox(height: TSizes.spaceBtwItems),
              if (order.products.isEmpty)
                Text(
                  TTexts.orderNoItems.tr,
                  style: theme.textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.products.length,
                  separatorBuilder: (_, _) => const Divider(height: TSizes.spaceBtwItems * 2),
                  itemBuilder: (_, index) => _OrderItemTile(item: order.products[index], order: order),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek kalem: görsel · ad · birim fiyat × adet · satır tutarı
/// (+ teslim edilmiş siparişte değerlendirme düğmesi).
class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item, required this.order});

  final CartItemModel item;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = item.image ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: TColors.lightContainer,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          ),
          clipBehavior: Clip.antiAlias,
          child: image.isEmpty
              ? const Icon(Iconsax.receipt_item, size: TSizes.iconMd, color: TColors.darkGrey)
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Iconsax.receipt_item, size: TSizes.iconMd, color: TColors.darkGrey),
                ),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(width: TSizes.sm),
                  Text(
                    TFormatter.formatCurrency(item.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.xs / 2),
              Text(
                '${TTexts.unitPrice.tr}: ${TFormatter.formatCurrency(item.unitPrice)}  ·  '
                '${TTexts.quantity.tr}: ${item.quantity}',
                style: theme.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
              ),

              /// Değerlendirme yalnız TESLİM EDİLMİŞ siparişte açılır; zaten
              /// yorum yazılmışsa düğme yerine yıldızlar ve "düzenle" görünür.
              if (order.orderStatus == OrderStatus.delivered) _ReviewAction(item: item),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      // Controller sipariş detayı ekranında kuruluyor; kayıtlı değilse
      // değerlendirme bölümü hiç çizilmez (ekran bir düğme yüzünden patlamaz).
      if (!Get.isRegistered<ReviewController>()) return const SizedBox.shrink();
      final reviewController = ReviewController.instance;

      if (!reviewController.hasReviewed(item.productId)) {
        return Padding(
          padding: const EdgeInsets.only(top: TSizes.sm),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Get.to(() => ProductReviewsScreen(product: item)),
            icon: const Icon(Iconsax.star, size: TSizes.iconXs),
            label: Text(TTexts.reviewProduct.tr),
          ),
        );
      }

      final existing = reviewController.userReviewFor(item.productId);
      final savedRating = existing?.rating.round() ?? 0;

      return Padding(
        padding: const EdgeInsets.only(top: TSizes.sm),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TSizes.sm,
          runSpacing: TSizes.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.tick_circle, size: TSizes.iconXs, color: TColors.success),
                const SizedBox(width: TSizes.xs),
                Text(
                  TTexts.reviewed.tr,
                  style: theme.textTheme.labelLarge?.copyWith(color: TColors.success),
                ),
              ],
            ),
            if (savedRating > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < savedRating ? Icons.star : Icons.star_border,
                    size: TSizes.iconXs,
                    color: TColors.star,
                  ),
                ),
              ),
            if (existing != null && existing.id.isNotEmpty)
              InkWell(
                onTap: () => Get.to(() => ProductReviewsScreen(product: item, existingReview: existing)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.edit_2, size: TSizes.iconXs, color: TColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      TTexts.edit.tr,
                      style: theme.textTheme.labelLarge?.copyWith(color: TColors.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
