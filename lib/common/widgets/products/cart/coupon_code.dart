/// Kupon kodu giriş kutusu (ödeme özetinin içinde durur).
///
/// ⚠️ Sunucuda kupon ucu HENÜZ YOK; girilen kod [CouponController] üzerinde
/// tutulur ve ödeme sayfası (FAZ 07) oradan okur. Uç eklenince doğrulama
/// `ApiCouponRepository`ye bağlanacak.
///
/// TASARIM.md §6: form alanı 48px + 8px köşe, "uygula" ikincil düğme.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/shop/controllers/coupon_controller.dart';
import '../../../../features/shop/models/coupon_model.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../custom_shapes/containers/rounded_container.dart';

class TCouponCode extends StatefulWidget {
  const TCouponCode({super.key});

  @override
  State<TCouponCode> createState() => _TCouponCodeState();
}

class _TCouponCodeState extends State<TCouponCode> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Ekran yeniden çizilirse kullanıcının yazdığı kod kaybolmasın; uygulanan
    // kupon varsa kutuda görünsün.
    final applied = Get.isRegistered<CouponController>()
        ? CouponController.instance.coupon.value.code
        : '';
    _controller = TextEditingController(text: applied);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    final controller = Get.isRegistered<CouponController>()
        ? CouponController.instance
        : Get.put(CouponController());

    // Kupon listesi sunucudan boş geliyor; girilen kodu doğrulayacak bir uç
    // olmadığı için kod ödeme sayfasına ham hâliyle taşınır (sunucu sipariş
    // anında reddedebilir).
    controller.coupon.value = CouponModel(id: '', code: code, discountValue: 0);
    controller.isCouponToggled.value = true;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return TRoundedContainer(
      showBorder: true,
      backgroundColor: dark ? TColors.darkSurface : TColors.white,
      radius: TSizes.buttonRadius,
      padding: const EdgeInsets.only(
        top: TSizes.sm,
        bottom: TSizes.sm,
        right: TSizes.sm,
        left: TSizes.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Kod alanı
          Flexible(
            child: TextFormField(
              controller: _controller,
              expands: false,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _apply(),
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                hintText: TTexts.couponCode.tr,
              ),
            ),
          ),

          /// Uygula
          OutlinedButton(
            onPressed: _apply,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(TTexts.apply.tr),
          ),
        ],
      ),
    );
  }
}
