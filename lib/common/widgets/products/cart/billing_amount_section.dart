/// Ödeme ekranının tutar özeti: ara toplam, kargo, vergi, genel toplam.
///
/// Kargo ve vergi satırları yalnız `SettingsController` `isTaxShippingEnabled`
/// dediğinde çizilir — kapalıyken "0 ₸ kargo" yazmak müşteriye kargonun
/// ücretsiz olduğunu söylerdi, oysa tutar sipariş sonrası belirleniyor.
///
/// Kupon ve puan blokları **bilerek yorumda**: kupon ucu (`coupons`) sunucuda
/// 404 dönüyor ve uygulamada puan sistemi yok (referansta da böyle). Silme;
/// uç açıldığında buradan geri gelecekler.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/shop/controllers/product/checkout_controller.dart';
// Kupon arayüzü devre dışı (kuponlar uygulamada gösterilmiyor):
// import '../../../../features/shop/models/coupon_model.dart';
// import '../../../../routes/routes.dart';
// import '../../../../utils/constants/enums.dart';
// import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key, required this.subTotal});

  final double subTotal;

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;

    return Obx(
      () => Column(
        children: [
          /* -- Kupon kodu (devre dışı: kuponlar uygulamada gösterilmiyor)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(TTexts.couponCodeOrVouchers.tr, style: Theme.of(context).textTheme.bodyLarge),
              IconButton(
                onPressed: () => Get.toNamed(TRoutes.coupon),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              )
            ],
          ),
          */

          /* -- Puan (devre dışı: uygulamada puan sistemi yok)
          if (controller.settingsController.settings.value.isPointBaseEnabled) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Available Points: ${controller.userController.user.value.points}", style: Theme.of(context).textTheme.bodyMedium),
                controller.userController.user.value.points > 0 ?
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: controller.isUsingPoints.value,
                    activeTrackColor: TColors.darkerGrey,
                    onChanged: (value) {
                      controller.isUsingPoints.value = value;
                      if (value) controller.pointsDiscountAmount.value = 0.0;
                    },
                  ),
                ) : SizedBox.shrink(),
              ],
            ),
          ],
          */

          /// -- Ara toplam
          Row(
            children: [
              Expanded(child: Text(TTexts.subTotal.tr, style: Theme.of(context).textTheme.bodyMedium)),
              Text(TFormatter.formatCurrency(subTotal), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          /// -- Kargo
          if (controller.settingsController.settings.value.isTaxShippingEnabled) ...[
            Row(
              children: [
                Expanded(child: Text(TTexts.shippingFee.tr, style: Theme.of(context).textTheme.bodyMedium)),
                Obx(
                  () => Text(
                    controller.isShippingFree(subTotal)
                        ? TTexts.free.tr
                        : TFormatter.formatCurrency(controller.getShippingCost(subTotal)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /// -- Vergi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TTexts.taxFee.tr, style: Theme.of(context).textTheme.bodyMedium),
                Text(TFormatter.formatCurrency(controller.getTaxAmount(subTotal)),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /* -- Puan indirimi (devre dışı: uygulamada puan sistemi yok)
            if (controller.isUsingPoints.value) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Points Discount', style: Theme.of(context).textTheme.bodyMedium),
                  Obx(() => Text('-₸${controller.pointsDiscountAmount.value}', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ],
            */

            /* -- Kupon indirimi (devre dışı: kuponlar uygulamada gösterilmiyor)
            if (controller.couponController.coupon.value.id.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Coupon Discount', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsetsDirectional.zero),
                        onPressed: () => controller.couponController.coupon.value = CouponModel.empty(),
                        child: Text('Clear', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TColors.error)),
                      )
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        controller.couponController.coupon.value.discountType == DiscountType.percentage
                            ? "${controller.couponController.coupon.value.discountValue.toStringAsFixed(2)}%"
                            : "-₸${controller.couponController.coupon.value.discountValue.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            */
            const SizedBox(height: TSizes.spaceBtwItems),
          ],

          /// -- Genel toplam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(TTexts.orderTotal.tr, style: Theme.of(context).textTheme.titleMedium),
              Obx(() => Text(TFormatter.formatCurrency(controller.calculateGrandTotal(subTotal)),
                  style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
        ],
      ),
    );
  }
}
