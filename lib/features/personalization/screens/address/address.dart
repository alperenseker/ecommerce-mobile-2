/// Adres defteri.
///
/// İki bölümden oluşur:
///  1. **Ödemede kullanılacak adresler** — teslimat ve fatura (web
///     `App.address.pair()` karşılığı).
///  2. **Kayıtlı adresler** — tüm aktif adresler; her satırda düzenle, sil ve
///     "varsayılan yap".
///
/// 🔴 Şirket hesabında **fatura adresi düzenlenemez**: resmî adres 1C'den
/// (`GET /company/{iin}`) geliyor, veritabanında karşılığı yok. FAZ 07'deki
/// ödeme ekranıyla aynı kural.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/loaders/circular_loader.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/address_controller.dart';
import '../../models/address_model.dart';
import 'update_address.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());

    // 🔴 Misafirin adres defteri "boş" değil YOKTUR; uç zaten 401 döner.
    if (AuthenticationRepository.instance.isGuestUser) {
      return Scaffold(
        appBar: TAppBar(
          showBackArrow: true,
          showSkipButton: false,
          showActions: false,
          title: Text(TTexts.addresses.tr, style: Theme.of(context).textTheme.headlineSmall),
        ),
        body: TEmptyState.signInRequired(message: TTexts.addressesSubTitle.tr),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showSkipButton: false,
        showActions: false,
        title: Text(TTexts.addresses.tr, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Obx(() {
        // Ekleme/silme/varsayılan değişince bu anahtar değişir ve liste
        // yeniden çekilir.
        final refreshKey = controller.refreshData.value;
        return FutureBuilder<List<AddressModel>>(
          key: ValueKey(refreshKey),
          future: controller.fetchAddressBook(),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: TCircularLoader());
            }

            final all = snapshot.data ?? [];
            final shipping = controller.selectedAddress.value;
            final billing = controller.selectedBillingAddress.value;
            final isCorporate = controller.isCorporate;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TTexts.addressesSubTitle.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Teslimat adresi (daima düzenlenebilir)
                  _AddressSection(
                    title: TTexts.shippingAddress.tr,
                    address: shipping,
                    editable: true,
                    minimal: false,
                    onEdit: () => Get.to(() => UpdateAddressScreen(address: shipping)),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Fatura adresi — şirkette kilitli ve sade, bireyselde tam
                  _AddressSection(
                    title: TTexts.billingAddress.tr,
                    address: billing,
                    editable: !isCorporate,
                    minimal: isCorporate,
                    onEdit: () => Get.to(() => UpdateAddressScreen(address: billing)),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Kayıtlı adreslerin tamamı
                  TSectionHeading(title: TTexts.savedAddresses.tr, showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  if (all.isEmpty)
                    TRoundedContainer(
                      width: double.infinity,
                      showBorder: true,
                      radius: TSizes.cardRadiusMd,
                      backgroundColor: Colors.transparent,
                      borderColor: TColors.borderSecondary,
                      child: Text(
                        TTexts.noAddressYetMessage.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                      ),
                    )
                  else
                    ...all.map((address) => _AddressBookRow(address: address, controller: controller)),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),
                ],
              ),
            );
          },
        );
      }),

      /// -- Yeni adres ekle
      floatingActionButton: FloatingActionButton(
        backgroundColor: TColors.primary,
        onPressed: () => Get.toNamed(TRoutes.addNewAddress),
        child: const Icon(Iconsax.add, color: TColors.white),
      ),
    );
  }
}

/// "Etiket: değer" biçiminde tek adres bloğu (web hesabım sayfasıyla aynı dil).
class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.title,
    required this.address,
    required this.editable,
    required this.minimal,
    required this.onEdit,
  });

  final String title;
  final AddressModel address;

  /// Düzenle bağlantısı çizilsin mi (şirket faturası kilitli).
  final bool editable;

  /// Şirket faturasında yalnız resmî bilgiler gösterilir, kişisel alanlar yok.
  final bool minimal;

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.id.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(title: title, showActionButton: false),
        const Divider(),
        const SizedBox(height: TSizes.spaceBtwItems),

        if (!hasAddress)
          Text(
            TTexts.selectAddress.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          )
        else if (minimal) ...[
          if (address.company.isNotEmpty) _DetailRow(label: TTexts.company.tr, value: address.company),
          if (address.name.isNotEmpty) _DetailRow(label: TTexts.director.tr, value: address.name),
          _DetailRow(label: TTexts.address.tr, value: _addressLine(address)),
          const SizedBox(height: TSizes.sm),
          Text(
            TTexts.companyBillingLocked.tr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.textSecondary),
          ),
        ] else ...[
          _DetailRow(label: TTexts.name.tr, value: address.name),
          if (address.company.isNotEmpty) _DetailRow(label: TTexts.company.tr, value: address.company),
          if (address.city.isNotEmpty) _DetailRow(label: TTexts.city.tr, value: address.city),
          if (address.country.isNotEmpty) _DetailRow(label: TTexts.country.tr, value: address.country),
          if (address.postalCode.isNotEmpty) _DetailRow(label: TTexts.postalCode.tr, value: address.postalCode),
          if (address.phoneNumber.isNotEmpty) _DetailRow(label: TTexts.phoneNo.tr, value: address.formattedPhoneNo),
          _DetailRow(label: TTexts.address.tr, value: _addressLine(address)),
          if (address.addressLine2.isNotEmpty)
            _DetailRow(label: TTexts.addressLine2.tr, value: address.addressLine2),
        ],

        if (editable && hasAddress) ...[
          const SizedBox(height: TSizes.spaceBtwItems),
          InkWell(
            onTap: onEdit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TASARIM.md §1: büyük harf yığını yok — düz cümle bağlantı.
                Text(
                  TTexts.editAddress.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: TColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: TSizes.sm),
                const Icon(Icons.arrow_forward, color: TColors.primary, size: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _addressLine(AddressModel a) => a.street.isNotEmpty ? a.street : a.toString();
}

/// Kayıtlı adres listesinin tek satırı: özet + düzenle / sil / varsayılan yap.
class _AddressBookRow extends StatelessWidget {
  const _AddressBookRow({required this.address, required this.controller});

  final AddressModel address;
  final AddressController controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isDefault = controller.selectedAddress.value.id == address.id;

    return TRoundedContainer(
      width: double.infinity,
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.md),
      // TASARIM.md §6: seçili hâl `accent` zemin + indigo çerçeve.
      backgroundColor: isDefault
          ? (dark ? TColors.darkAccent : TColors.accent)
          : (dark ? TColors.darkSurface : TColors.white),
      borderColor: isDefault ? TColors.primary : TColors.borderSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.name.isNotEmpty ? address.name : address.street,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDefault)
                TRoundedContainer(
                  radius: 100,
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 2),
                  backgroundColor: TColors.primary,
                  child: Text(
                    TTexts.defaultAddress.tr,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TSizes.xs),
          if (address.phoneNumber.isNotEmpty)
            Text(
              address.formattedPhoneNo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
            ),
          const SizedBox(height: TSizes.xs),
          Text(
            address.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              // Zaten varsayılan olan adres için düğme çizilmez.
              if (!isDefault)
                TextButton.icon(
                  onPressed: () => controller.makeDefault(address),
                  icon: const Icon(Iconsax.tick_circle, size: TSizes.iconSm),
                  label: Text(TTexts.setAsDefault.tr),
                ),
              const Spacer(),
              IconButton(
                tooltip: TTexts.editAddress.tr,
                onPressed: () => Get.to(() => UpdateAddressScreen(address: address)),
                icon: const Icon(Iconsax.edit, size: TSizes.iconSm, color: TColors.darkerGrey),
              ),
              IconButton(
                tooltip: TTexts.deleteAddress.tr,
                onPressed: () => controller.deleteAddressWarningPopup(address),
                icon: const Icon(Iconsax.trash, size: TSizes.iconSm, color: TColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
