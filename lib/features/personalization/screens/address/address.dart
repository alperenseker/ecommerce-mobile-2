/// Adres defteri.
///
/// İki bölüm var:
///   1. **Ödemede kullanılacak** teslimat ve fatura adresi (referansın ekranı),
///   2. **Kayıtlı adreslerin tamamı** — satır başına düzenle · sil ·
///      varsayılan yap. Fazın "liste, silme, varsayılan yapma" maddesi bunu
///      istiyor; referansta yalnız birinci bölüm vardı.
///
/// 🔴 **Şirket hesabında fatura adresi düzenlenemez** (FAZ 07 ile aynı kural):
/// o adres 1C'nin resmî adresi (`GET /company/{iin}`), veritabanında satırı
/// yok. Kilitli ve sade çizilir, "düzenle" bağlantısı **hiç konmaz**.
///
/// ⚠️ Ekran tek bir çağrı yapar: `AddressController.fetchAddressBook()` hem
/// listeyi döndürür hem varsayılanları çözer. İki ayrı çağrı aynı ucu iki kez
/// vurup başlıkla listenin farklı anlarda gelmesine yol açıyordu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/address_controller.dart';
import '../../models/address_model.dart';
import 'update_address.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        showBackArrow: true,
        showSkipButton: false,
        showActions: false,
        title: Text(TTexts.addresses.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Obx(() {
        final refreshKey = controller.refreshData.value;
        return FutureBuilder<List<AddressModel>>(
          key: ValueKey(refreshKey),
          future: controller.fetchAddressBook(),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const TDelayedLoader();
            }

            final all = snapshot.data ?? const <AddressModel>[];
            final shipping = controller.selectedAddress.value;
            final billing = controller.selectedBillingAddress.value;
            final isCorporate = controller.isCorporate;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                TSizes.defaultSpace,
                TSizes.md,
                TSizes.defaultSpace,
                // Yüzen "yeni adres" düğmesi son kartı örtmesin.
                MediaQuery.paddingOf(context).bottom + TSizes.spaceBtwSections * 2,
              ),
              children: [
                Text(
                  TTexts.addressBookHint.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// -- Ödemede kullanılan iki adres
                _AddressSection(
                  title: TTexts.shippingAddress.tr,
                  icon: Iconsax.truck,
                  address: shipping,
                  editable: true,
                  minimal: false,
                  onEdit: () => Get.to(() => UpdateAddressScreen(address: shipping)),
                ),

                /// Fatura adresi — şirkette kilitli ve sade, bireyselde tam
                _AddressSection(
                  title: TTexts.billingAddress.tr,
                  icon: Iconsax.receipt_item,
                  address: billing,
                  editable: !isCorporate,
                  minimal: isCorporate,
                  locked: isCorporate,
                  onEdit: () => Get.to(() => UpdateAddressScreen(address: billing)),
                ),

                /// -- Kayıtlı adreslerin tamamı
                const SizedBox(height: TSizes.sm),
                Padding(
                  padding: const EdgeInsets.only(left: TSizes.xs, bottom: TSizes.sm),
                  child: Text(
                    TTexts.savedAddresses.tr,
                    style: Theme.of(context).textTheme.labelMedium!
                        .apply(color: TColors.darkGrey, fontWeightDelta: 1)
                        .copyWith(letterSpacing: 0.4),
                  ),
                ),
                if (all.isEmpty)
                  TEmptyState(
                    icon: Iconsax.location,
                    title: TTexts.noSavedAddresses.tr,
                    actionText: TTexts.addNewAddress.tr,
                    onAction: () => Get.toNamed(TRoutes.addNewAddress),
                  )
                else
                  ...all.map(
                    (address) => _SavedAddressCard(
                      address: address,
                      isDefault: address.id == shipping.id,
                      controller: controller,
                    ),
                  ),
              ],
            );
          },
        );
      }),

      /// Yeni adres ekle
      //
      /// 🔴 Yuvarlak "+" değil ETİKETLİ düğme: yalnız artı işareti bu ekranda
      /// "neyi ekliyorum" sorusunu bırakıyordu.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TColors.primary,
        foregroundColor: TColors.white,
        onPressed: () => Get.toNamed(TRoutes.addNewAddress),
        icon: const Icon(Iconsax.add),
        label: Text(TTexts.addNewAddress.tr),
      ),
    );
  }
}

/// Ödemede kullanılacak adresin kartı: başlık şeridi + "etiket / değer"
/// blokları + düzenle bağlantısı.
///
/// 🔴 Eskiden başlık, `Divider` ve 110px sabit etiket sütunlu satırlardan
/// oluşuyordu; uzun çevirilerde (Rusça) etiket sütunu sarıyor, değerler
/// birbirinden kopuyordu. Artık etiket değerin ÜSTÜNDE küçük ve soluk
/// duruyor, değer tam genişlikte.
class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.title,
    required this.icon,
    required this.address,
    required this.editable,
    required this.minimal,
    required this.onEdit,
    this.locked = false,
  });

  final String title;
  final IconData icon;
  final AddressModel address;

  /// "Düzenle" bağlantısı çizilsin mi (şirket faturası kilitli).
  final bool editable;

  /// Şirket faturasında yalnız adres satırı gösterilir, kişisel alanlar değil.
  final bool minimal;

  /// Kilidin sebebini açıklayan not çizilsin mi.
  final bool locked;

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.id.isNotEmpty;
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: dark ? TColors.darkBorder : TColors.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Başlık şeridi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 2),
            color: dark ? TColors.darkAccent : TColors.accent,
            child: Row(
              children: [
                Icon(icon, size: 18, color: TColors.primary),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (locked) const Icon(Iconsax.lock, size: 14, color: TColors.darkGrey),
                if (editable && hasAddress)
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            TTexts.editAddress.tr,
                            style: Theme.of(context).textTheme.labelLarge!.apply(
                              color: TColors.primary,
                            ),
                          ),
                          const SizedBox(width: TSizes.xs),
                          const Icon(Iconsax.arrow_right_3, size: 14, color: TColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// -- Gövde
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locked) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.info_circle, size: TSizes.iconXs, color: TColors.darkGrey),
                      const SizedBox(width: TSizes.xs),
                      Expanded(
                        child: Text(
                          TTexts.companyBillingLocked.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.md),
                ],

                if (!hasAddress)
                  Text(TTexts.selectAddress.tr, style: Theme.of(context).textTheme.bodyMedium)
                else if (minimal) ...[
                  if (address.company.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelCompany.tr, value: address.company),
                  if (address.name.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelDirector.tr, value: address.name),
                  _DetailRow(label: TTexts.addressLabelAddress.tr, value: _addressLine(address)),
                ] else ...[
                  _DetailRow(label: TTexts.addressLabelName.tr, value: address.name),
                  if (address.company.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelCompany.tr, value: address.company),
                  if (address.city.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelCity.tr, value: address.city),
                  if (address.country.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelCountry.tr, value: address.country),
                  if (address.postalCode.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelPostcode.tr, value: address.postalCode),
                  if (address.phoneNumber.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelPhone.tr, value: address.formattedPhoneNo),
                  _DetailRow(label: TTexts.addressLabelAddress.tr, value: _addressLine(address)),
                  if (address.addressLine2.isNotEmpty)
                    _DetailRow(label: TTexts.addressLabelAddress2.tr, value: address.addressLine2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _addressLine(AddressModel a) => a.street.isNotEmpty ? a.street : a.toString();
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiket sabit genişlikte bir sütun DEĞİL, değerin üstünde: uzun
          // çevirilerde (Rusça) sütun sarıyor ve değerler birbirinden
          // kopuyordu.
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.darkGrey),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Kayıtlı adres kartı: konum ikonu · ad · varsayılan rozeti · eylemler.
///
/// 🔴 Kart artık iki katmanlı: üstte kimlik (ikon + ad + rozet), altta ince
/// çizgiyle ayrılmış eylem şeridi. Eskiden eylemler gövdeye yapışıktı ve
/// "düzenle / varsayılan yap / sil" üçlüsü adresin devamı gibi okunuyordu.
class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.isDefault,
    required this.controller,
  });

  final AddressModel address;
  final bool isDefault;
  final AddressController controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 1.5),
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        // TASARIM.md §6: varsayılan hâl indigo çerçeveyle işaretleniyor.
        border: Border.all(
          color: isDefault
              ? TColors.primary
              : (dark ? TColors.darkBorder : TColors.borderSecondary),
          width: isDefault ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? TColors.darkAccent : TColors.accent,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                  ),
                  child: const Icon(Iconsax.location, size: 18, color: TColors.primary),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TColors.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                TTexts.defaultAddress.tr,
                                style: Theme.of(context).textTheme.labelMedium!.apply(
                                  color: TColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (address.phoneNumber.isNotEmpty)
                        Text(
                          address.formattedPhoneNo,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        address.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: dark ? TColors.darkBorder : TColors.borderSecondary,
          ),

          /// -- Eylem şeridi
          //
          // 🔴 Düğmeler `Wrap` içinde: FAZ 06'da bulunan kusur — birincil düğme
          // teması `minimumSize: Size(double.infinity, …)` verdiği için `Row`
          // içindeki düğme çizimde patlıyor. Buradakiler `TextButton` ve
          // taşma olmasın diye alt satıra sarılıyorlar.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
            child: Wrap(
              spacing: TSizes.sm,
              children: [
                TextButton.icon(
                  onPressed: () => Get.to(() => UpdateAddressScreen(address: address)),
                  icon: const Icon(Iconsax.edit, size: TSizes.iconSm),
                  label: Text(TTexts.edit.tr),
                ),
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () => controller.makeDefault(address),
                    icon: const Icon(Iconsax.tick_circle, size: TSizes.iconSm),
                    label: Text(TTexts.setAsDefault.tr),
                  ),
                TextButton.icon(
                  onPressed: () => controller.deleteAddressWarningPopup(address),
                  icon: const Icon(Iconsax.trash, size: TSizes.iconSm, color: TColors.error),
                  label: Text(TTexts.delete.tr, style: const TextStyle(color: TColors.error)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
