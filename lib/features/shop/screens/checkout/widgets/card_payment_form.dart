/// Elle kart girişi formu.
///
/// 🔴 **HİÇBİR YERDEN ÇİZİLMEZ ve çizilmemelidir.** Kart bilgisi bu
/// uygulamada toplanmıyor: ödeme Halyk ePay'in PCI güvenli sayfasında
/// yapılıyor ([TEpaySecureNote] bunu anlatır). Dosya KURALLAR §4 gereği
/// referanstan taşındı (orada da yalnız yorumda duruyor); ölü kod sanıp
/// silme, ama ekrana da bağlama.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/product/checkout_controller.dart';

class TCardPaymentForm extends StatelessWidget {
  const TCardPaymentForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;
    return Form(
      key: controller.cardFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionHeading(title: TTexts.enterCardDetails.tr, showActionButton: false),
          const SizedBox(height: TSizes.spaceBtwItems),

          /// Kart sahibi
          TextFormField(
            controller: controller.cardHolderName,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
              _UpperCaseFormatter(),
            ],
            decoration: InputDecoration(
              labelText: TTexts.cardHolderName.tr,
              prefixIcon: const Icon(Iconsax.user),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Kart numarası
          TextFormField(
            controller: controller.cardNumber,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: TTexts.cardNumber.tr,
              hintText: '0000 0000 0000 0000',
              prefixIcon: const Icon(Iconsax.card),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Son kullanma + CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.cardExpiry,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: TTexts.expiryDate.tr,
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Iconsax.calendar),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: TextFormField(
                  controller: controller.cardCvv,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: TTexts.cvv.tr,
                    prefixIcon: const Icon(Iconsax.lock),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kart numarasını dörderli bloklara ayırır (`4242 4242 4242 4242`).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Son kullanma tarihine `/` ayıracını koyar (`12/27`).
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Kart sahibinin adını yazarken büyük harfe çevirir.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
