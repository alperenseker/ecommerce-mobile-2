/// Havale rekvizitleri (IBAN, BIN, BIK, KBe) — **şirket şirket**.
///
/// 🔴 NEDEN ŞİRKET BAŞINA (K29.4): `bank_details` şirketleşti ve her şirketin
/// kendi satırları var. Süzgeçsiz çağrıda 12 satır dönüyor (3 şirket × 4
/// hesap); hepsi bugün aynı IBAN'ı taşıdığı için tek düz liste yalnızca
/// çirkin görünüyor. Şirket adminleri kendi gerçek IBAN'larını girdiği anda
/// düz liste ANLAŞILMAZ olur: müşteri hangi hesaba yatıracağını bilemez. Bu
/// widget, sepetin zaten yaptığı şirket kırılımını rekvizitlere de uygular.
///
/// Web'deki `ui/bank-details.js`'in mobil karşılığıdır; orada çözülen tasarım
/// problemleri burada da aynen geçerli (şirket başına para birimi sekmesi,
/// "hesap yok" uyarısı, "okunamadı" ile "yok"un ayrılması).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../data/repositories/settings/api_bank_details_repository.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/erp_source_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/bank_detail_model.dart';

/// Rekvizit listesindeki **tek şirket bloğu**: şirket + o şirkete düşen tutar.
///
/// Ödeme ekranında her şirket için bir blok olur; sipariş detayında tek blok
/// olur, çünkü sipariş şirket başına bölünüyor.
class TBankTransferBlock {
  const TBankTransferBlock({required this.code, this.name = '', this.amount});

  /// 1C kaynağının kodu (`fores`, `foral`, `stark`).
  final String code;

  /// Sunucudan gelen ad (varsa). Yoksa [TErpSource.label] çözer.
  final String name;

  /// Bu şirkete düşen tutar. `null` ise tutar yazılmaz.
  final double? amount;

  /// 🔴 Ad çözümü **tek yerden** yapılır ([TErpSource.label]): yeni bir 1C
  /// bağlandığında `labels`'a tek satır eklemek yeter, rekvizit başlıkları da
  /// aynı yardımcıyı kullandığı için kendiliğinden düzelir.
  String get label => TErpSource.label(code, name);
}

class TBankTransferDetails extends StatefulWidget {
  const TBankTransferDetails({
    super.key,
    required this.blocks,
    this.noteKey = TTexts.bankTransferNote,
  });

  /// Gösterilecek şirketler. Boşsa widget hiç çizilmez.
  final List<TBankTransferBlock> blocks;

  /// Başlığın altındaki açıklamanın çeviri anahtarı. Kredili müşteriye
  /// bugünkü metin, genel `transfer_only` modundaki kredisiz müşteriye
  /// "ödeme banka havalesi ile alınmaktadır" metni gösterilir.
  ///
  /// **Boş dize** verilirse açıklama hiç çizilmez: `transfer_only` modunda
  /// hemen üstteki [TPaymentModeNote] zaten AYNI cümleyi yazıyor ve ekranda
  /// aynı paragraf arka arkaya iki kez görünüyordu.
  final String noteKey;

  @override
  State<TBankTransferDetails> createState() => _TBankTransferDetailsState();
}

class _TBankTransferDetailsState extends State<TBankTransferDetails> {
  /// Şirket kodu → o şirketin aktif hesapları.
  /// `null` = **okunamadı** (ağ/sunucu hatası), `{}` = okundu ama satır yok.
  Map<String, List<BankDetailModel>>? _byCompany;
  bool _loading = true;

  /// Seçili para birimi — **şirket başına**. Genel bir seçici hangi şirketin
  /// hangi para biriminde hesabı olduğunu gizlerdi.
  final Map<String, String> _activeCurrency = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TBankTransferDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sepet değişip şirket sayısı 1'den 2'ye çıktıysa süzgeç stratejisi de
    // değişir (sunucu süzsün / istemcide grupla) — yeniden yüklenir.
    if (_companyKey(oldWidget.blocks) != _companyKey(widget.blocks)) {
      _load();
    }
  }

  String _companyKey(List<TBankTransferBlock> blocks) =>
      blocks.map((b) => b.code.trim().toLowerCase()).join(',');

  Future<void> _load() async {
    final companies = _companies;
    if (companies.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() => _loading = true);

    // Tek şirketli ekranda sunucu süzsün (daha küçük yanıt); çok şirketlide
    // tek çağrı + istemcide gruplama (daha az istek).
    final filter = companies.length == 1 ? companies.first.code : null;
    // Depo GetX'e kayıtlıysa oradan alınır; değilse referanstaki gibi doğrudan
    // kurulur. Üretimde davranış aynı — kanca, testin ağa çıkmadan sahte
    // rekvizit verebilmesi için.
    final repository = Get.isRegistered<ApiBankDetailsRepository>()
        ? Get.find<ApiBankDetailsRepository>()
        : ApiBankDetailsRepository();
    final result = await repository.fetchByCompany(erpSource: filter);

    if (!mounted) return;
    setState(() {
      _byCompany = result;
      _loading = false;
      _activeCurrency.clear();
    });
  }

  /// Şirketi çözülebilen bloklar. Şirketsiz kalem için hangi hesaba
  /// yatırılacağı belirsizdir; ad uydurulmaz, blok hiç çizilmez.
  List<TBankTransferBlock> get _companies =>
      widget.blocks.where((b) => b.code.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final companies = _companies;
    if (companies.isEmpty) return const SizedBox.shrink();
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: TSizes.spaceBtwItems),
        child: Center(child: CircularProgressIndicator(color: TColors.primary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TSizes.spaceBtwItems),

        // Açıklama boşsa başlık da çizilmez: bu durumda hemen üstte
        // [TPaymentModeNote] duruyor ve o balon AYNI başlığı + AYNI cümleyi
        // zaten yazıyor. İkisi birden çizilince ekranda başlık iki kez
        // arka arkaya görünüyordu.
        if (widget.noteKey.isNotEmpty) ...[
          TSectionHeading(title: TTexts.bankTransferTitle.tr, showActionButton: false),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(widget.noteKey.tr, style: Theme.of(context).textTheme.bodySmall),
        ],

        /// Sepet birden çok şirkete bölündüyse: tek havale hepsini kapatmaz,
        /// müşteri her şirkete AYRI ödeme yapacak. Bunu ödeme öncesinde
        /// bilmezse tek havale yapıp siparişinin yarısını bekletir.
        if (companies.length > 1) ...[
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            TTexts.bankPerCompanyNote.trParams({'count': '${companies.length}'}),
            style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.primary),
          ),
        ],
        const SizedBox(height: TSizes.spaceBtwItems),

        /// 🔴 Liste okunamadı. "Hesap yok" demek YANLIŞ olurdu — bu bir ağ /
        /// sunucu hatası. Sipariş yine verilebilir, bu bölüm bilgilendirmedir.
        if (_byCompany == null)
          _notice(context, TTexts.bankLoadError.tr)
        else
          ...companies.map((block) => _companyBlock(context, block)),
      ],
    );
  }

  Widget _companyBlock(BuildContext context, TBankTransferBlock block) {
    final code = block.code.trim().toLowerCase();
    final accounts = _byCompany?[code] ?? const <BankDetailModel>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Şirket başlığı + o şirkete düşen tutar
          Row(
            children: [
              Expanded(
                child: Text(block.label, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (block.amount != null)
                Text(
                  TFormatter.formatCurrency(block.amount!),
                  style: Theme.of(context).textTheme.titleSmall!.apply(color: TColors.primary),
                ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),

          /// 🔴 Hesabı olmayan şirket SESSİZCE BOŞ BIRAKILMAZ: müşteri o
          /// şirkete nereye ödeyeceğini göremiyor demektir ve bunu bilmeli.
          if (accounts.isEmpty)
            _notice(context, TTexts.bankMissing.tr)
          else
            ..._accountsFor(context, code, accounts),
        ],
      ),
    );
  }

  List<Widget> _accountsFor(BuildContext context, String code, List<BankDetailModel> accounts) {
    // Para birimleri hesapların sırasıyla toplanır; KZT varsa öne alınır
    // (mağazanın para birimi o, müşteri önce onu arıyor).
    final currencies = <String>[];
    for (final account in accounts) {
      if (!currencies.contains(account.currencyKey)) currencies.add(account.currencyKey);
    }
    if (currencies.remove('KZT')) currencies.insert(0, 'KZT');

    final active = _activeCurrency[code] ?? currencies.first;
    final visible = accounts.where((a) => a.currencyKey == active).toList();

    return [
      /// Sekmeler ŞİRKET BAŞINA: her şirketin kendi KZT/USD/EUR seti var.
      /// Tek para birimi varsa seçici hiç çizilmez.
      if (currencies.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
          child: Wrap(
            spacing: TSizes.xs,
            children: currencies
                .map(
                  (cur) => ChoiceChip(
                    label: Text(cur == 'OTHER' ? TTexts.bankOther.tr : cur),
                    selected: cur == active,
                    // Sadece BU şirketin sekmeleri — komşu blok etkilenmez.
                    onSelected: (_) => setState(() => _activeCurrency[code] = cur),
                  ),
                )
                .toList(),
          ),
        ),
      ...visible.map((bank) => _accountCard(context, bank)),
    ];
  }

  Widget _accountCard(BuildContext context, BankDetailModel bank) {
    final dark = THelperFunctions.isDarkMode(context);
    final split = bank.nameAndCurrency;

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: TRoundedContainer(
        showBorder: true,
        radius: TSizes.borderRadiusMd,
        padding: const EdgeInsets.all(TSizes.md),
        backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(split.name, style: Theme.of(context).textTheme.titleSmall)),
                if (split.currency != null)
                  TRoundedContainer(
                    radius: TSizes.borderRadiusSm,
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs / 2),
                    backgroundColor: TColors.accent,
                    child: Text(
                      split.currency!,
                      style: Theme.of(context).textTheme.labelMedium!.apply(color: TColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /// IBAN + kopyala. Elle yazılan bir IBAN'da tek hane hata parayı
            /// başka hesaba gönderir; kopyalama düğmesi bu yüzden var.
            Row(
              children: [
                Expanded(
                  child: Text(
                    bank.iban,
                    style: Theme.of(context).textTheme.bodyMedium!.apply(fontWeightDelta: 2),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyIban(bank.iban),
                  icon: const Icon(Iconsax.copy, size: TSizes.iconSm),
                  label: Text(TTexts.bankCopy.tr),
                ),
              ],
            ),
            const Divider(),
            _row(context, TTexts.bankBeneficiary.tr, bank.beneficiaryName),
            _row(context, TTexts.bankBin.tr, bank.bin),
            _row(context, TTexts.bankBik.tr, bank.bik),
            _row(context, TTexts.bankKbe.tr, bank.kbe),
          ],
        ),
      ),
    );
  }

  /// Uyarı kutusu — "hesap yok" ve "okunamadı" için ortak gösterim.
  Widget _notice(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: TRoundedContainer(
        radius: TSizes.borderRadiusMd,
        padding: const EdgeInsets.all(TSizes.md),
        backgroundColor: TColors.warningSoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Iconsax.warning_2, color: TColors.warning, size: TSizes.iconMd),
            const SizedBox(width: TSizes.spaceBtwItems / 2),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.apply(color: TColors.darkerGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyIban(String iban) {
    Clipboard.setData(ClipboardData(text: iban));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TTexts.bankCopied.tr), duration: const Duration(seconds: 2)),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium!.apply(fontWeightDelta: 1)),
        ],
      ),
    );
  }
}
