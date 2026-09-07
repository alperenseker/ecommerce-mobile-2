// FAZ 12 — ePay widget adresinin güvenilirlik denetimi.
//
// Referans projedeki `test/epay_widget_url_test.dart` dosyasının hedefe
// taşınmış hâlidir (FAZ 07'den devreden borç, DURUM.md).
//
// Neden bu test var: `payments/epay-token` yanıtındaki `widgetUrl` sunucudan
// geliyor ve WebView'e **script kaynağı** olarak veriliyor. Sunucu ele
// geçirilir ya da yanlış yapılandırılırsa oraya yabancı bir alan adı yazılıp
// kart sayfası taklit edilebilir. Bu yüzden yalnız `epayment.kz` ve
// `homebank.kz` (ve alt alan adları), yalnız `https` üzerinden kabul edilir;
// geri kalan her şeyde gömülü yedek kaynaklara düşülür (faz/API.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:tstore_ecommerce_app/data/services/epay/epay_service.dart';

void main() {
  group('TEpayService.resolveWidgetSources', () {
    test('sunucunun bugün döndürdüğü test adresi tek başına kullanılır', () {
      const url = 'https://test-epay.epayment.kz/payform/payment-api.js';
      expect(TEpayService.resolveWidgetSources(url), [url]);
    });

    test('canlı Halyk adresi güveniliyor', () {
      const url = 'https://epay.homebank.kz/payform/payment-api.js';
      expect(TEpayService.resolveWidgetSources(url), [url]);
    });

    test('boş widgetUrl gömülü yedek kaynaklara düşer', () {
      expect(TEpayService.resolveWidgetSources(''), TEpayService.fallbackWidgetSources);
    });

    test('https olmayan adres reddedilir', () {
      expect(
        TEpayService.resolveWidgetSources('http://epay.homebank.kz/payform/payment-api.js'),
        TEpayService.fallbackWidgetSources,
      );
    });

    test('benzer görünen alan adları reddedilir', () {
      // Alan adı denetimi "içeriyor mu" ile yapılırsa bunların hepsi geçerdi.
      for (final evil in [
        'https://evil-homebank.kz/payform/payment-api.js',
        'https://homebank.kz.attacker.com/payform/payment-api.js',
        'https://fakeepayment.kz/payform/payment-api.js',
        'https://attacker.com/?x=.homebank.kz',
      ]) {
        expect(
          TEpayService.resolveWidgetSources(evil),
          TEpayService.fallbackWidgetSources,
          reason: '$evil güvenilir sayılmamalı',
        );
      }
    });

    test('güvenilir alan adlarının alt alanları kabul edilir', () {
      const url = 'https://test-epay.homebank.kz/payform/payment-api.js';
      expect(TEpayService.resolveWidgetSources(url), [url]);
    });
  });
}
