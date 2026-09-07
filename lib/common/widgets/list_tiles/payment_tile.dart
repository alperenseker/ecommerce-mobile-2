/// Referanstaki boş yer tutucu (`ListTile()` döndürüyor, hiçbir yerden
/// çağrılmıyor). KURALLAR §4 gereği taşındı; ölü kod sanıp silme.
///
/// Ödeme ekranında kullanılan gerçek satır
/// `features/shop/screens/checkout/widgets/payment_tile.dart` içindedir.
library;

import 'package:flutter/material.dart';

class TPaymentTile extends StatelessWidget {
  const TPaymentTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile();
  }
}
