import '../../../utils/constants/enums.dart';

/// Ödeme yöntemi seçeneği (ad, simge, [PaymentMethods] karşılığı).
///
/// 🔴 Hangi seçeneklerin çizileceğini sunucudaki `paymentMode` belirler:
/// `transfer_only` modunda kart akışı hiç gösterilmez.
class PaymentMethodModel {
  String name;
  String image;
  final PaymentMethods paymentMethod;

  PaymentMethodModel({required this.image, required this.name, required this.paymentMethod});

  static PaymentMethodModel empty() => PaymentMethodModel(image: '', name: '', paymentMethod: PaymentMethods.cash);
}