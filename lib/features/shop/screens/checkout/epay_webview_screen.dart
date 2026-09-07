/// Halyk ePay `payment-api.js` widget'ını WebView içinde barındıran ekran.
///
/// Widget yalnız tarayıcıda/JS ile çalışıyor, bu yüzden
/// [TEpayService.buildHtml] ile üretilen sayfa WebView'e yükleniyor ve
/// `halyk.pay(...)` orada açılıyor. Kart bilgisi **Halyk'in PCI güvenli
/// sayfasında** giriliyor; uygulama hiçbir kart alanı toplamıyor.
///
/// 🔴 Dönüş adresleri (`successReturn` / `failureReturn`) **yakalanır,
/// yüklenmez**: `NavigationDecision.prevent` ile durdurulup sonuç ekranı
/// kapatır. Adresler gerçek bir sayfa değil, yalnız benzersiz ve sabit
/// önekler.
///
/// Sonuç `Get.back(result:)` ile döner: `true` ödendi, `false` başarısız,
/// `null` kullanıcı vazgeçti.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../data/services/epay/epay_service.dart';
import '../../../../utils/constants/colors.dart';

class EpayWebViewScreen extends StatefulWidget {
  const EpayWebViewScreen({super.key, required this.paymentObject, required this.widgetSources});

  final Map<String, dynamic> paymentObject;

  /// Denenecek `payment-api.js` adresleri — [TEpayService.resolveWidgetSources]
  /// tarafından zaten doğrulandı (güvenilen backend adresi ya da yerleşik test
  /// adresleri). Ekran kendi başına adres kabul etmez.
  final List<String> widgetSources;

  @override
  State<EpayWebViewScreen> createState() => _EpayWebViewScreenState();
}

class _EpayWebViewScreenState extends State<EpayWebViewScreen> {
  late final WebViewController _controller;
  final RxBool _loading = true.obs;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => _loading.value = true,
          onPageFinished: (url) => _loading.value = false,
          onNavigationRequest: (request) {
            if (request.url.startsWith(TEpayService.successReturn)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(TEpayService.failureReturn)) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        TEpayService.buildHtml(widget.paymentObject, sources: widget.widgetSources),
        // Gerçek bir https `baseUrl`: dış betiğin yüklenmesi ve Halyk'in
        // origin kontrolleri ancak böyle çalışıyor.
        baseUrl: 'https://ecom.aycom.kz',
      );
  }

  /// Sonucu bir kez döndürür. Arka arkaya birden çok yönlendirme gelirse
  /// ekranın iki kez kapanmasını engeller.
  void _finish(bool? paid) {
    if (_settled) return;
    _settled = true;
    Get.back(result: paid);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Donanım geri tuşu / kaydırma = vazgeçti; `null` dönüyor ki çağıran
      // "tamamlanmadı" diye ayırt edebilsin.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(null);
      },
      // Başlık çubuğu / kapatma düğmesi YOK: Halyk widget'ının kendi kapatma
      // denetimi var ve o, yakaladığımız hata adresine yönlendiriyor.
      child: Scaffold(
        backgroundColor: TColors.white,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              Obx(
                () => _loading.value
                    ? const Center(child: CircularProgressIndicator(color: TColors.primary))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
