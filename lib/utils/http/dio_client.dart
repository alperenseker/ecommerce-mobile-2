/// Uygulamanın **tek** HTTP istemcisi.
///
/// Eskiden her repository kendi `Dio`'sunu kuruyordu (15+ ayrı bağlantı havuzu,
/// her birinde auth interceptor'ın ayrı bir kopyası). Artık hepsi buradaki tek
/// istemciyi paylaşır; taban adres, zaman aşımları, yetki başlığı ve GET
/// önbelleği tek yerde tanımlıdır.
library;

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../data/repositories/authentication/authentication_repository.dart';

/// Single shared [Dio] instance for the whole app.
///
/// Previously every repository created its own [Dio] (15+ separate connection
/// pools, each with its own copy of the auth interceptor). They now all share
/// this one client, which carries:
///   * the auth-token interceptor (token read per-request, so it always
///     reflects the latest login state), and
///   * a small in-memory GET cache ([TCacheInterceptor]) for read-heavy public
///     catalog endpoints.
class THttpClient {
  THttpClient._();

  static const String baseUrl = 'https://ecom.aycom.kz:5006/api/';

  /// Paylaşılan istemci. İlk erişimde kurulur.
  static final Dio dio = _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      // Bunlar olmadan yanıt vermeyen bir sunucu (ya da kopan bağlantı)
      // isteği sonsuza kadar askıda bırakır; onu bekleyen arayüz (ör. yükleme
      // penceresi) kurtulma yolu olmadan kilitlenir.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    /// Jeton her isteğe eklenir; yoksa `[Authorize]` isteyen uçlar (adres,
    /// ayarlar, kullanıcı, sipariş, ...) 401 döner. Jeton **her istekte
    /// yeniden okunur**, böylece en güncel oturum durumunu yansıtır. Çağıran
    /// açıkça bir `Authorization` başlığı koyduysa üzerine yazılmaz.
    ///
    /// `options: Options(extra: {'skip_auth': true})` ile token HİÇ
    /// eklenmez. Kayıt ekranı tanımı gereği anonimdir ve
    /// `GET /settings/public` anonim uçtur; oturumdan kalmış bayat bir token
    /// göndermek o çağrıyı gereksiz yere sunucunun kimlik doğrulama yoluna
    /// sokar. (Web'deki `skipAuth: true` ile aynı.)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.extra['skip_auth'] == true) {
          options.headers.remove('Authorization');
          return handler.next(options);
        }
        if (Get.isRegistered<AuthenticationRepository>()) {
          final token = AuthenticationRepository.instance.customAuthToken.value;
          if (token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));

    /// Nadiren değişen genel veriler için bellek içi önbellek.
    dio.interceptors.add(TCacheInterceptor());

    return dio;
  }
}

/// Nadiren değişen genel verinin (afiş, kategori, öznitelik, ayar, ürün) her
/// ekranda yeniden çekilmesini önleyen küçük bellek içi yanıt önbelleği.
///
/// 🔴 Tasarımı gereği güvenli:
///  * Yalnız GET istekleri ve yalnız izin listesindeki yolla başlayanlar
///    önbelleklenir. **Kullanıcıya özel veri (sepet, adres, sipariş, favori,
///    bildirim, kullanıcı/kullanıcı ayarları) asla önbelleklenmez** — bayat
///    gösterilemez.
///  * Kayıtların ömrü [_ttl] kadardır.
///  * Başarılı HERHANGİ bir yazma isteği (POST/PUT/PATCH/DELETE) önbelleğin
///    tamamını temizler; böylece yazmadan sonraki ilk okuma tazedir.
///  * Tek bir istek için atlamak isteyen
///    `options: Options(extra: {'no_cache': true})` gönderir.
class TCacheInterceptor extends Interceptor {
  static const Duration _ttl = Duration(seconds: 90);

  /// Önbelleklenmesi güvenli yol önekleri: yalnız genel katalog verisi.
  static const Set<String> _cacheablePrefixes = {
    'banners',
    'categories',
    'attributes',
    'settings',
    'products',
  };

  final Map<String, _CacheEntry> _store = {};

  bool _isCacheable(RequestOptions o) {
    if (o.method.toUpperCase() != 'GET') return false;
    if (o.extra['no_cache'] == true) return false;
    final path = o.path.replaceFirst(RegExp(r'^/+'), '').toLowerCase();
    return _cacheablePrefixes.any(
      (p) => path == p || path.startsWith('$p/') || path.startsWith('$p?'),
    );
  }

  String _key(RequestOptions o) => '${o.path}?${o.uri.query}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isCacheable(options)) {
      final entry = _store[_key(options)];
      if (entry != null && !entry.isExpired) {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: entry.data,
            statusCode: 200,
          ),
        );
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    if (o.method.toUpperCase() == 'GET') {
      if (_isCacheable(o) && response.statusCode == 200) {
        _store[_key(o)] = _CacheEntry(
          response.data,
          DateTime.now().add(_ttl),
        );
      }
    } else {
      // Yazma oldu: her şeyi at ki sonraki okuma taze gelsin.
      _store.clear();
    }
    handler.next(response);
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
