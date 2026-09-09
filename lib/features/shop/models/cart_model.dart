import 'cart_item_model.dart';

/// Sepetin tamamı (kalemler + toplam).
///
/// FAZ 01'de yalnız `pricing_calculator.dart` derlenebilsin diye getirildi;
/// asıl sahibi FAZ 02'nin veri katmanıdır.
class CartModel {
  String cartId;
  List<CartItemModel> items;

  CartModel({
    required this.cartId,
    required this.items,
  });

  static CartModel empty() => CartModel(cartId: '', items: []);
}
