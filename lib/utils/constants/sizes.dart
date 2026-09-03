/// Uygulamanın tek ölçü kaynağı (boşluk, yarıçap, ikon, yükseklik).
///
/// Alan adları referans uygulamayla birebir aynıdır; TASARIM.md §3 uyarınca
/// yalnız köşe yarıçapları ve birkaç yükseklik web ile hizalandı.
/// Boşluk ölçeği (xs 4 · sm 8 · md 16 · lg 24 · xl 32) değişmedi.
class TSizes {
  // Padding and margin sizes
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Icon sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Font sizes
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;

  // Button sizes
  // Referansta buttonHeight (12) düğmenin DİKEY DOLGUSU olarak kullanılıyordu;
  // artık gerçek düğme yüksekliğidir (TASARIM.md §6: 44px dokunma hedefi).
  // Dolgu değeri için buttonPadding kullanılır.
  static const double buttonHeight = 44.0;
  static const double buttonPadding = 12.0;
  static const double buttonRadius = 8.0;
  static const double buttonWidth = 120.0;
  static const double buttonElevation = 4.0;

  // AppBar height
  static const double appBarHeight = 56.0;

  // Image sizes
  static const double imageThumbSize = 80.0;

  // Default spacing between sections
  static const double defaultSpace = 16.0;
  static const double spaceBtwItems = 16.0;
  static const double spaceBtwSections = 32.0;

  // Border radius
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 14.0;

  // Divider height
  static const double dividerHeight = 1.0;

  // Product item dimensions
  static const double productImageSize = 120.0;
  static const double productImageRadius = 12.0;
  static const double productItemHeight = 160.0;

  // FAZ 04 — ürün kartı ızgara ölçüleri.
  // Kart görselin altına başlık + fiyat + stok hapı + "sepete ekle" düğmesi
  // koyuyor (TASARIM.md §6); referanstaki 270'lik hücre bunları taşırıyordu.
  static const double productCardHeight = 300.0;
  static const double productCardImageHeight = 148.0;

  // Input field
  // 48px yükseklik + 8px köşe: form alanı ile düğme aynı dili konuşsun.
  static const double inputFieldHeight = 48.0;
  static const double inputFieldRadius = 8.0;
  static const double spaceBtwInputFields = 16.0;

  // Card sizes
  // Not: kartlar TASARIM.md §5 uyarınca gölgesizdir, ayrım 1px çizgiyle verilir.
  // cardElevation yalnız üste çıkan katmanlar (diyalog, sayfa altı sayfası) için.
  static const double cardRadiusLg = 16.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusSm = 10.0;
  static const double cardRadiusXs = 6.0;
  static const double cardElevation = 2.0;

  // Image carousel height
  static const double imageCarouselHeight = 200.0;

  // Loading indicator size
  static const double loadingIndicatorSize = 36.0;

  // Grid view spacing
  static const double gridViewSpacing = 16.0;
}
