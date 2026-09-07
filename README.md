# ecommerce-mobile-2 — Fores mobil mağaza

Fores / Foral / Stark Alpha ürünlerinin satıldığı **B2B ağırlıklı** e-ticaret
uygulamasının Flutter istemcisi. `fores/ecommerce-mobile` uygulamasının
**işlevsel birebir kopyasıdır**; yalnız tasarımı, renk paleti ve görünümü
değişir (kaynak: `ecommerce2/ecommerce-web-2`, bkz. `faz/TASARIM.md`).

- **Paket adı:** `tstore_ecommerce_app` · **applicationId:** `kz.fores.store`
- **353 Dart dosyası / ~53.000 satır** · **9 test dosyası / 118 test**
- **API tabanı:** `https://ecom.aycom.kz:5006/api/`
- **Diller:** 10 (kz · ru · tr · en elle çevrildi, kalan 6'da FAZ 11 bloğu İngilizce)

---

## Çalıştırma

```bash
flutter pub get
flutter run -d <cihaz>          # cihaz listesi: flutter devices
flutter analyze                 # 0 hata beklenir (41 info/warning referansta da var)
flutter test                    # 118 test
flutter build apk --debug
```

Gereken sürümler: **Flutter 3.47+**, Gradle **8.14.3**, AGP **8.11.1**, Kotlin
2.2.20, NDK 28.1.13356709. iOS bu makinede sınanmadı (CocoaPods kurulu değil).

> `pubspec.yaml` bağımlılıkları referans projeyle **birebir aynıdır**; yeni
> paket eklemeden önce sorulmalıdır (`faz/00-KURALLAR.md` §6).

---

## Mimari

GetX tabanlı üç katman; referanstaki dosya adları korunur.

```
lib/
├── app.dart · main.dart · home_menu.dart      # kök, 5 sekmeli alt gezinme
├── bindings/general_bindings.dart             # tüm repository + controller kaydı
├── routes/                                    # 38 rota sabiti + kayıt
├── data/
│   ├── abstract/api_base_repository.dart      # zarf okuma, sayfalama, hata çevirisi
│   ├── repositories/                          # 40 dosya — uç başına bir repository
│   └── services/                              # epay, bildirim, yerel depolama
├── features/
│   ├── authentication/                        # kayıt (bireysel + şirket + OTP), giriş, PIN
│   ├── shop/                                  # katalog, ürün, sepet, ödeme, sipariş, iade
│   ├── personalization/                       # profil, adres, ayarlar, bildirim, dil
│   └── chat/                                  # destek sohbeti
├── common/widgets/                            # paylaşılan bileşenler (kart, boş durum, appbar…)
├── localization/Languages/                    # 10 sözlük + tembel yükleyici
└── utils/
    ├── constants/colors.dart · sizes.dart     # TEK renk ve ölçü kaynağı
    ├── http/dio_client.dart                   # tek Dio + auth + önbellek interceptor'ı
    └── theme/                                 # aydınlık + karanlık tema
```

**Kural:** ağ trafiği daima `THttpClient` (tek `Dio`) üzerinden geçer; her uç
için `TApiRepositoryController` türevi bir repository vardır; ekranlar
repository'yi doğrudan çağırmaz, controller üzerinden erişir.

### Yanıt zarfı
Sunucu **hem** `{Success, Data, Message}` **hem** `{success, data, message}`
biçimini kullanır (aynı API içinde: `usersettings` PascalCase, `settings/public`
camelCase). Okuma daima temel sınıfın `isSuccess` / `dataOf` / `messageOf`
yardımcılarıyla yapılır — tek yazımı okuyan kod sessizce boş liste döndürür.

---

## İş kuralları nerede

| Kural | Tek kaynak |
|---|---|
| Ödeme modu (`gateway` / `transfer_only`) | `personalization/controllers/public_settings_controller.dart` |
| Kredi limiti kapısı (`hasCreditLine \|\| canOrderWithoutStock`) | `common/widgets/credit/credit_limit_section.dart` → `shouldShowCreditSection` |
| Ödeme kapıları (kartla tamamla / rekvizit göster) | `shop/screens/order/widgets/order_payment_gate.dart` |
| Stok durumu (var / ön sipariş / yok) | `common/widgets/products/product_cards/widgets/product_stock_badge.dart` → `TProductStock` |
| Şirket (1C / `erpSource`) bölme | `utils/helpers/erp_source_helper.dart` → `TErpSource.groupCartItems` |
| Fiyat semantiği (`price` güncel, `salePrice` = eski fiyat) | `shop/models/product_model.dart` + `product_controller.getProductPrice` |
| Fiyatı gizli ürün | `product_model.isPriceHidden` · `common/widgets/texts/t_product_price_text.dart` |
| Bildirim süzme (`RecipientIds`) | `personalization/controllers/notifcation_controller.dart` → `onlyMine` |
| Tek destek sohbeti | `chat/controllers/chat_controller.dart` → `ensureSupportChat` |
| ePay widget adresi güvenliği | `data/services/epay/epay_service.dart` → `resolveWidgetSources` |
| Renk ve ölçü | `utils/constants/colors.dart` · `sizes.dart` (**başka yerde ham değer yok**) |

### Atlanmaması gereken sunucu davranışları

- `GET products/{id}/variants` **dizi değil nesne** döner.
- `transfer_only` modunda sunucu `CanBypassPayment`'ı **herkese** `true` döner;
  kredili müşteri ayrımı **`HasCreditLine`** ile yapılır.
- **Bir ödeme = bir grup + şirket başına bir sipariş.** Sepette iki şirketin
  ürünü varsa sunucu siparişi böler, ikisi de aynı `GroupId` altındadır.
- `GET notifications` **süzgeçsiz** ve jetonsuz bile 200 döner; alıcıya göre
  süzme istemcide yapılır. `IsBroadcast`'e güvenilmez.
- `bank-details` süzgeçsiz çağrıda 12 satır (3 şirket × 4 para birimi) döner;
  **şirkete göre gruplanmalıdır**.
- `settings/public` erişilemezse **bugünkü davranışa** düşülür (kayıt AÇIK, mod
  `gateway`) ve sonuç **diske yazılmaz**.
- Kategori ağacı değişken derinliktedir (Fores 2, Foral 4 seviye).
- Fiyat kullanıcıya göre çözülür: isteklere `userId` gönderilir, misafirde liste
  fiyatı gelir (veya "fiyat sorunuz").

---

## Tasarım

Tek eylem rengi **indigo `#4A57E8`**; referansın turuncusu (`#F4801F`) tamamen
kalkmıştır. Zemin `#F5F6F8`, yüzey beyaz, köşe 8–14px, sayfa akışında gölge yok
(ayrım 1px çizgi). Karanlık tema korunur. Ayrıntı: `faz/TASARIM.md`.

İki denetim kuralı CI gibi çalıştırılabilir:

```bash
grep -rn "F4801F\|FFE24B\|FAD9C1" lib/                      # boş olmalı
grep -rn "Color(0xFF" lib/ | grep -v "constants/colors.dart" # boş olmalı
```

---

## Test

```bash
flutter test
```

| Dosya | Neyi korur |
|---|---|
| `order_group_split_test.dart` | alışveriş grubu çözümü, sepetin şirket kırılımı |
| `order_and_return_test.dart` | sipariş durumları, ödeme kapıları, iade akışı |
| `account_and_address_test.dart` | kredi kapısı, adres defteri, bildirim süzme |
| `chat_test.dart` | tek sohbet kuralı, yoklama koşulu, mesaj birleştirme |
| `localization_test.dart` | **on dilin anahtar kümesi birebir eşit** |
| `payment_mode_and_registration_test.dart` | kayıt anahtarları, `HasCreditLine`, rekvizitler |
| `price_hidden_test.dart` | fiyatı gizli ürünler (canlı yanıt fixture'ı ile) |
| `epay_widget_url_test.dart` | ePay widget adresinin alan adı denetimi |
| `notifications_test.dart` | canlı bildirim biçimi + alıcıya göre süzme |

`test/fixtures/live_products.json` canlı `GET /products` yanıtıdır; uydurma
veri değildir.

> **Yeni bir `TTexts` sabiti ekleyen, onu on sözlüğe de eklemek zorundadır** —
> `localization_test.dart` bunu her koşuda doğrular.

---

## Bilinen sınırlar

- **İade uçları (`return-requests`) ve kupon ucu (`coupons`) sunucuda YOK (404).**
  Ekranlar ve doğrulama yazılıdır; uç açıldığında yalnız repository gövdesi dolar.
- **`chat/{chatId}/upload` sunucuda YOK (404).** Ek, "görsel adresi" olarak
  gönderilir; bayt yükleyen yol hazır ve bağlıdır.
- Projede `image_picker`/`file_picker` bağımlılığı yoktur (paket ekleme yasağı);
  iade ve sohbet görselleri **bağlantı** olarak eklenir.
- **Telefonla giriş ve PIN'in sunucuya yazılması yoktur** (referansta da yok);
  PIN yalnız istemcide doğrulanır.
- `banners` ve `attributes` uçları boş döner; ana sayfa afişi
  `assets/slider2/` görsellerinden beslenir.
- SignalR (`chathub`) sunucuda açık değildir; yeni mesajlar **8 sn'lik yoklama**
  ile gelir. Hub kodu referansla birebir durur, açılırsa hazırdır.

Ayrıntılı faz geçmişi ve karar kayıtları: **`faz/DURUM.md`**.
