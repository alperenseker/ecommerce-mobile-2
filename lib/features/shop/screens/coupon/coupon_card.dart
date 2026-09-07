/// Kupon kartı: indirim · kod · açıklama · kalan kullanım · geçerlilik.
///
/// TASARIM.md §6: beyaz kart, 1px çizgi, gölgesiz; "kullan" birincil düğme.
/// Referanstaki `TContainer` (t_utils paketi) yerine projenin kendi
/// [TRoundedContainer]'ı kullanılıyor — kart dili tek yerden geliyor.
///
/// Kullanım hakkı bitmiş ya da pasif kuponda düğme KAPALIDIR.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/coupon_controller.dart';
import '../../models/coupon_model.dart';

class CouponCard extends StatelessWidget {
  const CouponCard({super.key, required this.coupon});

  final CouponModel coupon;

  @override
  Widget build(BuildContext context) {
    final controller = CouponController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    final theme = Theme.of(context).textTheme;

    // `usageLimit` -1 ise sınırsız demektir (modelin varsayılanı).
    final bool hasUsageLeft = coupon.usageLimit < 0 || (coupon.usageLimit - coupon.usageCount) > 0;
    final bool canApply = hasUsageLeft && coupon.isActive;

    return TRoundedContainer(
      showBorder: true,
      borderColor: dark ? TColors.darkBorder : TColors.borderSecondary,
      backgroundColor: dark ? TColors.darkSurface : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Kod ve "kullan" düğmesi
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// İndirim
                    Text(
                      coupon.discountType == DiscountType.percentage
                          ? '−${coupon.discountValue.toStringAsFixed(0)}%'
                          : '−₸${coupon.discountValue.toStringAsFixed(2)}',
                      style: theme.labelLarge?.copyWith(color: TColors.deal, fontWeight: FontWeight.w700),
                    ),

                    /// Kod
                    Text(
                      coupon.code.toUpperCase(),
                      style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: canApply ? () => controller.applyCoupon(coupon) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                  ),
                  child: Text(TTexts.redeemCoupon.tr),
                ),
              ),
            ],
          ),

          /// Açıklama (boşsa satır hiç çizilmez)
          if (coupon.description.trim().isNotEmpty) ...[
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Text(coupon.description, style: theme.bodyMedium),
          ],
          const SizedBox(height: TSizes.spaceBtwItems),

          /// Kalan kullanım + geçerlilik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (coupon.usageLimit >= 0)
                Text(
                  '${(coupon.usageLimit - coupon.usageCount).floor()}',
                  style: theme.bodySmall?.copyWith(color: hasUsageLeft ? TColors.textSecondary : TColors.error),
                ),

              /// Geçerlilik süresi
              if (coupon.endDate != null)
                Text(
                  THelperFunctions.getFormattedDate(coupon.endDate!),
                  style: theme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
