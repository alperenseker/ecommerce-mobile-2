/// İade / değişim talepleri.
///
/// 🔴 **Sunucuda iade ucu YOK.** `ApiReturnRepository` bugün bir yer
/// tutucudur: listeler boş döner, `addNewItem` `UnsupportedError` fırlatır
/// (referansta da öyle). Ekranlar ve akış referansla birebir yazıldı ki uç
/// açıldığında yalnız repository'nin gövdesi doldurulsun; kapılar, doğrulama
/// ve durum eşlemeleri hazır beklesin.
///
/// Talep tek bir **siparişten** açılır (grup değil): iade edilen mal bir
/// şirkete geri gidiyor ve sipariş zaten şirket başına bölünmüş durumda.
library;

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../common/widgets/success_screen/success_screen.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/return/api_return_repository.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/return_request_model.dart';

class ReturnController extends GetxController {
  static ReturnController get instance => Get.find();

  // Repository instance
  final ApiReturnRepository _returnRepository = ApiReturnRepository.instance;

  // Reactive variables
  final Rx<ReturnRequest> returnRequest = ReturnRequest.empty().obs;
  final RxList<ReturnRequest> returnRequests = <ReturnRequest>[].obs;
  final RxList<CartItemModel> selectedItems = <CartItemModel>[].obs;
  final Rx<ReturnType> selectedReturnType = ReturnType.returnForRefund.obs;
  final Rx<ReturnReason> selectedReason = ReturnReason.other.obs;
  final RxString customDescription = ''.obs;
  final RxBool isLoading = false.obs;

  /// Talebe eklenen görsel bağlantıları.
  ///
  /// ⚠️ Uygulamada **görsel seçici yok**: ne referansta ne de bu projede bir
  /// `image_picker`/`file_picker` paketi var ve KURALLAR §6 yeni paket
  /// eklemeyi yasaklıyor. Model (`ReturnRequest.photoUrls`) ve detay ekranı
  /// görselleri zaten destekliyor, bu yüzden kanıt görselleri **bağlantı
  /// olarak** eklenir. Paket izni gelirse yalnız bu listeyi dolduran widget
  /// değişir.
  final RxList<String> photoUrls = <String>[].obs;

  /// Talebi sipariş verisiyle başlatır.
  void initializeReturnRequest(OrderModel order) {
    returnRequest.value = ReturnRequest(
      id: const Uuid().v4(),
      orderId: order.id,
      userId: order.userId,
      userName: order.userName,
      userEmail: order.userEmail,
      userPhone: order.shippingAddress.phoneNumber,
      requestDate: DateTime.now(),
      returnType: selectedReturnType.value,
      status: ReturnStatus.requested,
      reason: selectedReason.value,
      description: customDescription.value,
      photoUrls: photoUrls,
      returnItems: selectedItems,
    );
  }

  /// Kalemi iade listesine ekler / listeden çıkarır.
  void toggleItemSelection(CartItemModel item) {
    if (selectedItems.any((selectedItem) => selectedItem.productId == item.productId)) {
      selectedItems.removeWhere((selectedItem) => selectedItem.productId == item.productId);
    } else {
      selectedItems.add(item);
    }
    update();
  }

  /// Görsel bağlantısı ekler. Aynı bağlantı iki kez eklenmez.
  void addPhotoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || photoUrls.contains(trimmed)) return;
    photoUrls.add(trimmed);
  }

  void removePhotoUrl(String url) => photoUrls.remove(url);

  /// Talebi gönderir.
  Future<void> submitReturnRequest() async {
    try {
      if (selectedItems.isEmpty) {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.returnSelectItemError.tr);
        return;
      }

      if (customDescription.value.isEmpty) {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.returnDescriptionError.tr);
        return;
      }

      TFullScreenLoader.openLoadingDialog(TTexts.processingYourOrder.tr, TImages.pencilAnimation);

      // Nihai talep — ekrandaki seçimlerin son hâliyle kurulur.
      final ReturnRequest finalRequest = ReturnRequest(
        id: returnRequest.value.id,
        orderId: returnRequest.value.orderId,
        userId: returnRequest.value.userId,
        userName: returnRequest.value.userName,
        userEmail: returnRequest.value.userEmail,
        userPhone: returnRequest.value.userPhone,
        requestDate: DateTime.now(),
        returnType: selectedReturnType.value,
        status: ReturnStatus.requested,
        reason: selectedReason.value,
        description: customDescription.value,
        photoUrls: photoUrls.toList(),
        returnItems: selectedItems.toList(),
      );

      await _returnRepository.addNewItem(finalRequest);

      // Formu sıfırla
      resetForm();

      TFullScreenLoader.stopLoading();

      // Başarı ekranı
      Get.off(
        () => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: TTexts.returnRequest.tr,
          subTitle: TTexts.returnRequestSubTitle.tr,
          onPressed: () => Get.offAllNamed(TRoutes.homeMenu),
        ),
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      // 🔴 Uç henüz yok: repository `UnsupportedError` fırlatıyor. Kullanıcıya
      // ham istisna değil, anlaşılır bir metin gösterilir.
      final message = e is UnsupportedError ? TTexts.returnNotSupported.tr : '${TTexts.returnSubmitFailed.tr} $e';
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: message);
    }
  }

  /// Talebi iptal eder.
  Future<void> cancelReturnRequest(String requestId) async {
    try {
      _returnRepository.updateSingleField(requestId, {
        'status': ReturnStatus.canceled.name,
        'rejectedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      TLoaders.successSnackBar(title: TTexts.success.tr, message: TTexts.returnRequestCancelled.tr);

      Get.offAllNamed(TRoutes.homeMenu);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: '${TTexts.returnCancelFailed.tr} $e');
    }
  }

  void resetForm() {
    selectedItems.clear();
    photoUrls.clear();
    selectedReturnType.value = ReturnType.returnForRefund;
    selectedReason.value = ReturnReason.other;
    customDescription.value = '';
    returnRequest.value = ReturnRequest.empty();
  }

  /// Kullanıcının taleplerini akış olarak verir.
  Stream<List<ReturnRequest>> getUserReturnRequests(String userId) {
    return _returnRepository.getReturnRequestsStream().map((allRequests) {
      return allRequests.where((request) => request.userId == userId).toList();
    });
  }

  /// Tek talebi kimliğiyle getirir.
  Future<ReturnRequest?> getReturnRequestById(String requestId) async {
    try {
      return await _returnRepository.getSingleItem(requestId);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.returnLoadFailed.tr);
      return null;
    }
  }

  /// Kullanıcının iade talepleri.
  Future<List<ReturnRequest>> getUserReturnsRequest() async {
    try {
      final allUserRequests =
          await _returnRepository.getReturnRequestsByUserId(AuthenticationRepository.instance.getUserID);
      return allUserRequests;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: TTexts.returnLoadFailed.tr);
      return [];
    }
  }

  @override
  void dispose() {
    returnRequests.close();
    selectedItems.close();
    photoUrls.close();
    selectedReturnType.close();
    selectedReason.close();
    customDescription.close();
    isLoading.close();
    super.dispose();
  }
}
