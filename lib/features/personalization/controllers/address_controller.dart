/// Adres defteri: kullanıcının adreslerini okur, ödeme ekranında seçilen
/// teslimat/fatura adresini tutar, yeni adres ekler ve günceller.
///
/// 🔴 **Şirket hesabında fatura adresi 1C'den gelir ve düzenlenemez.**
/// [loadDefaultAddresses] şirket hesabında fatura adresini
/// `GET /company/{iin}` ucundan çeker; adres defterinden değil. Sunucuya
/// sipariş oluştururken fatura adresi olarak **teslimat adresinin kimliği**
/// gönderilir (bkz. `OrderController.processOrder`), çünkü 1C adresinin
/// veritabanında bir kimliği yok.
///
/// ⚠️ Bu dosya aslında FAZ 09'un (Hesap) kapsamında; ödeme ekranı onsuz
/// çalışamadığı için FAZ 07'de erken getirildi. FAZ 09 adres defteri
/// ekranını (`screens/address/address.dart`) ekleyecek — bu controller'ı
/// yeniden yazmasın.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iconsax/iconsax.dart';

import '../../../common/widgets/texts/section_heading.dart';
import '../../../data/repositories/address/api_address_repository.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/cloud_helper_functions.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/dialogs.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../models/address_model.dart';
import '../screens/address/add_new_address.dart';
import '../screens/address/widgets/single_address_widget.dart';
import 'user_controller.dart';

class AddressController extends GetxController {
  static AddressController get instance => Get.find();

  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final street = TextEditingController();
  final addressLine2 = TextEditingController();
  final postalCode = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final country = TextEditingController();
  GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();

  RxBool refreshData = true.obs;
  final addressRepository = ApiAddressRepository.instance;
  final Rx<bool> billingSameAsShipping = true.obs;
  final Rx<AddressModel> selectedAddress = AddressModel.empty().obs;
  final Rx<AddressModel> selectedBillingAddress = AddressModel.empty().obs;

  /// Kullanıcının bütün adreslerini getirir ve varsayılanı seçer.
  Future<List<AddressModel>> allUserAddresses() async {
    try {
      final addresses = await addressRepository.fetchUserAddresses(AuthenticationRepository.instance.getUserID);
      selectedAddress.value = addresses.firstWhere((element) => element.selectedAddress, orElse: () => AddressModel.empty());
      return addresses;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.addressNotFound.tr, message: e.toString());
      return [];
    }
  }

  /// Hesap şirket hesabı mı. Şirket hesabı fatura adresini düzenleyemez
  /// (resmî adres 1C'nin).
  bool get isCorporate => UserController.instance.user.value.isCorporate;

  /// Teslimat ve fatura adresini birlikte çözer (web `App.address.pair()`).
  ///
  /// Sunucu geçmişteki adres satırlarını da döndürüyor; ekranda her tipin
  /// **en son eklenen aktif** olanı gösterilir.
  Future<void> loadDefaultAddresses() async {
    try {
      final addresses = await addressRepository.fetchUserAddresses(AuthenticationRepository.instance.getUserID);
      await _resolveDefaults(addresses);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.addressNotFound.tr, message: e.toString());
    }
  }

  /// FAZ 09 — adres defteri ekranının tek çağrısı.
  ///
  /// Hem **bütün aktif adresleri** döndürür hem de varsayılan teslimat/fatura
  /// adreslerini çözer. Ayrı ayrı `allUserAddresses()` + `loadDefaultAddresses()`
  /// çağırmak aynı ucu iki kez vurup listeyle başlığın farklı anlarda
  /// gelmesine yol açıyordu.
  Future<List<AddressModel>> fetchAddressBook() async {
    try {
      final addresses = await addressRepository.fetchUserAddresses(AuthenticationRepository.instance.getUserID);
      await _resolveDefaults(addresses);
      // Silinmiş (soft delete) satırlar defterde görünmez.
      return addresses.where((a) => a.isActive).toList();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.addressNotFound.tr, message: e.toString());
      return [];
    }
  }

  /// Gelen adres listesinden teslimat ve fatura varsayılanlarını seçer.
  Future<void> _resolveDefaults(List<AddressModel> addresses) async {
    // Teslimat: önce kullanıcının işaretlediği varsayılan, yoksa en son
    // eklenen aktif teslimat adresi. (Referans yalnız ikinciye bakıyordu;
    // "varsayılan yap" düğmesine basan müşteri seçiminin tutmasını bekler.)
    final markedDefault = addresses.where((a) => a.selectedAddress && a.isActive).toList();
    selectedAddress.value = markedDefault.isNotEmpty
        ? markedDefault.first
        : (_latestActiveOfType(addresses, 'shipping') ?? AddressModel.empty());

    final user = UserController.instance.user.value;
    if (user.isCorporate && user.iin.trim().isNotEmpty) {
      // 🔴 Şirket faturası = 1C'deki resmî adres (`/company/{iin}`), kilitli.
      final companyAddress = await addressRepository.fetchCompanyBillingAddress(user.iin.trim());
      selectedBillingAddress.value = companyAddress ?? AddressModel.empty();
    } else {
      // Bireysel fatura = adres defterindeki en son aktif `billing` satırı.
      selectedBillingAddress.value = _latestActiveOfType(addresses, 'billing') ?? AddressModel.empty();
    }
  }

  /// [type] ('shipping' | 'billing') tipindeki en son eklenen aktif adres.
  AddressModel? _latestActiveOfType(List<AddressModel> addresses, String type) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final filtered = addresses
        .where((a) => a.isActive && a.addressType.toLowerCase() == type.toLowerCase())
        .toList()
      ..sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
    return filtered.isEmpty ? null : filtered.first;
  }

  Future selectAddress({required AddressModel newSelectedAddress, bool isBillingAddress = false}) async {
    try {
      // Teslimat mı fatura mı seçiliyor
      if (!isBillingAddress) {
        newSelectedAddress.selectedAddress = true;
        selectedAddress.value = newSelectedAddress;

        // Varsayılanı sunucu işaretler; öncekinin işaretini de o kaldırır.
        await addressRepository.setDefaultAddress(selectedAddress.value.id);
      } else {
        selectedBillingAddress.value = newSelectedAddress;
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.errorInSelection.tr, message: e.toString());
    }
  }

  /// Yeni adres ekle
  addNewAddresses() async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.errorInSelection.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!addressFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final address = AddressModel(
        id: '',
        name: name.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        street: street.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        postalCode: postalCode.text.trim(),
        country: country.text.trim(),
        selectedAddress: true,
      );
      final created = await addressRepository.createAddress(address);

      // Seçili adres durumunu güncelle
      address.id = created.id;
      await selectAddress(newSelectedAddress: address);

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.addressSaveSuccess.tr);

      refreshData.toggle();
      resetFormFields();

      Navigator.of(Get.context!).pop();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.addressNotFound.tr, message: e.toString());
    }
  }

  /// Ödeme ekranındaki adres seçme alt sayfası.
  Future<dynamic> selectNewAddressPopup({required BuildContext context, bool isBillingAddress = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(TSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TSectionHeading(title: TTexts.selectAddress.tr, showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),
              FutureBuilder(
                future: allUserAddresses(),
                builder: (_, snapshot) {
                  /// Yükleniyor / kayıt yok / hata durumlarını tek yerden çizer
                  final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot);
                  if (response != null) return response;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) => TSingleAddress(
                      address: snapshot.data![index],
                      isBillingAddress: isBillingAddress,
                      onTap: () async {
                        await selectAddress(newSelectedAddress: snapshot.data![index], isBillingAddress: isBillingAddress);
                        Get.back();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: TSizes.defaultSpace),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const AddNewAddressScreen()),
                  child: Text(TTexts.addNewAddress.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Güncelleme formunu var olan adresle doldurur
  initUpdateAddressValues(AddressModel address) {
    name.text = address.name;
    phoneNumber.text = address.phoneNumber;
    street.text = address.street;
    addressLine2.text = address.addressLine2;
    postalCode.text = address.postalCode;
    city.text = address.city;
    state.text = address.state;
    country.text = address.country;
  }

  /// Adres güncelle
  updateAddress(AddressModel oldAddress) async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.updatingAddress.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!addressFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Sunucu ad/soyadı ayrık tutuyor; ekranda tek alan var, çeviri burada.
      final nameParts = name.text.trim().split(RegExp(r'\s+'));
      final address = AddressModel(
        id: oldAddress.id,
        name: name.text.trim(),
        firstName: nameParts.isNotEmpty ? nameParts.first : '',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        phoneNumber: phoneNumber.text.trim(),
        street: street.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        postalCode: postalCode.text.trim(),
        country: country.text.trim(),
        selectedAddress: oldAddress.selectedAddress,
        addressLine2: addressLine2.text.trim(),
        // Formda düzenlenmeyen alanlar korunur — aksi hâlde sunucudaki
        // değerler boşla ezilirdi.
        addressType: oldAddress.addressType,
        email: oldAddress.email,
        company: oldAddress.company,
        district: oldAddress.district,
        neighborhood: oldAddress.neighborhood,
      );

      await addressRepository.updateAddress(address);

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.addressUpdated.tr);

      refreshData.toggle();
      resetFormFields();

      Navigator.of(Get.context!).pop();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.errorUpdatedAddress.tr, message: e.toString());
    }
  }

  /// FAZ 09 — adresi siler (sunucuda soft delete).
  ///
  /// Silinen adres seçili teslimat adresiyse seçim temizlenir; ödeme ekranı
  /// artık var olmayan bir adresle sipariş göndermesin.
  Future<void> deleteAddress(AddressModel address) async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processingRequest.tr, TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await addressRepository.deleteAddress(address.id);

      if (selectedAddress.value.id == address.id) selectedAddress.value = AddressModel.empty();
      if (selectedBillingAddress.value.id == address.id) selectedBillingAddress.value = AddressModel.empty();

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(title: TTexts.congratulation.tr, message: TTexts.addressDeleted.tr);

      refreshData.toggle();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.addressDeleteFailed.tr, message: e.toString());
    }
  }

  /// FAZ 09 — silmeden önce onay sorar. Adres silme geri alınamıyor.
  void deleteAddressWarningPopup(AddressModel address) {
    TDialogs.confirm(
      title: TTexts.deleteAddress.tr,
      message: TTexts.deleteAddressMessage.tr,
      icon: Iconsax.trash,
      isDestructive: true,
      confirmText: TTexts.delete.tr,
      // Diyalog kendini kapatıyor; burada Get.back() çağrılmaz.
      onConfirm: () => deleteAddress(address),
    );
  }

  /// FAZ 09 — adresi varsayılan yapar ve listeyi tazeler.
  ///
  /// Varsayılanı **sunucu** işaretliyor (`address/{id}/set-default`);
  /// öncekinin işaretini de o kaldırıyor, istemci tek tek güncellemiyor.
  Future<void> makeDefault(AddressModel address) async {
    await selectAddress(newSelectedAddress: address);
    refreshData.toggle();
  }

  /// Form alanlarını temizler
  void resetFormFields() {
    name.clear();
    phoneNumber.clear();
    street.clear();
    addressLine2.clear();
    postalCode.clear();
    city.clear();
    state.clear();
    country.clear();
    addressFormKey.currentState?.reset();
  }
}
