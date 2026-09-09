import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../data/repositories/authentication/authentication_repository.dart';

/// Uygulamanın tamamı için **tek** paylaşılan [Dio] örneği.
///
/// Önceden her repository kendi [Dio]'sunu kuruyordu (15'ten fazla ayrı bağlantı
/// havuzu, her birinde auth interceptor'ın ayrı bir kopyası). Hepsi artık bu tek
/// istemciyi paylaşıyor; üzerinde iki interceptor var:
///   * jeton interceptor'ı — jeton **her istekte yeniden okunur**, böylece daima
///     son oturum durumunu yansıtır;
///   * [TCacheInterceptor] — yalnız herkese açık katalog uçları için küçük,
///     bellek içi GET önbelleği.
class THttpClient {
  THttpClient._();

  static const String baseUrl = 'https://ecom.aycom.kz:5006/api/';

  /// The shared client. Built lazily on first access.
  static final Dio dio = _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      // Bunlar olmadan hiç yanıt vermeyen bir sunucu (ya da kopan bağlantı)
      // isteği sonsuza dek asar; onu bekleyen arayüz — örneğin bir yükleme
      // penceresi — çıkışsız kalır.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    /// Jetonu her isteğe ekler; yoksa `[Authorize]` isteyen uçlar (adres,
    /// ayarlar, kullanıcı, sipariş…) 401 döner. Jeton **her istekte yeniden
    /// okunur**, böylece son oturum durumunu yansıtır. Çağıranın kendi
    /// koyduğu bir `Authorization` başlığı ezilmez.
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

    /// Seyrek değişen herkese açık veri için bellek içi önbellek.
    dio.interceptors.add(TCacheInterceptor());

    return dio;
  }
}

/// Seyrek değişen herkese açık verinin (afiş, kategori, öznitelik, ayar,
/// ürün) her ekranda yeniden çekilmesini önleyen küçük bellek içi önbellek.
///
/// 🔴 Tasarımı gereği güvenli:
///  * Yalnız yolu **izin listesindeki** bir önekle başlayan GET istekleri
///    önbelleklenir. Kullanıcıya özel veri (sepet, adres, sipariş, favori,
///    bildirim, kullanıcı/kullanıcı ayarları) **asla** önbelleklenmez —
///    bayat gösterilmesi yanlış tutar, yanlış adres, yanlış stok demektir.
///  * Kayıtlar [_ttl] sonunda düşer.
///  * Başarılı **her** yazma isteği (POST/PUT/PATCH/DELETE) önbelleğin
///    tamamını temizler, böylece bir yazmanın ardından gelen ilk okuma taze
///    veri görür.
///  * Tek bir istek için `options: Options(extra: {'no_cache': true})` ile
///    önbellek atlanır.
class TCacheInterceptor extends Interceptor {
  static const Duration _ttl = Duration(seconds: 90);

  /// Önbelleklenmesi güvenli yol önekleri: yalnız herkese açık katalog
  /// verisi. Bu kümeye kullanıcıya özel bir yol EKLEME.
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
      // Bir yazma oldu: her şeyi at ki sonraki okuma taze olsun.
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
