/// Ödeme yöntemi tanımı.
library;

import '../../../utils/constants/enums.dart';

class PaymentMethodModel {
  String name;
  String image;
  final PaymentMethods paymentMethod;

  PaymentMethodModel({required this.image, required this.name, required this.paymentMethod});

  static PaymentMethodModel empty() => PaymentMethodModel(image: '', name: '', paymentMethod: PaymentMethods.cash);
}