/// Sipariş ekranlarındaki **ödeme kapıları** — tek yerde.
///
/// Aynı kurallar hem sipariş listesinde hem detayda (grup ve tek sipariş
/// görünümünde) geçerli; üç yerde kopyalanınca biri güncellenip diğeri
/// unutulur. Kurallar web `pages/account-orders.js` → `payButton()` ve
/// `pages/order.js` → `payActionHtml()` / `bankVisible()` ile birebirdir.
///
/// 🔴 **Genel mod (`transfer_only`) HER kapıda EN BAŞTA okunur.** Kısa devre
/// yüzünden okunmadan geçilirse çağıran `Obx` genel anahtarı izlemeye almaz
/// ve mod sunucudan çevrildiğinde ekran güncellenmez.
library;

import 'package:t_utils/utils/constants/enums.dart';

import '../../../../personalization/controllers/public_settings_controller.dart';
import '../../../models/order_group_model.dart';
import '../../../models/order_model.dart';

/// Sunucuya kart ödemesi olarak giden yöntem kodları.
/// (checkout `card` yazıyor, eski kayıtlarda `credit_card` var)
const Set<String> kCardPaymentMethods = {'card', 'credit_card'};

/// Havale rekvizitlerinin gösterildiği yöntem kodları.
const Set<String> kTransferPaymentMethods = {'bank_transfer', 'pending_approval'};

/// "Ödemeyi tamamla" düğmesi çizilmeli mi — **saf kural**.
///
/// 🔴 `transfer_only` modunda daima `false`: sunucu o modda
/// `payments/epay-token` ucuna 409 (`payment_disabled`) dönüyor ve müşteri o
/// hata ekranını görmemeli.
bool canCompleteCardPayment({
  required bool transferOnly,
  required String paymentMethod,
  required PaymentStatus paymentStatus,
  required double amount,
  bool isCanceled = false,
}) {
  if (transferOnly) return false;
  if (isCanceled) return false;
  if (paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.refunded) return false;
  if (amount <= 0) return false;

  // Yöntem boşsa (eski kayıt) düğme çizilmez: ePay yalnız kart siparişinde
  // açılır, havale siparişinde müşteri rekvizitlere bakar.
  return kCardPaymentMethods.contains(paymentMethod.toLowerCase());
}

/// Havale rekvizitleri gösterilmeli mi — **saf kural**.
///
/// Ödenmiş ya da iade edilmiş siparişte gösterilmez; `transfer_only` modunda
/// yöntem ne olursa olsun gösterilir (o modda ödeme zaten havaleyle alınıyor).
bool shouldShowBankDetails({
  required bool transferOnly,
  required String paymentMethod,
  required PaymentStatus paymentStatus,
  bool isCanceled = false,
}) {
  if (isCanceled) return false;
  if (paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.refunded) return false;

  return kTransferPaymentMethods.contains(paymentMethod.toLowerCase()) || transferOnly;
}

// ─── Ekranların çağırdığı sarmalayıcılar ────────────────────────────────────
// Genel anahtar İLK SATIRDA okunuyor; çağıran `Obx` böylece onu izler.

/// Alışveriş (grup) için "ödemeyi tamamla".
bool canPayGroup(OrderGroupModel group) {
  final transferOnly = PublicSettingsController.instance.isTransferOnly;
  if (group.orders.isEmpty) return false;
  return canCompleteCardPayment(
    transferOnly: transferOnly,
    paymentMethod: group.paymentMethod,
    paymentStatus: group.paymentStatus,
    amount: group.totalAmount,
  );
}

/// Tek sipariş için "ödemeyi tamamla".
bool canPayOrder(OrderModel order) {
  final transferOnly = PublicSettingsController.instance.isTransferOnly;
  return canCompleteCardPayment(
    transferOnly: transferOnly,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    amount: order.totalAmount,
    isCanceled: order.orderStatus == OrderStatus.canceled,
  );
}

/// Alışveriş için havale rekvizitleri.
bool bankDetailsVisibleForGroup(OrderGroupModel group) {
  final transferOnly = PublicSettingsController.instance.isTransferOnly;
  return shouldShowBankDetails(
    transferOnly: transferOnly,
    paymentMethod: group.paymentMethod,
    paymentStatus: group.paymentStatus,
  );
}

/// Tek sipariş için havale rekvizitleri.
///
/// 🔴 **Şirketi olmayan eski sipariş** (`erp_source_id` NULL) bölümü açsa da
/// içi boş kalır: `TBankTransferDetails` kodu boş bloğu çizmiyor — hangi
/// hesaba yatırılacağı belirsizken ad uydurulmaz.
bool bankDetailsVisibleForOrder(OrderModel order) {
  final transferOnly = PublicSettingsController.instance.isTransferOnly;
  return shouldShowBankDetails(
    transferOnly: transferOnly,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    isCanceled: order.orderStatus == OrderStatus.canceled,
  );
}
