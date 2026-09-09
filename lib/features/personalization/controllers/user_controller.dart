import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../common/widgets/loaders/circular_loader.dart';
import '../../../utils/popups/dialogs.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/api_user_repository.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../models/user_model.dart';
import 'settings_controller.dart';

/// Giriş yapan kullanıcının bellekteki kaydı ve profil işlemleri.
///
/// İki kaynak var ve sırası önemli: özel API ile giriş yapıldığında kullanıcı
/// bilgisi girişte `GetStorage`'a yazılan `userData`'dan okunur; orada yoksa
/// `users/{id}` ucundan çekilip tekrar oraya yazılır. Böylece uygulama her
/// açılışta ağ beklemeden profili gösterebiliyor.
///
/// ⚠️ Dosyadaki "Firebase kullanıcısı için orijinal kod" dalları referanstan
/// olduğu gibi duruyor; bu proje Firebase kullanmıyor, o dallar hiç
/// çalışmıyor (KURALLAR §2: sebebini bilmediğin kodu silme).
class UserController extends GetxController {
  static UserController get instance => Get.find();

  Rx<UserModel> user = UserModel.empty().obs;
  final profileLoading = false.obs;
  final profileImageUrl = ''.obs;
  final hidePassword = false.obs;
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  final userRepository = ApiUserRepository.instance;
  final settingController = Get.put(SettingsController());
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  /// init user data when Home Screen appears
  @override
  void onInit() {
    fetchUserRecord();
    super.onInit();
  }

  /// Fetch user record
  Future<void> fetchUserRecord({bool fetchLatestRecord = false}) async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        profileLoading.value = true;
        
        // Storage'dan user verilerini oku
        final userData = authRepo.deviceStorage.read('userData');
        
        if (userData != null) {
          // Storage'daki veriyi UserModel'e çevir
          user.value = UserModel(
            id: userData['userId'] ?? '',
            firstName: userData['name'] ?? '',
            lastName: userData['surname'] ?? '',
            userName: '', // API'nizde username yoksa boş bırakın
            email: userData['email'] ?? '',
            phoneNumber: userData['phone'] ?? '',
            profilePicture: userData['profileImage'] ?? '',
            isEmailVerified: userData['isEmailVerified'] ?? false,
            isProfileActive: true,
            accountType: (userData['accountType'] ?? userData['accounttype'] ?? 'retail').toString(),
            iin: (userData['iin'] ?? '').toString(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else if (authRepo.customAuthToken.value.isNotEmpty) {
          // Storage'da veri yoksa API'den çek
          try {
            final userId = authRepo.getUserID;
            if (userId.isNotEmpty) {
              final fetchedUser = await ApiUserRepository.instance.fetchSingleItem(userId);
              user.value = fetchedUser;
              await authRepo.deviceStorage.write('userData', fetchedUser.toJson());
            }
          } catch (e) {
            user.value = UserModel.empty();
          }
        }
        
        profileLoading.value = false;
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      if (fetchLatestRecord) {
        profileLoading.value = true;
        final user = await userRepository.fetchSingleItem(AuthenticationRepository.instance.getUserID);
        this.user(user);
      } else {
        // Check if user is logged in and has a valid ID
        if (user.value.id != AuthenticationRepository.instance.getUserID) {
          user.value = UserModel.empty();
        }

        // Fetch user data from the repository
        if (user.value.id.isEmpty) {
          profileLoading.value = true;
          final user = await userRepository.fetchSingleItem(AuthenticationRepository.instance.getUserID);
          this.user(user);
        }
      }
    } catch (e) {
      TLoaders.warningSnackBar(title: TTexts.warning.tr, message: TTexts.userFetchFailed.tr);
    } finally {
      profileLoading.value = false;
    }
  }

  /// Save user Record from any Registration provider
  Future<void> saveUserRecord({UserModel? user}) async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı için user zaten kaydedilmiş, sadece fetch edelim
      if (authRepo.isCustomAuthUser.value) {
        await fetchUserRecord();
        return;
      }

      await fetchUserRecord();

      // If no record already stored, save the provided model.
      if (this.user.value.id.isEmpty && user != null) {
        await userRepository.addItem(user);
        this.user(user);
      }
    } catch (e) {
      TLoaders.warningSnackBar(
        title: TTexts.dataNotSaved.tr,
        message: TTexts.dataNotSavedMessage.tr,
      );
    }
  }

  /// Update user record after login (e.g., to update token)
  Future<void> updateUserRecordWithToken(String newToken) async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        // Custom API için token güncellemesi
        // TODO: API'nizde token güncelleme endpoint'i varsa burada çağırın
        user.value.deviceToken = newToken;
        user.refresh();
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      // Ensure we have fetched the user record before updating
      await fetchUserRecord();
      // Create a map to store the fields we want to update (e.g., token)
      Map<String, dynamic> updatedFields = {'deviceToken': newToken};

      // Call the repository to update the specific fields
      await userRepository.updateSingleField(user.value.id, updatedFields);

      // Update the local RxUser object with the new token
      user.value.deviceToken = newToken;
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: '${TTexts.failToUpdateUserRecord.tr} $e');
    }
  }

  /// Update user record after login (e.g., to update Pin)
  Future<void> updateUserRecordWithPin(String pin) async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        // 🔴 PIN yalnız istemcide tutuluyor: sunucuda karşılığı yok, bu yüzden
        // uygulama silinince/kurulunca kayboluyor. PIN'e güvenen bir güvenlik
        // kararı verme.
        // TODO: API'nizde pin güncelleme endpoint'i varsa burada çağırın
        user.value.pin = pin;
        user.refresh();
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      // Ensure we have fetched the user record before updating
      await fetchUserRecord();
      // Create a map to store the fields we want to update (e.g., token)
      Map<String, dynamic> updatedFields = {'pin': pin};

      // Call the repository to update the specific fields
      await userRepository.updateSingleField(user.value.id, updatedFields);

      // Update the local RxUser object with the new token
      user.value.pin = pin;
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: '${TTexts.failedToUpdateUserRecord.tr}: $e');
    }
  }

  /// - Increments `orderCount` by 1.
  /// - Adds `pointsPerPurchase * total` to `points`.
  /// - Subtracts `usedPoints` from `points`.
  /// - Updates the local `user` object in memory after the write.
  Future<void> updateUserAfterOrder({required double total, required bool isUsingPoints}) async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        // Custom API için order güncellemesi
        // TODO: API'nizde order update endpoint'i varsa burada çağırın
        
        // Local olarak güncelle
        int currentPoints = user.value.points;
        currentPoints = isUsingPoints ? 0 : currentPoints;
        final earnedPoints = (total * settingController.settings.value.pointsPerPurchase).toInt();
        final newPoints = currentPoints + earnedPoints;
        final newOrderCount = user.value.orderCount + 1;

        user.update((u) {
          if (u != null) {
            u.orderCount = newOrderCount;
            u.points = newPoints;
          }
        });
        user.refresh();
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      // 1️⃣ Refresh user from Firestore to get the latest values.
      await fetchUserRecord(fetchLatestRecord: true);

      // 2️⃣ Compute the new values based on existing user state:
      final currentOrderCount = user.value.orderCount;
      int currentPoints = user.value.points;
      currentPoints = isUsingPoints ? 0 : currentPoints;

      // Earned points = total * pointsPerPurchase (convert to int)
      final earnedPoints = (total * settingController.settings.value.pointsPerPurchase).toInt();

      // New points balance = (currentPoints + earned)
      final newPoints = currentPoints + earnedPoints;

      // New order count = current + 1
      final newOrderCount = currentOrderCount + 1;

      // 3️⃣ Prepare a single map of all fields to update:
      final updatedFields = <String, dynamic>{'orderCount': newOrderCount, 'points': newPoints};

      // 4️⃣ Perform exactly one write operation:
      await userRepository.updateSingleField(user.value.id, updatedFields);

      // 5️⃣ Update local Rx user object so UI stays in sync:
      user.update((u) {
        if (u != null) {
          u.orderCount = newOrderCount;
          u.points = newPoints;
        }
      });
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: '${TTexts.failToUpdateUserRecord.tr} $e');
    }
  }

  /// Update user points per purchase
  Future<void> updateUserPointsPerReview() async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        // Custom API için points güncellemesi
        // TODO: API'nizde points update endpoint'i varsa burada çağırın
        
        int points = user.value.points;
        points = points + settingController.settings.value.pointsPerReview.round();
        user.value.points = points;
        user.refresh();
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      // Ensure we have fetched the user record before updating
      await fetchUserRecord();

      int points = user.value.points;
      points = points + settingController.settings.value.pointsPerReview.round();
      Map<String, dynamic> updatedFields = {'points': points};

      // Call the repository to update the specific fields
      await userRepository.updateSingleField(user.value.id, updatedFields);

      // Update the local RxUser object with the order Count
      user.value.points = points;
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: '${TTexts.failToUpdateUserRecord.tr} $e');
    }
  }

  /// Update user points per purchase
  Future<void> updateUserPointsPerRating() async {
    try {
      final authRepo = AuthenticationRepository.instance;

      // Custom API kullanıcısı kontrolü
      if (authRepo.isCustomAuthUser.value) {
        // Custom API için points güncellemesi
        // TODO: API'nizde points update endpoint'i varsa burada çağırın
        
        int points = user.value.points;
        points = points + settingController.settings.value.pointsPerRating.round();
        user.value.points = points;
        user.refresh();
        return;
      }

      // Firebase kullanıcısı için orijinal kod
      // Ensure we have fetched the user record before updating
      await fetchUserRecord();

      int points = user.value.points;
      points = points + settingController.settings.value.pointsPerRating.round();
      Map<String, dynamic> updatedFields = {'points': points};

      // Call the repository to update the specific fields
      await userRepository.updateSingleField(user.value.id, updatedFields);

      // Update the local RxUser object with the order Count
      user.value.points = points;
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error.tr, message: '${TTexts.failToUpdateUserRecord.tr} $e');
    }
  }

  /// Delete Account Warning
  void deleteAccountWarningPopup() {
    TDialogs.confirm(
      title: TTexts.deleteAccount.tr,
      message: TTexts.deleteAccountSubText.tr,
      icon: Iconsax.profile_delete,
      isDestructive: true,
      confirmText: TTexts.delete.tr,
      onConfirm: () => deleteUserAccount(),
    );
  }

  /// Delete User Account
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processing.tr, TImages.docerAnimation);

      final auth = AuthenticationRepository.instance;

      await auth.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAllNamed(TRoutes.logIn);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// -- RE-AUTHENTICATE before deleting
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      TFullScreenLoader.openLoadingDialog(TTexts.processing.tr, TImages.docerAnimation);

      //Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!reAuthFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.reAuthenticateWithEmailAndPassword(verifyEmail.text.trim(), verifyPassword.text.trim());
      await AuthenticationRepository.instance.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAllNamed(TRoutes.logIn);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }

  /// Logout Loader Function
  logout() {
    try {
      TDialogs.confirm(
        title: TTexts.logout.tr,
        message: TTexts.sureLogout.tr,
        icon: Iconsax.logout,
        isDestructive: true,
        confirmText: TTexts.confirm.tr,
        onConfirm: () async {
          onClose();

          /// On Confirmation show any loader until user Logged Out.
          Get.defaultDialog(title: '', barrierDismissible: false, backgroundColor: Colors.transparent, content: const TCircularLoader());
          await AuthenticationRepository.instance.logout();
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    }
  }
}