/// Siparişin teslimat ve fatura adresleri.
///
/// Adres sunucudan üç ayrı yoldan gelebiliyor ve ekran üçünü de dener:
///   1. siparişin içindeki adres nesnesi / snapshot'ı,
///   2. yalnız kimlik geldiyse `GET /Address/{id}`,
///   3. **şirket hesabında** fatura adresi 1C'den (`GET /company/{iin}`) —
///      o adresin veritabanında kimliği yoktur (FAZ 07 kararı).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../../data/repositories/address/api_address_repository.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../../utils/helpers/helper_functions.dart';
import '../../../../../personalization/controllers/address_controller.dart';
import '../../../../../personalization/controllers/user_controller.dart';
import '../../../../../personalization/models/address_model.dart';
import '../../../../models/order_model.dart';
import 'heading_with_icon.dart';

class OrderAddresses extends StatefulWidget {
  const OrderAddresses({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderAddresses> createState() => _OrderAddressesState();
}

class _OrderAddressesState extends State<OrderAddresses> {
  AddressModel? _shippingAddress;
  AddressModel? _billingAddress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final repo = ApiAddressRepository.instance;

    // ── Teslimat ────────────────────────────────────────────────────────────
    AddressModel? shipping;
    // Sipariş adresi doluysa ek istek atılmaz.
    if (widget.order.shippingAddress.street.isNotEmpty || widget.order.shippingAddress.city.isNotEmpty) {
      shipping = widget.order.shippingAddress;
    } else if (widget.order.shippingAddressId.isNotEmpty) {
      // Sunucu yalnız kimliği gönderdi — tam adresi çek.
      try {
        shipping = await repo.fetchSingleAddress(widget.order.shippingAddressId);
      } catch (_) {
        // Adres okunamadı: bölüm "—" gösterir, ekran çökmez.
      }
    }

    // ── Fatura ──────────────────────────────────────────────────────────────
    AddressModel? billing;
    final user = Get.find<UserController>().user.value;

    if (user.isCorporate && user.iin.trim().isNotEmpty) {
      // Şirket hesabı: önce ödeme ekranının okuduğu değer, sonra 1C.
      if (Get.isRegistered<AddressController>()) {
        final cached = AddressController.instance.selectedBillingAddress.value;
        if (cached.id.isNotEmpty || cached.company.isNotEmpty) {
          billing = cached;
        }
      }
      if (billing == null) {
        try {
          billing = await repo.fetchCompanyBillingAddress(user.iin.trim());
        } catch (_) {}
      }
    } else if (!widget.order.billingAddressSameAsShipping) {
      // Fatura adresi teslimattan farklı — siparişten ya da uçtan oku.
      final bid = widget.order.billingAddressId;
      final existing = widget.order.billingAddress;
      if (existing != null && (existing.street.isNotEmpty || existing.city.isNotEmpty)) {
        billing = existing;
      } else if (bid.isNotEmpty && bid != widget.order.shippingAddressId) {
        try {
          billing = await repo.fetchSingleAddress(bid);
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _shippingAddress = shipping;
        _billingAddress = billing;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    if (_loading) {
      return TRoundedContainer(
        showBorder: true,
        radius: TSizes.cardRadiusMd,
        backgroundColor: dark ? TColors.darkContainer : TColors.white,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(TSizes.md),
            child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2),
          ),
        ),
      );
    }

    return TRoundedContainer(
      showBorder: true,
      radius: TSizes.cardRadiusMd,
      backgroundColor: dark ? TColors.darkContainer : TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Teslimat ──────────────────────────────────────────────────────
          THeadingWithIcon(title: TTexts.shippingAddress.tr, icon: Iconsax.location_tick),
          const SizedBox(height: TSizes.spaceBtwItems),
          _shippingAddress != null
              ? _AddressBlock(
                  address: _shippingAddress!,
                  fallbackName: widget.order.userName,
                  fallbackEmail: widget.order.userEmail,
                )
              : Text('—', style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: TSizes.spaceBtwItems),
          const Divider(height: TSizes.dividerHeight),
          const SizedBox(height: TSizes.spaceBtwItems),

          // ── Fatura ────────────────────────────────────────────────────────
          THeadingWithIcon(title: TTexts.billingAddress.tr, icon: Iconsax.location),
          const SizedBox(height: TSizes.spaceBtwItems),
          _billingAddress != null
              ? _AddressBlock(address: _billingAddress!)
              : Text(
                  TTexts.billingAddressSubTitle.tr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
                ),
        ],
      ),
    );
  }
}

/// Tek adres bloğu: yalnız DOLU alanlar yazılır.
class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address, this.fallbackName = '', this.fallbackEmail = ''});

  final AddressModel address;
  final String fallbackName;
  final String fallbackEmail;

  @override
  Widget build(BuildContext context) {
    final company = address.company;
    final name = address.name.isNotEmpty ? address.name : fallbackName;
    final email = address.email.isNotEmpty ? address.email : fallbackEmail;
    final phone = address.phoneNumber;

    // Adres satırı elde olan parçalardan kurulur; boş parça araya virgül koymaz.
    final lineParts = <String>[
      if (address.street.isNotEmpty) address.street,
      if (address.addressLine2.isNotEmpty) address.addressLine2,
      if (address.neighborhood.isNotEmpty) address.neighborhood,
      if (address.district.isNotEmpty) address.district,
      if (address.city.isNotEmpty) address.city,
      if (address.postalCode.isNotEmpty) address.postalCode,
      if (address.country.isNotEmpty) address.country,
    ];
    final addressLine = lineParts.join(', ');

    final hasContent = company.isNotEmpty || name.isNotEmpty || addressLine.isNotEmpty;
    if (!hasContent) return Text('—', style: Theme.of(context).textTheme.bodyLarge);

    return Column(
      children: [
        if (company.isNotEmpty) _row(TTexts.company.tr, company, context),
        if (name.isNotEmpty) _row(TTexts.name.tr, name, context),
        if (email.isNotEmpty) _row(TTexts.email.tr, email, context),
        if (phone.isNotEmpty) _row(TTexts.phoneNo.tr, phone, context),
        if (addressLine.isNotEmpty) _row(TTexts.address.tr, addressLine, context),
      ],
    );
  }

  Widget _row(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
