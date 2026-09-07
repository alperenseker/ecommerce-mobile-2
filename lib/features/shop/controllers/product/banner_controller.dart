/// Sunucudan gelen afişleri (banner) tutan controller.
///
/// 🔴 `GET /api/banners` şu an **boş** dönüyor (`TotalCount: 0`, yetkili de
/// yetkisiz de). Afiş karuseli çizen yer boş hâli tasarlamak zorunda;
/// "veri gelmiyor, kod bozuk" diye zaman harcama — sunucuda kayıt yok.
library;

import 'package:get/get.dart';

import '../../../../data/repositories/banners/api_banner_repository.dart';
import '../../../../home_menu.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/banner_model.dart';

class BannerController extends GetxController {
  final bannersLoading = false.obs;
  final carousalCurrentIndex = 0.obs;
  final bannerRepo = ApiBannerRepository.instance;
  final RxList<BannerModel> banners = <BannerModel>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchBanners();
  }

  void updatePageIndicator(int index) {
    carousalCurrentIndex.value = index;
  }

  /// Afişleri sunucudan çek ve listeyi güncelle.
  Future<void> fetchBanners() async {
    try {
      bannersLoading.value = true;

      final banners = await bannerRepo.fetchAllItems();

      this.banners.assignAll(banners);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      bannersLoading.value = false;
    }
  }

  /// Afişe dokunulunca nereye gidileceği. Hedef türü sunucudan geliyor.
  void onBannerClick(BannerModel banner) {
    switch (banner.targetType) {
      case BannerTargetType.productScreen:
        if (banner.targetId != null) {
          Get.toNamed(TRoutes.productDetail, parameters: {'id': "${banner.targetId}"});
        }
        break;

      case BannerTargetType.categoryScreen:
        if (banner.targetId != null) {
          Get.toNamed(TRoutes.category, arguments: {'id': banner.targetId});
        }
        break;

      case BannerTargetType.customUrl:
        if (banner.customUrl != null) {
          Get.toNamed('/webview', arguments: {'url': banner.customUrl});
        }
        break;
      case BannerTargetType.brandScreen:
        if (banner.targetId != null) {
          // Marka düzenleme rotası referansta da yorumda; hedef yok.
          //   Get.toNamed(TRoutes.editBrand, arguments: {'id': banner.targetId});
        }
        break;

      case BannerTargetType.homeScreen:
        Get.toNamed(TRoutes.homeMenu);
        break;
      case BannerTargetType.shopScreen:
        AppScreenController.instance.selectedMenu.value = 1;
        Get.toNamed(TRoutes.homeMenu);
        break;
      case BannerTargetType.settingScreen:
        AppScreenController.instance.selectedMenu.value = 3;
        Get.toNamed(TRoutes.homeMenu);
        break;
      case BannerTargetType.favouriteScreen:
        AppScreenController.instance.selectedMenu.value = 2;
        Get.toNamed(TRoutes.homeMenu);
        break;
      case BannerTargetType.cart:
        Get.toNamed(TRoutes.cart);
        break;
      case BannerTargetType.orders:
        Get.toNamed(TRoutes.order);
        break;
      case BannerTargetType.profile:
        Get.toNamed(TRoutes.userProfile);
        break;
      case BannerTargetType.none:
        Get.toNamed(TRoutes.homeMenu);
        break;
    }
  }

  void updateClickValue(BannerModel banner) async {
    int clicks = banner.clicks;
    clicks++;
    await bannerRepo.updateSingleField(banner.id, {'clicks': clicks});
  }
}
