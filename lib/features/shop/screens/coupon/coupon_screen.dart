/// Kupon ekranı.
///
/// ⚠️ Sunucuda kupon ucu HENÜZ YOK — `ApiCouponRepository` boş liste
/// döndürüyor (referansta da öyle). Ekran bugün "kupon yok" boş durumunu
/// gösteriyor; uç eklendiği gün repository bağlanınca liste kendiliğinden
/// dolacak.
///
/// Seçilen kupon [CouponController.coupon] üzerinde tutulur ve ödeme sayfası
/// (FAZ 07) kodu oradan okur; bu ekran sipariş oluşturmaz.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/coupon_controller.dart';
import '../../models/coupon_model.dart';
import 'coupon_card.dart';

class CouponScreen extends StatelessWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `CouponBinding` rotadan gelirken kuruyor; ekran doğrudan `Get.to` ile
    // açılırsa da kayıtlı controller bulunur.
    final controller = CouponController.instance;

    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.coupon.tr),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: FutureBuilder<List<CouponModel>>(
        // ignore: discarded_futures
        future: controller.fetchAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(TSizes.defaultSpace),
              child: TVerticalProductShimmer(itemCount: 4),
            );
          }

          final coupons = snapshot.data ?? [];
          if (coupons.isEmpty) {
            return TEmptyState(
              icon: Iconsax.ticket_discount,
              title: TTexts.couponEmpty.tr,
              message: TTexts.couponEmptyText.tr,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            itemCount: coupons.length,
            itemBuilder: (context, index) => CouponCard(coupon: coupons[index]),
            separatorBuilder: (context, index) => const SizedBox(height: TSizes.spaceBtwItems),
          );
        },
      ),
    );
  }
}

/// ⚠️ Aşağıdaki iki sınıf **referanstaki dosyada da var ve hiçbir yerden
/// çağrılmıyor** (bilet kenarındaki yarım daire çentiği ve eski, sunucu
/// modeline bağlanmamış `Coupon` kaydı). KURALLAR §4 gereği taşındılar;
/// ölü kod sanıp silmeyin.
class HalfCircle extends StatelessWidget {
  const HalfCircle({super.key, required this.isTop});

  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 18,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              isTop
                  ? const BorderRadius.only(bottomRight: Radius.circular(10), bottomLeft: Radius.circular(10))
                  : const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
      ),
    );
  }
}

class Coupon {
  final String code;
  final double discount;
  final bool isPercentage;
  final double saved;
  final String description;
  final double? minimumOrderAmount;
  final double? uptoDiscount;

  Coupon({
    required this.code,
    required this.discount,
    required this.isPercentage,
    required this.saved,
    required this.description,
    this.minimumOrderAmount,
    this.uptoDiscount,
  });
}
