/// Kupon kartı: indirim · kod · açıklama · kalan kullanım · geçerlilik.
///
/// TASARIM.md §6: beyaz kart, 1px çizgi, gölgesiz; "kullan" birincil düğme.
///
/// Kullanım hakkı bitmiş ya da pasif kuponda düğme KAPALIDIR.
library;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

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

    final discount = coupon.discountType == DiscountType.percentage
        ? '−${coupon.discountValue.toStringAsFixed(0)}%'
        : '−₸${coupon.discountValue.toStringAsFixed(2)}';

    /// 🔴 Kart artık **bilet** biçiminde: solda indirim değerini taşıyan renkli
    /// koçan, sağda kod ve ayrıntılar. Eskiden hepsi düz bir kartta alt alta
    /// duruyordu ve indirim oranı — kuponun tek önemli sayısı — küçük bir
    /// satır olarak kayboluyordu.
    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: canApply
              ? (dark ? TColors.darkBorder : TColors.borderSecondary)
              : (dark ? TColors.darkBorder : TColors.borderSecondary),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// -- Koçan: indirim
            Container(
              width: 92,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
              color: canApply
                  ? (dark ? TColors.darkAccent : TColors.dealSoft)
                  : (dark ? TColors.darkBorder : TColors.softGrey),
              child: Text(
                discount,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge?.copyWith(
                  color: canApply ? TColors.deal : TColors.darkGrey,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            /// -- Gövde: kod · açıklama · kullanım/geçerlilik · kullan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      coupon.code.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),

                    /// Açıklama (boşsa satır hiç çizilmez)
                    if (coupon.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        coupon.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: TSizes.sm),

                    /// Kalan kullanım + geçerlilik
                    Wrap(
                      spacing: TSizes.sm,
                      runSpacing: TSizes.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (coupon.usageLimit >= 0)
                          Text(
                            '${(coupon.usageLimit - coupon.usageCount).floor()}',
                            style: theme.labelMedium?.copyWith(
                              color: hasUsageLeft ? TColors.darkGrey : TColors.error,
                            ),
                          ),

                        /// Geçerlilik süresi
                        if (coupon.endDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.calendar_1, size: 12, color: TColors.darkGrey),
                              const SizedBox(width: 4),
                              Text(
                                THelperFunctions.getFormattedDate(coupon.endDate!),
                                style: theme.labelMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: TSizes.sm + 2),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: canApply ? () => controller.applyCoupon(coupon) : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                          // Tema en küçük genişliği sonsuz veriyor; `Row`
                          // içindeki düğme bunu alırsa çizim patlar
                          // (bkz. `cart.dart`).
                          minimumSize: Size.zero,
                        ),
                        child: Text(TTexts.redeemCoupon.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
