/// Uygulamanın tek ölçü kaynağı (boşluk, ikon, köşe, yükseklik).
///
/// Alan adları referans uygulamayla aynıdır; `faz/TASARIM.md` §3 yalnız köşe
/// yarıçaplarını ve birkaç yüksekliği web paletiyle hizalar. Boşluk ölçeği
/// (xs 4 · sm 8 · md 16 · lg 24 · xl 32) referanstakiyle aynı kaldı.
///
/// Sihirli sayı yazmak yerine hep buradan okunur.
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
  /// Dokunma hedefi yüksekliği. Referansta bu alan 12.0 idi ve düğme
  /// temalarında **dikey iç boşluk** olarak kullanılıyordu; TASARIM.md §6
  /// düğmeyi 44px yükseklik olarak tanımladığı için artık gerçek yükseklik.
  /// Dikey iç boşluk için [buttonVerticalPadding] kullanılır.
  static const double buttonHeight = 44.0;
  static const double buttonVerticalPadding = 10.0;
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

  /// FAZ 04 — ürün kartının ızgara hücresi ölçüleri.
  ///
  /// Referansın 270px'lik hücresi yeni kartı (başlık + puan + fiyat + stok hapı
  /// + "sepete ekle" düğmesi) taşırıyordu; 320px genişlikte denenip bu üç
  /// değere oturtuldu. **Ürün ızgarası çizen her yer bunları kullanmalı**,
  /// yoksa kartlar bir ekranda taşar, ötekinde boşluk bırakır.
  static const double productCardHeight = 330.0;
  static const double productCardImageHeight = 130.0;
  static const double productCardHorizontalHeight = 176.0;

  // Input field
  /// TASARIM.md §6: form alanı 48px yüksekliğinde, 8px köşeli.
  /// Referansta yalnız yarıçap vardı; yükseklik bu projede eklendi.
  static const double inputFieldHeight = 48.0;
  static const double inputFieldRadius = 8.0;
  static const double spaceBtwInputFields = 16.0;

  // Card sizes
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
