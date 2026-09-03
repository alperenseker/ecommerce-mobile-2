/// Üç genel anahtarın (kayıt aç/kapa, ödeme modu) istemci tarafındaki tek
/// kaynağı. `GET /api/settings/public` (anonim) okunur.
library;

import 'package:get/get.dart';

import '../../../data/repositories/settings/api_settings_repository.dart';
import '../models/public_settings_model.dart';

/// FAZ 34 — üç genel anahtarın (kayıt aç/kapa, ödeme modu) istemci tarafındaki
/// tek kaynağı. `GET /api/settings/public` (anonim) okunur.
///
/// İki kural koda gömüldü — ikisi de Faz 32'nin (web) kararlarının aynısı:
///
/// 🔴 **Hata = bugünkü davranış.** Ağ/sunucu hatasında değer
/// [PublicSettingsModel.defaults] (kayıt AÇIK, mod `gateway`) kalır ve metot
/// **asla fırlatmaz**. Bir ağ hatası uygulamayı kayıt kapalıya ya da ödemesiz
/// moda düşürmemeli; asıl kapı sunucudadır (K29.2).
///
/// 🔴 **Diske YAZILMAZ.** `GetStorage`'a kalıcı yazılsaydı superAdmin anahtarı
/// çevirdikten sonra bayat değer müşteriyi yanlış ekrana sokardı. Değer yalnız
/// uygulama oturumu boyunca bellekte tutulur.
class PublicSettingsController extends GetxController {
  static PublicSettingsController get instance => Get.isRegistered<PublicSettingsController>()
      ? Get.find()
      : Get.put(PublicSettingsController(), permanent: true);

  final Rx<PublicSettingsModel> settings = PublicSettingsModel.defaults.obs;
  final RxBool loaded = false.obs;

  /// Aynı anda birden çok ekran isterse tek istek açılır, ötekiler aynı sözü
  /// bekler (web'deki `getPublicSettings()` deseni).
  Future<void>? _inFlight;

  ApiSettingsRepository get _repository => Get.isRegistered<ApiSettingsRepository>()
      ? ApiSettingsRepository.instance
      : Get.put(ApiSettingsRepository(), permanent: true);

  /// Kısayollar — ekranlar bunlara bakar.
  bool get retailRegistrationEnabled => settings.value.retailRegistrationEnabled;
  bool get companyRegistrationEnabled => settings.value.companyRegistrationEnabled;
  bool get isRegistrationClosed => settings.value.isRegistrationClosed;
  bool get isTransferOnly => settings.value.isTransferOnly;

  @override
  void onInit() {
    // Sonucu beklemiyoruz: ekranlar `Obx` ile değeri izliyor, gelene kadar
    // bugünkü davranış çiziliyor.
    ensureLoaded();
    super.onInit();
  }

  /// Bir kez yükler; yüklendiyse hiçbir şey yapmaz.
  Future<void> ensureLoaded() {
    if (loaded.value) return Future.value();
    return _inFlight ??= _load(forceRefresh: false).whenComplete(() => _inFlight = null);
  }

  /// Anahtarları **yeniden** okur (istemci önbelleği atlanır).
  ///
  /// Sipariş oluşturmadan hemen önce çağrılır: bayat bir mod değeri müşteriyi
  /// kapalı ödeme yoluna sokar ya da 409'a çarptırır.
  ///
  /// ⚠️ Adı bilerek `refresh` DEĞİL: `GetxController` o adı zaten taşıyor
  /// (dinleyicileri uyaran senkron metot) ve üzerine yazmak GetX'in kendi
  /// yenileme mekanizmasını sessizce bozardı.
  Future<void> reload() {
    return _inFlight ??= _load(forceRefresh: true).whenComplete(() => _inFlight = null);
  }

  Future<void> _load({required bool forceRefresh}) async {
    try {
      settings.value = await _repository.getPublicSettings(forceRefresh: forceRefresh);
      loaded.value = true;
    } catch (_) {
      // Bilerek sessiz: okunamayan anahtar "bugünkü davranış" demektir.
      // Daha önce başarıyla okunmuşsa o değer korunur, yoksa varsayılan kalır.
    }
  }

  /// Sunucudan **403 + `errorCode`** geldiğinde ekranı gerçeğe çeker (K29.2).
  ///
  /// Anahtar, ekran açıldıktan sonra çevrilmiş olabilir: kullanıcı hâlâ kayıt
  /// formunu görüyor ama sunucu artık kabul etmiyor. Kodlar Faz 29'un
  /// **değiştirilemez** sözleşmesidir.
  void applyRegistrationError(String? errorCode) {
    switch (errorCode) {
      case 'registration_disabled_retail':
        settings.value = settings.value.copyWith(retailRegistrationEnabled: false);
        break;
      case 'registration_disabled_company':
        settings.value = settings.value.copyWith(companyRegistrationEnabled: false);
        break;
      case 'registration_disabled':
        settings.value = settings.value.copyWith(
          retailRegistrationEnabled: false,
          companyRegistrationEnabled: false,
        );
        break;
      default:
        // Alakasız bir hata — anahtarlara dokunulmaz.
        break;
    }
  }
}
