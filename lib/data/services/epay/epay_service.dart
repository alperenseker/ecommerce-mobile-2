/// Halyk ePay ödeme jetonu ve widget parametreleri.
///
/// 🔴 Widget'a giden tutar, jetonun üretildiği tutarla **birebir aynı**
/// olmalı; farklıysa Halyk reddeder. `invoiceId` istemcide üretilmez.
/// `postlink` sunucu-sunucu çağrılır; istemci yalnız adresini widget'a verir.
library;

import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../../../utils/http/dio_client.dart';

/// Halyk ePay integration — the mobile counterpart of the web `checkout.js`
/// `EPAY` block and its helpers (`epayLang`, the `/payments/epay-token` call
/// and the `paymentObject`).
///
/// The Halyk widget (`payment-api.js` → `halyk.pay(...)`) is browser/JS only, so
/// it is hosted inside a [WebView] via [buildHtml]. Card data is entered on
/// Halyk's PCI-secure page; nothing sensitive is collected in the app.
class TEpayService {
  TEpayService._();

  /// Server-to-server payment notification endpoint (authoritative payment
  /// result). Same absolute URL as the web `EPAY.postLink`.
  static const String postLink = 'https://ecom.aycom.kz:5006/api/payments/epay-postlink';

  static const String currency = 'KZT';

  /// FALLBACK widget hosts (TEST environment), tried in order — used only when
  /// the backend does not return a (trusted) `widgetUrl` in the epay-token
  /// response. The environment switch lives on the backend: when it starts
  /// returning the live host (`https://epay.homebank.kz/payform/payment-api.js`)
  /// every installed app version switches without a store release.
  static const List<String> fallbackWidgetSources = [
    'https://test-epay.epayment.kz/payform/payment-api.js',
    'https://test-epay.homebank.kz/payform/payment-api.js',
  ];

  /// Domains the payment widget script may be loaded from. The backend-supplied
  /// `widgetUrl` is only honored when it is an https URL on one of these Halyk
  /// domains (or a subdomain); anything else is ignored and the fallback list
  /// is used, so a tampered/misconfigured response can never make the WebView
  /// execute a script from an attacker-controlled host.
  static const List<String> _trustedWidgetDomains = ['epayment.kz', 'homebank.kz'];

  /// True when [url] is an https URL whose host is one of
  /// [_trustedWidgetDomains] or a subdomain of one.
  static bool isTrustedWidgetUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return _trustedWidgetDomains.any((d) => host == d || host.endsWith('.$d'));
  }

  /// Sources the payment page should try, in order. A trusted backend
  /// [widgetUrl] is used EXCLUSIVELY (no fallback to the test hosts, so live
  /// credentials can never end up on a test widget or vice versa); otherwise
  /// the built-in test fallbacks apply.
  static List<String> resolveWidgetSources(String widgetUrl) =>
      isTrustedWidgetUrl(widgetUrl) ? [widgetUrl.trim()] : fallbackWidgetSources;

  /// Sentinel return URLs. Halyk redirects the browser here after
  /// success/failure; the WebView intercepts them (they are never loaded) to
  /// resolve the payment result. They only need to be unique, stable prefixes.
  static const String successReturn = 'https://ecom.aycom.kz/mobile-epay/success';
  static const String failureReturn = 'https://ecom.aycom.kz/mobile-epay/failure';

  /// Maps the saved app language (`LanguageController` writes `'language'` to
  /// GetStorage) to an ePay language code — web `epayLang`.
  static String epayLang() {
    final l = (GetStorage().read<String>('language') ?? 'ru').toLowerCase();
    if (l.startsWith('kk') || l.startsWith('kz')) return 'kaz';
    if (l.startsWith('en')) return 'eng';
    return 'rus';
  }

  /// Requests an ePay auth token from the backend (the `ClientSecret` stays on
  /// the server). Mirrors the web `POST /payments/epay-token`. `auth` is the raw
  /// ePay OAuth object and is forwarded to the widget unchanged, like web.
  ///
  /// `invoiceId` is NOT sent — the backend generates it and writes it to
  /// `order_groups.invoiceid` so the `postLink` callback can find the purchase
  /// by it. The generated id is read back from the response and must be the one
  /// used in [buildPaymentObject]; using a locally-generated id here would
  /// desync the payform's invoiceId from the one the backend is listening for,
  /// and the order would never be marked paid.
  ///
  /// FAZ 26 — [groupId] gönderilir (karar K3): fatura **gruba** aittir ve
  /// çekilen tutar grubun toplamıdır. Boş bırakılırsa backend grubu [orderId]
  /// üzerinden bulur (K7 yolu; eski istemciler böyle çalışıyor).
  /// Yanıttaki [EpayTokenResult.amount] **otoritedir** — widget'a her zaman o
  /// verilir, istemcinin hesapladığı tutar değil.
  ///
  /// The response may also carry `widgetUrl` — the payment-api.js host chosen
  /// by the backend (test or live). It is returned raw here; trust/domain
  /// validation happens in [resolveWidgetSources].
  static Future<EpayTokenResult> fetchToken({
    required int amount,
    required String orderId,
    required String description,
    String groupId = '',
  }) async {
    // debugPrint('🟦 [TEpayService.fetchToken] POST payments/epay-token '
    //     'amount=$amount currency=$currency orderId=$orderId groupId=$groupId');
    final response = await THttpClient.dio.post(
      'payments/epay-token',
      data: {
        'amount': amount,
        'currency': currency,
        'orderId': orderId,
        'description': description,
        // Boşken hiç gönderilmez: backend yalnız groupId gelip de grup
        // bulunamazsa 404 döndürüyor, oysa orderId yolu her zaman çalışır.
        if (groupId.isNotEmpty) 'groupId': groupId,
      },
    );
    // debugPrint('🟩 [TEpayService.fetchToken] status=${response.statusCode} data=${response.data}');

    final body = response.data;
    final data = (body is Map ? (body['Data'] ?? body['data']) : null);
    if (data is! Map) {
      // debugPrint('🟥 [TEpayService.fetchToken] Data alanı yok/beklenmeyen tip: $body');
      throw (body is Map ? (body['Message'] ?? body['message']) : null) ?? 'Payment token could not be obtained.';
    }
    final auth = data['auth'] ?? data['Auth'];
    final terminal = data['terminal'] ?? data['Terminal'];
    final invoiceId = data['invoiceId'] ?? data['InvoiceId'] ?? data['invoiceid'];
    final widgetUrl = data['widgetUrl'] ?? data['WidgetUrl'] ?? data['widgeturl'];
    if (auth == null || terminal == null || invoiceId == null) {
      // debugPrint('🟥 [TEpayService.fetchToken] auth/terminal/invoiceId eksik: auth=$auth terminal=$terminal invoiceId=$invoiceId');
      throw 'Payment token could not be obtained.';
    }

    // Grup alanları eski API'de YOKTUR; yoklukları hata değildir.
    final resolvedAmount = _toInt(data['amount'] ?? data['Amount']) ?? 0;

    return EpayTokenResult(
      auth: auth,
      terminal: terminal.toString(),
      invoiceId: invoiceId.toString(),
      widgetUrl: widgetUrl?.toString() ?? '',
      amount: resolvedAmount > 0 ? resolvedAmount : amount,
      groupId: (data['groupId'] ?? data['GroupId'])?.toString() ?? '',
      groupNumber: (data['groupNumber'] ?? data['GroupNumber'])?.toString() ?? '',
      orderCount: _toInt(data['orderCount'] ?? data['OrderCount']) ?? 0,
    );
  }

  /// Sayı alanları backend'den `int`, `double` ya da metin gelebilir.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().trim());
  }

  /// Builds the `paymentObject` passed to `halyk.pay(...)` — same fields as web.
  /// `token.invoiceId` (backend-generated) is used, not a locally-generated id.
  /// [amount] must be [EpayTokenResult.amount] (the group total when the
  /// purchase was split), never a client-side figure.
  static Map<String, dynamic> buildPaymentObject({
    required EpayTokenResult token,
    required int amount,
    required String orderId,
    required String accountId,
    required String name,
    required String email,
    required String phone,
  }) {
    final description = 'Order #$orderId';
    return {
      'invoiceId': token.invoiceId,
      'backLink': successReturn,
      'failureBackLink': failureReturn,
      'postLink': postLink,
      'failurePostLink': postLink,
      'language': epayLang(),
      'description': description,
      'accountId': accountId,
      'terminal': token.terminal,
      'amount': amount,
      'currency': currency,
      'name': name,
      'email': email,
      'phone': phone,
      'auth': token.auth,
    };
  }

  /// HTML page that loads the widget script from [sources] (tried in order,
  /// same fallback pattern as web) and then opens the payment screen via
  /// `halyk.pay(...)`, falling back to `halyk.showPaymentWidget(...)`. Loaded
  /// into the WebView with a real https `baseUrl` so the external script and
  /// origin checks work. Callers must obtain [sources] via
  /// [resolveWidgetSources] so only trusted Halyk hosts ever reach the page.
  static String buildHtml(Map<String, dynamic> paymentObject, {required List<String> sources}) {
    final poJson = jsonEncode(paymentObject);
    final sourcesJson = jsonEncode(sources);
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="margin:0;background:#fff;">
<script>
  var SOURCES = $sourcesJson;
  var paymentObject = $poJson;
  function startPay() {
    try {
      if (typeof halyk !== 'undefined' && typeof halyk.pay === 'function') {
        halyk.pay(paymentObject);
      } else if (typeof halyk !== 'undefined' && typeof halyk.showPaymentWidget === 'function') {
        halyk.showPaymentWidget(paymentObject, function (result) {
          if (result && (result.success === true || result.code === 'ok')) {
            window.location.href = paymentObject.backLink;
          } else {
            window.location.href = paymentObject.failureBackLink;
          }
        });
      } else {
        window.location.href = paymentObject.failureBackLink;
      }
    } catch (e) {
      window.location.href = paymentObject.failureBackLink;
    }
  }
  function load(i) {
    if (i >= SOURCES.length) { window.location.href = paymentObject.failureBackLink; return; }
    var s = document.createElement('script');
    s.src = SOURCES[i];
    s.async = true;
    s.onload = function () { startPay(); };
    s.onerror = function () { load(i + 1); };
    document.head.appendChild(s);
  }
  load(0);
</script>
</body>
</html>
''';
  }
}


/// `POST /api/payments/epay-token` yanıtı.
///
/// [amount] **backend'in belirlediği** çekim tutarıdır: grup varsa grubun
/// toplamı (karar K3). Widget'a her zaman bu verilir; istemcinin hesapladığı
/// tutar yalnız ön kontrol içindir.
///
/// [groupId] / [groupNumber] / [orderCount] eski API'de gelmez — sırasıyla
/// boş, boş ve 0 kalır, arayüz de tek siparişlik davranışa düşer.
class EpayTokenResult {
  const EpayTokenResult({
    required this.auth,
    required this.terminal,
    required this.invoiceId,
    required this.widgetUrl,
    required this.amount,
    required this.groupId,
    required this.groupNumber,
    required this.orderCount,
  });

  /// Halyk OAuth nesnesi — widget'ın `auth` alanına AYNEN verilir.
  final dynamic auth;
  final String terminal;
  final String invoiceId;
  final String widgetUrl;

  /// Çekilecek tutar (KZT, tam sayı). Grup varsa grubun toplamı.
  final int amount;

  final String groupId;
  final String groupNumber;

  /// Bu tek ödemenin kapattığı sipariş sayısı.
  final int orderCount;

  /// Ödeme birden çok siparişi birden kapatıyor mu — arayüz bunu söylemeli ki
  /// müşteri tek siparişin tutarını ödediğini sanmasın.
  bool get coversMultipleOrders => orderCount > 1;
}
