/// Sipariş oluşturma, Halyk ePay ödemesi ve sipariş listeleri.
///
/// 🔴 **Bir ödeme = bir GRUP + şirket başına bir sipariş.** Sepette iki
/// şirketin (1C kaynağının) ürünü varsa sunucu siparişi böler, ikisi de aynı
/// `GroupId` altında toplanır ve **tek çekimle** ödenir. Bölmeyi sunucu
/// yapar; istemci yalnız müşteriyi önceden bilgilendirir.
///
/// 🔴 **Ödeme dalları** (web `pages/checkout.js` ile birebir):
///   • kredili müşteri (`HasCreditLine`) → `pending_approval`, ödeme alınmaz,
///   • genel `transfer_only` modu → `bank_transfer`, ePay'e HİÇ gidilmez
///     (sunucu o modda `payments/epay-token` ucuna 409 dönüyor),
///   • diğer herkes → seçtiği yöntem; kart seçtiyse Halyk ePay.
///
/// 🔴 **Tutarın tek kaynağı sunucudur.** Widget'a giden tutar
/// `payments/epay-token` yanıtındaki `amount`'tır; istemcinin hesapladığı
/// tutar yalnız ön kontrol içindir. Farklı olsa Halyk reddederdi.
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:t_utils/utils/constants/enums.dart';

import '../../../../data/repositories/order/api_order_repository.dart';
import '../../../../data/services/epay/epay_service.dart';
import '../../../../data/services/notifications/notification_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../../personalization/controllers/public_settings_controller.dart';
import '../../../personalization/controllers/settings_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/coupon_model.dart';
import '../../models/order_activity.dart';
import '../../models/order_group_model.dart';
import '../../models/order_model.dart';
import '../../models/shipping_model.dart';
import '../../screens/checkout/epay_webview_screen.dart';
import '../../screens/checkout/order_placed_screen.dart';
import '../coupon_controller.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';
import 'product_controller.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final isLoading = false.obs;
  final loadingOrders = false.obs;
  Rx<OrderModel> selectedOrder = OrderModel.empty().obs;
  final selectedOrderId = ''.obs;

  /// Değişkenler
  var selectedMethod = 0.obs;
  final orders = <OrderModel>[].obs;

  /// Kullanıcının alışverişleri (sipariş grupları). "Siparişlerim" ekranı
  /// bunu gösterir: bir alışveriş, şirket başına bir sipariş.
  final orderGroups = <OrderGroupModel>[].obs;

  /// FAZ 08 — sipariş kimliği → o siparişin kalemleri.
  ///
  /// 🔴 Kalemler **talep üzerine** çekilir (liste satırı açıldığında) ve
  /// burada saklanır. 40 siparişlik bir listede kalemleri önden çekmek 40 ek
  /// istek demekti; web (`pages/account-orders.js` → `details`) de aynı
  /// önbelleği tutuyor.
  final orderItems = <String, List<CartItemModel>>{}.obs;

  /// Kalemleri şu an çekilmekte olan siparişler (satırda dönen halka için).
  final loadingOrderItems = <String>{}.obs;

  final cartController = CartController.instance;
  final addressController = AddressController.instance;
  final checkoutController = Get.put(CheckoutController());
  final couponController = Get.put(CouponController());
  final orderRepository = ApiOrderRepository.instance;
  final userController = Get.put(UserController());
  final settingController = Get.put(SettingsController());

  /// Sipariş detayı için ilk veri
  Future<void> init() async {
    try {
      isLoading.value = true;
      // Argüman gelmediyse kaydı sunucudan çek
      if (selectedOrder.value.id.isEmpty) {
        if (selectedOrderId.value.isEmpty) {
          Get.back();
        } else {
          selectedOrder.value = await orderRepository.fetchSingleOrder(orderId: selectedOrderId.value);

          if (selectedOrder.value.id.isEmpty) Get.back();
        }
      }
    } catch (e) {
      if (selectedOrder.value.id.isEmpty) {
        Get.back();
      } else {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: '${TTexts.unableFetchOrderDetail.tr} $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectMethod(int index) {
    selectedMethod.value = index;
  }

  /// Kullanıcının sipariş geçmişi
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      loadingOrders.value = true;
      final userOrders = await orderRepository.fetchUserOrders(userId: userController.user.value.id);
      orders.assignAll(userOrders);
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return [];
    } finally {
      loadingOrders.value = false;
    }
  }

  Future<OrderModel> fetchSingleOrder(String id) async {
    return await orderRepository.fetchSingleOrder(orderId: id);
  }

  /// Kullanıcının alışverişlerini (gruplarını) getirir.
  ///
  /// Grup ucu okunamazsa repository düz sipariş listesinden grup kuruyor, bu
  /// yüzden burada ayrı bir yedek yola gerek yok.
  Future<List<OrderGroupModel>> fetchUserOrderGroups() async {
    try {
      loadingOrders.value = true;
      final groups = await orderRepository.fetchUserOrderGroups(userId: userController.user.value.id);
      orderGroups.assignAll(groups);
      return groups;
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return [];
    } finally {
      loadingOrders.value = false;
    }
  }

  /// Bir siparişin ait olduğu alışverişi (grubu) bulur.
  ///
  /// Tek grup ucu (`GET /order/group/{id}`) yok; grup ucu kullanıcının BÜTÜN
  /// gruplarını döndürüyor ve buradan süzülüyor. Bulunamazsa siparişin
  /// kendisinden tek siparişlik bir grup kurulur, böylece çağıran her hâlde
  /// çalışır.
  Future<OrderGroupModel> resolveGroupFor(OrderModel order) async {
    if (order.groupId.isEmpty) return OrderGroupModel.fromOrder(order);
    try {
      final groups = await orderRepository.fetchUserOrderGroups(
          userId: order.userId.isNotEmpty ? order.userId : userController.user.value.id);
      return groups.firstWhere(
        (g) => g.groupId == order.groupId,
        orElse: () => OrderGroupModel.fromOrder(order),
      );
    } catch (_) {
      return OrderGroupModel.fromOrder(order);
    }
  }

  /// Tek bir alışverişi (grubu) kimliğiyle getirir.
  ///
  /// Sunucuda tek grup ucu yok (`GET /order/group/{id}` mevcut değil); grup
  /// ucu kullanıcının bütün gruplarını döndürüyor ve buradan süzülüyor.
  /// Bulunamazsa `null` döner — çağıran "alışveriş bulunamadı" gösterir.
  Future<OrderGroupModel?> fetchGroup(String groupId) async {
    if (groupId.isEmpty) return null;
    try {
      loadingOrders.value = true;
      final groups = await orderRepository.fetchUserOrderGroups(userId: userController.user.value.id);
      orderGroups.assignAll(groups);
      for (final group in groups) {
        if (group.groupId == groupId) return group;
      }
      return null;
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
      return null;
    } finally {
      loadingOrders.value = false;
    }
  }

  /// Bir siparişin kalemlerini **talep üzerine** getirir ve önbelleğe alır.
  ///
  /// Liste satırı ilk kez açıldığında çağrılır. Aynı sipariş ikinci kez
  /// açıldığında istek atılmaz; hata durumunda önbelleğe **boş liste yazılmaz**
  /// ki kullanıcı yeniden deneyebilsin.
  Future<void> loadOrderItems(String orderId) async {
    if (orderId.isEmpty) return;
    if (orderItems.containsKey(orderId)) return;
    if (loadingOrderItems.contains(orderId)) return;

    loadingOrderItems.add(orderId);
    loadingOrderItems.refresh();
    try {
      final order = await orderRepository.fetchSingleOrder(orderId: orderId);
      orderItems[orderId] = order.products;
    } catch (_) {
      // Sessiz: satırın kendisi "kalemler okunamadı" yazar. Balon çıkarsaydı
      // birkaç satır açan kullanıcı üst üste uyarı görürdü.
    } finally {
      loadingOrderItems.remove(orderId);
      loadingOrderItems.refresh();
    }
  }

  /// Ödenmemiş bir **alışverişin** (grubun) ödemesini tamamlar.
  ///
  /// Ödeme tek çekimdir ve grubun bütün siparişlerini birden kapatır (K3), bu
  /// yüzden `groupId` gönderilir. Grubun ilk siparişi yalnız `orderId` alanını
  /// doldurmak için kullanılır; çekilen tutarı **backend** belirler.
  ///
  /// 🔴 `transfer_only` modunda hiç çağrılmaz (düğme çizilmez); yine de
  /// [completePayment] ikinci kapıyı koyuyor.
  Future<void> completePaymentForGroup(OrderGroupModel group) async {
    if (group.orders.isEmpty) return;

    // Grubun ilk ödenmemiş siparişi üzerinden yürünür: `completePayment`
    // "zaten ödendi" kapısını sipariş üzerinden kontrol ediyor.
    final target = group.orders.firstWhere(
      (o) => o.paymentStatus != PaymentStatus.paid,
      orElse: () => group.orders.first,
    );
    await completePayment(target);
  }

  /// Siparişi oluşturur ve (gerekiyorsa) ödemeyi başlatır.
  void processOrder(double subTotal) async {
    try {
      if (addressController.selectedAddress.value.id.isEmpty) {
        TLoaders.warningSnackBar(title: TTexts.addressRequired.tr, message: TTexts.addressRequiredMessage.tr);
        return;
      }

      if (userController.user.value.id.isEmpty) {
        return;
      }

      // 🔴 Fatura adresi: ŞİRKET hesabında 1C'den geliyor ve düzenlenemiyor;
      // sunucuya teslimat adresinin kimliği gönderilir (web `orderBody`:
      // `isCompany ? shipping.id : billing.id`). Bireysel hesapta fatura
      // adresi zorunlu — "teslimatla aynı" işaretli değilse seçilmiş olmalı.
      final isCompany = addressController.isCorporate;
      if (!isCompany && addressController.billingSameAsShipping.isFalse) {
        if (addressController.selectedBillingAddress.value.id.isEmpty) {
          TLoaders.warningSnackBar(
              title: TTexts.billingAddressRequired.tr, message: TTexts.billingAddressRequiredMessage.tr);
          return;
        }
      }

      // Sepet sunucuda tutuluyor ve web uygulamasıyla PAYLAŞILIYOR: aynı
      // kullanıcı bu siparişi web'de tamamlamış ve sunucudaki sepeti tüketmiş
      // olabilir. Bir şey oluşturmadan önce yeniden oku — yoksa sunucudan
      // artık var olmayan bir sepetten sipariş kurması istenirdi.
      await cartController.refreshFromBackend();
      if (cartController.cartItems.isEmpty) {
        TLoaders.warningSnackBar(title: TTexts.emptyCart.tr, message: TTexts.cartMessage.tr);
        Get.back();
        return;
      }
      // Taze toplamı kullan: ekran kurulurken alınan değer başka bir cihazda
      // sepet değiştiyse bayat olabilir.
      subTotal = cartController.totalCartPrice.value;

      // 🔴 Genel ödeme modu sipariş oluşturmadan HEMEN ÖNCE tazelenir. Bayat
      // bir değer müşteriyi ya kapalı ePay yoluna sokar (sunucu 409 döner ve
      // kullanıcı hata görür) ya da gereksiz yere havale dalına atar. Çağrı
      // hata verirse son bilinen değer korunur.
      await checkoutController.capturePaymentMode(force: true);

      // 🔴 Limit kontrolü sipariş anında TEKRAR koşar: ekran açıkken sepet
      // değişmiş olabilir (web `place-order` da böyle yapıyor). Ayrım
      // `HasCreditLine` iledir — `CanBypassPayment` `transfer_only`'de herkese
      // true dönüyor ve ona bakan kod minimum tutar kontrolünü düşürürdü.
      final limits = checkoutController.evaluateLimits(subTotal);
      if (!limits.canProceed) {
        TLoaders.warningSnackBar(title: TTexts.orderBlockedTitle.tr, message: limits.message);
        return;
      }

      // Kart ekranına gidilecek mi. `transfer_only`'de ve kredili müşteride
      // ASLA gidilmez.
      final payByCard = checkoutController.willPayByCard;

      // Yükleyiciyi başlat
      TFullScreenLoader.openLoadingDialog(TTexts.processingYourOrder.tr, TImages.pencilAnimation);

      // Cihaz jetonu (bildirim için)
      final token = await TNotificationService.getToken();

      final shipping = ShippingInfo(
        carrier: '',
        trackingNumber: UniqueKey().toString(),
        shippingStatus: ShippingStatus.pending,
        shippingMethod: ShippingMethod.express,
      );

      final activity = OrderActivity(
        activityType: ActivityType.orderCreated,
        activityDate: DateTime.now(),
        performedBy: Role.user.name,
        description: TTexts.orderCreateSuccessfully.tr,
      );

      final totalAmount = double.parse(checkoutController.calculateGrandTotal(subTotal).toStringAsFixed(2));
      final shippingAmount = SettingsController.instance.settings.value.isTaxShippingEnabled
          ? checkoutController.getShippingCost(
              (subTotal - checkoutController.calculateTotalDiscount(subTotal)).clamp(0.0, double.infinity),
            )
          : 0.0;
      final taxAmount = SettingsController.instance.settings.value.isTaxShippingEnabled
          ? checkoutController.getTaxAmount(subTotal)
          : 0.0;
      final pointsUsed =
          checkoutController.isUsingPoints.value ? checkoutController.pointsDiscountAmount.value.toInt() : 0;
      final couponDiscountAmount = couponController.coupon.value.discountType == DiscountType.flat
          ? couponController.coupon.value.discountValue
          : ((couponController.coupon.value.discountValue * subTotal) / 100);

      // Yerel sipariş nesnesi — eski API yanıtında `Orders[]` gelmezse
      // listeye bu ekleniyor.
      final order = OrderModel(
        docId: '',
        id: UniqueKey().toString(),
        userId: userController.user.value.id,
        userName: userController.user.value.fullName,
        userEmail: userController.user.value.email,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        shippingAddress: addressController.selectedAddress.value,
        products: cartController.cartItems,
        paymentStatus: PaymentStatus.unpaid,
        orderStatus: OrderStatus.pending,
        shippingInfo: shipping,
        activities: [activity],
        itemCount: cartController.cartItems.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        shippingAmount: shippingAmount,
        taxAmount: taxAmount,
        billingAddress: null,
        billingAddressSameAsShipping: true,
        userDeviceToken: token,
        subTotal: subTotal,
        coupon: couponController.coupon.value,
        taxRate: settingController.settings.value.taxRate,
        couponDiscountAmount: couponDiscountAmount,
        pointsUsed: pointsUsed,
        pointsDiscountAmount: checkoutController.pointsDiscountAmount.value,
        totalDiscountAmount: checkoutController.calculateTotalDiscount(subTotal),
        paymentMethodType: checkoutController.selectedPaymentMethod.value.paymentMethod,
      );

      // Siparişi oluştur. Sunucu oluşturma anında sepeti tüketiyor ve
      // otoriter toplamı ondan hesaplıyor; bu yüzden hiçbir zaman istemci
      // tarafında hesaplanmış bir tutar gönderilmez.
      //
      // ℹ️ Sunucu `transfer_only`'de `PaymentMethod`'u zaten `bank_transfer`'a
      // çeviriyor; doğru değeri göndermek onun düzeltmesine bel bağlamamak
      // içindir.
      final paymentMethod = checkoutController.resolvePaymentMethod();
      final purchase = await orderRepository.createOrder(
        userId: order.userId,
        shippingAddressId: addressController.selectedAddress.value.id,
        // 🔴 Şirket hesabında fatura adresi = teslimat adresi (1C adresinin
        // veritabanında kimliği yok).
        billingAddressId: (isCompany || addressController.billingSameAsShipping.isTrue)
            ? addressController.selectedAddress.value.id
            : addressController.selectedBillingAddress.value.id,
        paymentMethod: paymentMethod,
        customerNote: checkoutController.customerNote.text.trim(),
        couponCode: couponController.coupon.value.id.isNotEmpty ? couponController.coupon.value.id : null,
        // Stoksuz sipariş yetkisi olan bayi stok bitse de sipariş verebiliyor;
        // sunucu stok kapısını bu bayrağa göre gevşetiyor (web
        // `order.service.js` → `CanOrderWithoutStock`).
        canOrderWithoutStock: cartController.canOrderWithoutStock,
      );
      order.docId = purchase.orderId;

      // Sipariş sunucuda kayıtlı ve sunucudaki sepet tüketildi. Yerel sepeti
      // ve kuponu **hemen** temizle — ödeme adımından ÖNCE — ki başka bir
      // cihazdaki sepet düzenlemesi bir şeyi ayrıştırmasın ve kullanıcı ödeme
      // ekranını kapatırsa bayat sepetle kalmasın.
      //
      // ⚠️ Bu temizlikte "sepet temizlendi" balonu GÖSTERİLMEZ: kullanıcı
      // sepetini silmedi, siparişe çevirdi. `clearCart()` zaten sessiz.
      final purchasedItems = cartController.cartItems.toList();
      final appliedCoupon = couponController.coupon.value;
      cartController.clearCart();
      couponController.coupon.value = CouponModel.empty();

      // Kart ödemesi: Halyk ePay'in güvenli sayfası (WebView). Çekilen tutar
      // **backend'in** `epay-token` yanıtındaki tutardır (grubun toplamı),
      // asla yerel/bayat bir sayı değil. Otoriter sonuç `postLink` ile
      // backend'e ulaşır ve grubun tüm siparişlerini birden ödendi yapar.
      if (payByCard) {
        final paid = await _runEpayPayment(
          orderId: purchase.orderId,
          groupId: purchase.groupId,
          requestedAmount: purchase.totalAmount,
        );
        if (paid != true) {
          // İptal/başarısız: siparişler kayıtlı ama ödenmemiş kalır.
          // Kullanıcı ödemeyi sonra sipariş geçmişinden tamamlayabilir
          // ("ödemeyi tamamla"); ödeme oradan da grubun tamamını kapatır.
          TLoaders.warningSnackBar(
            title: TTexts.paymentFailed.tr,
            message: TTexts.orderPlacedNotPaidYet.tr,
          );
          Get.off(() => OrderPlacedScreen.fromResult(purchase, verifyPayment: true));
          return;
        }
        // Ödendi — kalan işler için yükleyiciyi yeniden aç.
        TFullScreenLoader.openLoadingDialog(TTexts.processingYourOrder.tr, TImages.pencilAnimation);
      }

      // Kupon kullanım sayacı
      if (appliedCoupon.id.isNotEmpty) {
        couponController.updateUsageCount(appliedCoupon);
      }

      // Kullanıcının sipariş sayacı — tutar GRUBUN toplamıdır (tek alışveriş).
      await userController.updateUserAfterOrder(
          total: purchase.totalAmount, isUsingPoints: checkoutController.isUsingPoints.value);

      // Sipariş verildikten sonra her kalemin stoğunu güncelle (sepet
      // temizlenmeden önce alınan kopyadan).
      final productController = Get.put(ProductController());
      for (var product in purchasedItems) {
        await productController.updateProductStock(product.productId, product.quantity, product.variationId);
      }

      // Sipariş listesi — alışverişte doğan siparişlerin hepsi eklenir.
      if (purchase.orders.isNotEmpty) {
        orders.addAll(purchase.orders);
      } else {
        orders.add(order);
      }

      // Sipariş başına bir bildirim: kullanıcı bir alışverişte birden çok
      // bildirim alır, bu yüzden metinde şirket adı da geçer.
      addOrderNotifications(purchase);

      // Onay ekranı: alışveriş numarası, kaç sipariş doğdu ve ödenecek tutar.
      // ePay akışında backend'in postLink çağrısı hâlâ yolda olabilir, o
      // yüzden ekran ödeme durumunu kendisi yokluyor.
      Get.off(() => OrderPlacedScreen.fromResult(purchase, verifyPayment: payByCard));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// Halyk ePay güvenli sayfasını **alışveriş** için açar ve sonucu döndürür.
  ///
  /// Ödeme tek çekimdir ve alışverişin (grubun) tamamını kapatır. [groupId]
  /// gönderilir; çekilen tutar **backend'in döndürdüğü** `amount`'tır
  /// ([requestedAmount] yalnız ön kontrol içindir), böylece ödenen tutar ile
  /// grubun toplamı asla ayrışamaz.
  ///
  /// Sonuç: `true` ödendi, `false` başarısız, `null` kullanıcı iptal etti.
  Future<bool?> _runEpayPayment({
    required String orderId,
    required String groupId,
    required double requestedAmount,
  }) async {
    // WebView'i açmadan önce işlem yükleyicisini kapat, yoksa ödeme ekranı
    // onun arkasında kalır.
    TFullScreenLoader.stopLoading();

    final int amount = requestedAmount.round(); // ePay tam sayı KZT bekliyor
    if (amount <= 0) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.emptyCart.tr);
      return false;
    }

    try {
      final user = userController.user.value;
      // 🔴 `invoiceId` istemcide ÜRETİLMEZ: backend üretip gruba yazıyor ki
      // `postLink` çağrısı alışverişi onunla bulabilsin.
      final token = await TEpayService.fetchToken(
        amount: amount,
        orderId: orderId,
        groupId: groupId,
        description: 'Order #$orderId',
      );

      final paymentObject = TEpayService.buildPaymentObject(
        token: token,
        // 🔴 Tutarın TEK kaynağı backend'in yanıtıdır (grup toplamı).
        amount: token.amount,
        orderId: orderId,
        accountId: user.id,
        name: user.fullName,
        email: user.email,
        phone: user.phoneNumber,
      );

      // Widget ortamını (test/canlı) backend `widgetUrl` ile seçiyor;
      // güvenilmeyen ya da eksik değerde yerleşik test adreslerine düşülür.
      final widgetSources = TEpayService.resolveWidgetSources(token.widgetUrl);

      // Ödeme birden çok siparişi birden kapatıyorsa müşteri bunu ödeme
      // ekranına gitmeden önce görsün — yoksa tek siparişin tutarını ödediğini
      // sanabilir.
      if (token.coversMultipleOrders) {
        TLoaders.customToast(
          message: '${TTexts.paymentCoversOrders.trParams({'count': '${token.orderCount}'})} '
              '(${TFormatter.formatCurrency(token.amount.toDouble())})',
        );
      } else {
        TLoaders.customToast(message: TTexts.redirectingToPayment.tr);
      }

      final result = await Get.to<bool>(
        () => EpayWebViewScreen(paymentObject: paymentObject, widgetSources: widgetSources),
      );

      if (result == null) {
        TLoaders.warningSnackBar(title: TTexts.paymentFailed.tr, message: TTexts.paymentCancelled.tr);
      } else if (result == false) {
        TLoaders.errorSnackBar(title: TTexts.paymentFailed.tr, message: TTexts.paymentCancelled.tr);
      }
      return result;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.paymentFailed.tr, message: e.toString());
      return false;
    }
  }

  /// Onay ekranından **sipariş takibine** yönlendirir: grup varsa grup
  /// (siparişler listesi), yoksa tek siparişin detayı.
  ///
  /// ⚠️ Sipariş ekranları FAZ 08'de geliyor; rota henüz açılmamışsa ana
  /// menüye düşülür — GetX'in "bilinmeyen rota" ekranı gösterilmez.
  Future<void> openPurchase({
    required List<OrderModel> orders,
    required String purchaseNumber,
    required String pollOrderId,
  }) async {
    final isSplit = orders.length > 1;

    // Bölünmüş alışverişte tek bir sipariş detayı yeterli değil: kullanıcı
    // hepsini görmeli, o yüzden sipariş listesine gidilir.
    if (isSplit && AppRoutes.isRegistered(TRoutes.order)) {
      Get.offAllNamed(TRoutes.order);
      return;
    }

    if (AppRoutes.isRegistered(TRoutes.orderDetail)) {
      OrderModel? target = orders.isNotEmpty ? orders.first : null;
      if (target == null && pollOrderId.isNotEmpty) {
        try {
          target = await orderRepository.fetchSingleOrder(orderId: pollOrderId);
        } catch (_) {
          // Sipariş çekilemedi — listeye/ana menüye düşülür.
        }
      }
      if (target != null) {
        Get.offAllNamed(TRoutes.orderDetail, arguments: target);
        return;
      }
    }

    if (AppRoutes.isRegistered(TRoutes.order)) {
      Get.offAllNamed(TRoutes.order);
      return;
    }
    Get.offAllNamed(TRoutes.homeMenu);
  }

  /// Alışverişte doğan **her sipariş için ayrı** bir bildirim üretir.
  ///
  /// Bir alışverişte üç sipariş doğabildiği için kullanıcı üç bildirim alır;
  /// hangisinin hangi şirkete ait olduğu karışmasın diye metinde sipariş
  /// numarasının yanında şirket adı da geçer (`ORD-…-1 · Fores`).
  ///
  /// ⚠️ Bildirim servisi FAZ 09'da kuruluyor; kayıtlı değilse bildirim
  /// atlanır (sipariş akışı bir bildirim yüzünden patlamaz).
  void addOrderNotifications(CreateOrderResultModel purchase) {
    if (!Get.isRegistered<TNotificationService>()) return;

    if (purchase.orders.isEmpty) {
      // Eski API: tek sipariş, şirket bilgisi yok.
      TNotificationService.instance.addNotification(
        title: TTexts.orderPlacedSuccess.tr,
        body: TTexts.orderPlacedNotificationBody.trParams({'order': purchase.purchaseNumber}),
        route: '${TRoutes.orderDetail}/${purchase.orderId}',
        routeId: purchase.orderId,
      );
      return;
    }

    for (final order in purchase.orders) {
      final label = order.hasCompany ? '${order.displayId} · ${order.companyLabel}' : order.displayId;
      TNotificationService.instance.addNotification(
        title: TTexts.orderPlacedSuccess.tr,
        body: TTexts.orderPlacedNotificationBody.trParams({'order': label}),
        route: '${TRoutes.orderDetail}/${order.id}',
        routeId: order.id,
      );
    }
  }

  /// Sipariş iptali
  Future<void> cancelOrder(OrderModel order) async {
    await orderRepository.updateOrderStatusOnly(orderId: order.id, orderStatus: OrderStatus.canceled.name);
    TLoaders.successSnackBar(title: TTexts.ohSnap.tr, message: TTexts.orderCancelled.tr);
    selectedOrder.refresh();
  }

  /// Oluşturulmuş ama hâlâ ödenmemiş bir [order] için ePay akışını yeniden
  /// koşturur — kullanıcı ödemeyi ödeme ekranında iptal ettiyse, sipariş
  /// geçmişinden ("ödemeyi tamamla") burayı kullanır.
  ///
  /// Ödeme **grubun tamamını** kapatır: `groupId` gönderilir ve çekilen tutar
  /// backend'in döndürdüğü grup toplamıdır, tek siparişin tutarı değil.
  Future<void> completePayment(OrderModel order) async {
    if (order.paymentStatus == PaymentStatus.paid) {
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: TTexts.orderAlreadyPaid.tr);
      return;
    }

    // 🔴 Genel mod `transfer_only` iken kart ekranı HİÇ açılmaz. Sunucu
    // `epay-token`'a 409 (`payment_disabled`) dönüyor ve müşteri o hata
    // ekranını görmemeli. Düğme zaten çizilmiyor; bu ikinci kapı,
    // bildirimden/derin bağlantıdan gelinmesi ya da anahtarın ekran açıkken
    // çevrilmesi ihtimaline karşı.
    await PublicSettingsController.instance.reload();
    if (PublicSettingsController.instance.isTransferOnly) {
      TLoaders.warningSnackBar(
        title: TTexts.bankTransferOnlyTitle.tr,
        message: TTexts.bankTransferOnlyNote.tr,
      );
      return;
    }

    final paid = await _runEpayPayment(
      orderId: order.id,
      groupId: order.groupId,
      // Ön kontrol için siparişin tutarı; gerçek tutarı backend belirler.
      requestedAmount: order.totalAmount,
    );

    if (paid == true) {
      // Ödeme sonrası alışverişin tamamı gösterilir; grup okunamazsa tek
      // siparişlik görünüme düşülür.
      final group = await resolveGroupFor(order);
      Get.off(() => OrderPlacedScreen.fromGroup(group, verifyPayment: true));
    }
    // İptal/başarısızda mesajı _runEpayPayment zaten gösterdi; kullanıcı
    // sipariş detayında kalsın, yeniden deneyebilsin.
  }
}
