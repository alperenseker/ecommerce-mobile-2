/// This class contains all the App Text in String formats.
class TTexts {
  static const String english = 'english';
  static const String french = 'french';
  static const String german = 'german';
  static const String portuguese = 'portuguese';
  static const String brazilian = 'brazilian';
  static const String vietnamese = 'Vietnamese';
  static const String spanish = 'spanish';
  static const String russian = 'russian';

  //Welcome Screen
  static const String welcomeToStore = "welcomeToStore";
  static const String shopSmartBetter = "shopSmartBetter";
  static const String loginWithEmailPass = "loginWithEmailPass";
  static const String loginWithPhoneNo = "loginWithPhoneNo";
  static const String signInWithGoogle = "signInWithGoogle";
  static const String haveAnAccount = "haveAnAccount";
  static const String signUp = "signUp";

  //login screen
  static const String loginTitle = "loginTitle";
  static const String loginSubTitle = "loginSubTitle";
  static const String email = "email";
  static const String password = "password";
  static const String rememberMe = "Remember Me";
  static const String forgetPassword = "forgetPassword";
  static const String signIn = "signIn";
  static const String createAccount = "Create Account";

  //Signup screen
  static const String signupTitle = "signupTitle";
  static const String firstName = "firstName";
  static const String lastName = "lastName";
  static const String username = "Username";
  static const String phoneNo = "Phone Number";
  static const String selectCountry = "selectCountry";
  static const String iAgreeTo = "iAgreeTo";
  static const String privacyPolicy = "privacyPolicy";
  static const String termsOfUse = "termsOfUse";
  static const String and = "and";
  static const String orSignUpWith = "orSignUpWith";

  //otp screen

  static const String otpVerification = "otpVerification";
  static const String signInSubTitle = "signInSubTitle";
  static const String tContinue = "Continue";

  //6 digit otp screen

  static const String enter6digitOTPCode = "enter6digitOTPCode";
  static const String otpSubTitle = "otpSubTitle";
  static const String otpFooter = "otpFooter";
  static const String resendOTP = "resendOTP";
  static const String inText = "inText";

  // Forget password screen

  static const String forgetPasswordTitle = "forgetPasswordTitle";
  static const String forgetPasswordSubTitle = "forgetPasswordSubTitle";
  static const String submit = "Submit";

  //Reset Password screen

  static const String changeYourPasswordTitle = "changeYourPasswordTitle";
  static const String gmail = "gmail";
  static const String changeYourPasswordSubTitle = "changeYourPasswordSubTitle";
  static const String done = "done";
  static const String resendEmail = "Resend Email";

  // Verify Email

  static const String confirmEmail = "confirmEmail";
  static const String confirmEmailSubTitle = "confirmEmailSubTitle";

  // -- OnBoarding Texts
  static const String onBoardingTitle1 = "onBoardingTitle1";
  static const String onBoardingTitle2 = "onBoardingTitle2";
  static const String onBoardingTitle3 = "onBoardingTitle3";

  static const String onBoardingSubTitle1 = "onBoardingSubTitle1";
  static const String onBoardingSubTitle2 = "onBoardingSubTitle2";
  static const String onBoardingSubTitle3 = "onBoardingSubTitle3";
  static const String skip = "skip";

  //Home Screen
  static const String homeAppbarTitle = "homeAppbarTitle";
  static const String searchInStore = "searchInStore";
  /// Arama ekranının başlığı.
  static const String search = "search";
  static const String popularProducts = "Popular Products";
  static const String newArrivals = 'New Arrivals';
  static const String popularCategories = "popularCategories";
  static const String categories = "categories";
  static const String clearFilter = "clearFilter";
  /// `clearFilter` bir PARÇA ("… seçili · Temizle"), tek başına kullanılamaz.
  /// Süzgeç boşken mağaza çipi bu etiketi gösterir.
  static const String allCategories = "allCategories";
  static const String products = "products";
  static const String noDataFound = "noDataFound";

  // Home Promo Banner (slider2)
  static const String promoBanner1Title = "promoBanner1Title";
  static const String promoBanner1Subtitle = "promoBanner1Subtitle";
  static const String promoBanner2Title = "promoBanner2Title";
  static const String promoBanner2Subtitle = "promoBanner2Subtitle";
  static const String promoBanner3Title = "promoBanner3Title";
  static const String promoBanner3Subtitle = "promoBanner3Subtitle";
  static const String shopNow = "shopNow";

  // Ana sayfa kaydırmalı afişi (metinler web `home.slider*` ile birebir).
  // 🔴 Bunlar METİN DEĞİL çeviri anahtarı; slider listesi `const` kalabilsin
  // diye `.tr` çizim sırasında uygulanır.
  static const String sliderSubtitle1 = 'sliderSubtitle1';
  static const String sliderTitle1 = 'sliderTitle1';
  static const String sliderSubtitle2 = 'sliderSubtitle2';
  static const String sliderSubtitle2Accent = 'sliderSubtitle2Accent';
  static const String sliderTitle2 = 'sliderTitle2';
  static const String sliderDescription2 = 'sliderDescription2';
  static const String sliderSubtitle3 = 'sliderSubtitle3';
  static const String sliderTitle3 = 'sliderTitle3';

  // Product Detail - cart
  static const String addToBag = "addToBag";
  static const String quantity = "quantity";

  // Store filtering
  static const String sortBy = "sortBy";
  static const String filter = "filter";
  static const String apply = "apply";
  static const String clearAll = "clearAll";
  static const String selectAll = "selectAll";
  static const String searchCategory = "searchCategory";
  static const String priceRange = "priceRange";
  static const String lowestPrice = "lowestPrice";
  static const String highestPrice = "highestPrice";
  static const String sortName = "sortName";
  static const String sortPriceLow = "sortPriceLow";
  static const String sortPriceHigh = "sortPriceHigh";
  static const String sortNewest = "sortNewest";
  static const String sortPopular = "sortPopular";
  static const String loadMore = "loadMore";
  // FAZ 04 — web'deki sıralama listesiyle (shop.html) hizalamak için eklendi:
  // varsayılan · fiyat artan/azalan · yeni · popüler · puan.
  static const String sortDefault = "sortDefault";
  static const String sortRating = "sortRating";
  /// İndirimli ürünleri öne alan sıralama (referanstaki `'Sale'`).
  static const String sortSale = "sortSale";
  /// Ana sayfada her ürün bloğunun altındaki "daha fazla" düğmesi.
  static const String moreProducts = "moreProducts";
  /// Liste yüklenemediğinde gösterilen yeniden deneme düğmesi.
  static const String tryAgain = "tryAgain";
  /// Girişsiz kullanıcı kapısı (boş durum kutusunun başlığı). Sepet/favori/
  /// karşılaştırma sunucuda kullanıcıya bağlıdır; misafire BOŞ liste değil
  /// "önce giriş yapın" gösterilir.
  static const String signInRequired = "signInRequired";

  // Store

  static const String featuredBrands = "featuredBrands";
  static const String youMightLike = "youMightLike";
  static const String tStore = "tStore";

  //Wishlist

  static const String wishlist = "wishlist";

  /// İstek listesinin kullanıcıya görünen adı: "Beğenilen Ürünler".
  /// Liste artık alt gezinmede değil profil sekmesinin içinde.
  static const String myCollection = "myCollection";
  static const String likedProducts = "likedProducts";
  static const String likedProductsSubTitle = "likedProductsSubTitle";
  static const String comparisonSubTitle = "comparisonSubTitle";
  static const String wishlistEmpty = "wishlistEmpty";
  static const String letsAddSome = "letsAddSome";

  //Settings

  static const String account = "account";
  static const String accountSetting = "accountSetting";
  static const String myAddress = "myAddress";
  static const String addressSubTitle = "addressSubTitle";
  static const String myCart = "myCart";
  static const String cartSubTitle = "cartSubTitle";
  static const String myOrders = "myOrders";
  static const String ordersSubTitle = "ordersSubTitle";
  static const String requestsSubTitle = "requestsSubTitle";
  static const String bankAccount = "bankAccount";
  static const String bankAccountSubTitle = "bankAccountSubTitle";
  static const String myCoupons = "myCoupons";
  static const String myCouponsSubTitle = "myCouponsSubTitle";
  static const String notifications = "notifications";
  static const String notificationsSubTitle = "notificationsSubTitle";
  static const String accountPrivacy = "accountPrivacy";
  static const String accountPrivacySubTitle = "accountPrivacySubTitle";

  static const String appSetting = "appSetting";
  static const String loadData = "loadData";
  static const String loadDataSubTitle = "loadDataSubTitle";
  static const String chat = "chat";
  static const String chatSubTitle = "chatSubTitle";
  static const String geolocation = "geolocation";
  static const String geolocationSubTitle = "geolocationSubTitle";
  static const String safeMode = "safeMode";
  static const String safeModeSubTitle = "safeModeSubTitle";
  static const String hdImage = "hdImage";
  static const String hdImageSubTitle = "hdImageSubTitle";
  static const String logout = "logout";
  static const String saveSettings = "saveSettings";
  static const String languages = 'Languages';
  static const String searchLanguage = "Search languages...";

  //Profile

  static const String profile = "profile";
  static const String profileInfo = "profileInfo";
  static const String name = "name";
  static const String personalInfo = "personalInfo";
  static const String userId = "userId";
  static const String gender = "gender";
  static const String dateOfBirth = "dateOfBirth";
  static const String closeAccount = "closeAccount";
  static const String changeProfilePic = "changeProfilePic";

  //Orders

  static const String whoopsNoOrder = "whoopsNoOrder";
  static const String letsFillIt = "letsFillIt";
  static const String order = "order";
  static const String shippingDate = "shippingDate";
  static const String orderDetails = "orderDetails";
  static const String shippingAddress = "shippingAddress";
  static const String address = "address";
  static const String billingAddress = "billingAddress";
  static const String billingAddressSubTitle = "billingAddressSubTitle";
  static const String deliveryStatus = "deliveryStatus";
  static const String orderCancelled = "orderCancelled";
  static const String completed = "completed";
  static const String orderPlaced = "orderPlaced";
  static const String processing = "processing";
  static const String shipped = "shipped";
  static const String delivered = "delivered";
  static const String returned = "returned";
  static const String refunded = "refunded";
  static const String cancelled = "cancelled";
  static const String arrived = "arrived";
  static const String pending = "pending";
  static const String inProgress = "inProgress";
  static const String onTheWay = "onTheWay";
  static const String orderSummary = "orderSummary";
  static const String orderId = "orderId";
  static const String placeOn = "placeOn";
  static const String grandTotal = "grandTotal";
  static const String orderStatus = "orderStatus";
  static const String items = "items";
  static const String paymentDetails = "paymentDetails";
  static const String subTotal = "subTotal";
  static const String deliveryFee = "deliveryFee";
  static const String taxAmount = "taxAmount";
  static const String total = "total";
  static const String paymentMethod = "paymentMethod";
  static const String cashOnDelivery = "cashOnDelivery";
  static const String returnAndExchange = 'returnAndExchange';
  static const String returnRequest = 'returnRequest';
  static const String requestedDate = 'requestedDate';
  static const String requestType = 'requestType';
  static const String returnRequestSubTitle = 'returnRequestSubTitle';


  // Checkout
  static const String checkOut = "checkOut";
  static const String emptyCart = "emptyCart";
  static const String cartMessage = "cartMessage";
  static const String change = "change";
  static const String selectAddress = "selectAddress";

  //Cart
  static const String cart = "cart";
  static const String whoopCartEmpty = "whoopCartEmpty";

  //Review
  static const String purchaseQuality = "purchaseQuality";
  static const String outfitFeedback = "outfitFeedback";
  static const String shareThought = "shareThought";
  static const String cancel = "cancel";

  //Product Details

  static const String description = "description";
  static const String showMore = "showMore";
  static const String less = "less";
  static const String reviews = "reviews";
  static const String variation = "variation";
  static const String price = "price";
  /// Fiyati misafirden gizli urunde fiyatin yerine gecen metin.
  /// Sunucu boyle urunde Price=0 gonderir; "0" basmak yerine bu kullanilir.
  static const String priceOnRequest = "priceOnRequest";
  static const String stock = "stock";
  static const String allReview = "allReview";
  static const String noReview = "noReview";
  static const String showLess = "showLess";

  // Compare
  static const String comparison = "comparison";
  static const String comparisonEmpty = "comparisonEmpty";
  static const String comparisonAddProducts = "comparisonAddProducts";
  static const String startShopping = "startShopping";
  static const String availability = "availability";
  static const String category = "category";
  static const String color = "color";
  static const String size = "size";
  static const String weight = "weight";
  static const String dimensions = "dimensions";
  static const String productAddedToCompare = "productAddedToCompare";
  static const String productRemovedFromCompare = "productRemovedFromCompare";
  static const String compareSameCategory = "compareSameCategory";
  static const String compareLimitReached = "compareLimitReached";
  static const String alreadyInCompare = "alreadyInCompare";

  // Product Specifications
  static const String specifications = "specifications";
  static const String stockStatus = "stockStatus";
  static const String unitWeight = "unitWeight";
  static const String weightNet = "weightNet";
  static const String weightGross = "weightGross";
  static const String width = "width";
  static const String height = "height";
  static const String depth = "depth";
  static const String volume = "volume";
  static const String unitsPerBox = "unitsPerBox";

  // Controller TEXT
  static const String processingRequest = "processingRequest";
  static const String emailSent = "emailSent";
  static const String emailSentMessage = "emailSentMessage";
  static const String ohSnap = "ohSnap";
  static const String emailResetPassword = "emailResetPassword";
  static const String loggingYouIn = "loggingYouIn";
  static const String noInternetAccess = "noInternetAccess";
  static const String weAreProcessingInformation = "weAreProcessingInformation";
  static const String acceptPrivacyPolicy = "acceptPrivacyPolicy";
  static const String acceptPrivacyPolicyMessage = "acceptPrivacyPolicyMessage";
  static const String congratulation = "congratulation";
  static const String congratulationMessage = "congratulationMessage";
  static const String emailCheckVerify = "emailCheckVerify";
  static const String unableFindChat = "unableFindChat";
  static const String unableFetchMessage = "unableFetchMessage";
  static const String unableSendMessage = "unableSendMessage";
  static const String permissionError = "permissionError";
  static const String failMicrophonePermission = "failMicrophonePermission";
  static const String recordingError = "recordingError";
  static const String failToRecord = "failToRecord";
  static const String pauseError = "pauseError";
  static const String failToPauseRecord = "failToPauseRecord";
  static const String stopError = "stopError";
  static const String failToStopRecord = "Failed to stop recording.";
  static const String cancelError = "cancelError";
  static const String failToCancelRecord = "failToCancelRecord";
  static const String addressNotFound = "addressNotFound";
  static const String errorInSelection = "errorInSelection";
  static const String storingAddress = "storingAddress";
  static const String addressSaveSuccess = "addressSaveSuccess";
  static const String updatingAddress = "updatingAddress";
  static const String addressUpdated = "addressUpdated";
  static const String errorUpdatedAddress = "errorUpdatedAddress";
  static const String unableToFetchNotification = "unableToFetchNotification";
  static const String error = "error";
  static const String failToFetchNotification = "failToFetchNotification";
  static const String markNotificationAsSeen = "markNotificationAsSeen";
  static const String somethingWentWrong = "somethingWentWrong";
  static const String updatingInformation = "updatingInformation";
  static const String nameUpdated = "nameUpdated";
  static const String failToUpdateUserRecord = "failToUpdateUserRecord";
  static const String profileImageUpdated = "profileImageUpdated";
  static const String deleteAccount = "deleteAccount";
  static const String deleteAccountSubText = "deleteAccountSubText";
  static const String delete = "delete";
  static const String sureLogout = "sureLogout";
  static const String confirm = "confirm";
  static const String selectVariations = "selectVariations";
  static const String selectVariationsOutOfStock = "selectVariationsOutOfStock";
  static const String selectProductOutOfStock = "selectProductOutOfStock";
  static const String productAddedToCart = "productAddedToCart";
  static const String removeProduct = "removeProduct";
  static const String removeProductSure = "removeProductSure";
  static const String productRemoveFromCart = "productRemoveFromCart";
  static const String removeStoreCartProduct = "removeStoreCartProduct";
  static const String selectPaymentMethod = "selectPaymentMethod";
  static const String visaMasterCard = "visaMasterCard";
  static const String paypal = "paypal";
  static const String productAddedToWishlist = "productAddedToWishlist";
  static const String productRemoveFromWishlist = "productRemoveFromWishlist";
  static const String close = "close";
  static const String unableFetchOrderDetail = "unableFetchOrderDetail";
  static const String addressRequired = "addressRequired";
  static const String addressRequiredMessage = "addressRequiredMessage";
  static const String billingAddressRequired = "billingAddressRequired";
  static const String billingAddressRequiredMessage = "billingAddressRequiredMessage";
  static const String processingYourOrder = "processingYourOrder";
  static const String orderCreateSuccessfully = "orderCreateSuccessfully";
  static const String orderSuccess = "orderSuccess";
  static const String orderSuccessSubTitle = "orderSuccessSubTitle";
  static const String orderPlacedSuccess = "orderPlacedSuccess";
  static const String paymentFailed = "paymentFailed";
  static const String inStock = "inStock";
  static const String outOfStock = "outOfStock";
  static const String preOrder = "preOrder";
  static const String typing = "typing";

  // -- User credit (admin-managed credit limit)
  static const String credit = "credit";
  static const String creditLimit = "creditLimit";
  static const String usedCredit = "usedCredit";
  static const String availableCredit = "availableCredit";
  static const String creditLimitExceeded = "creditLimitExceeded";
  static const String creditLimitExceededMessage = "creditLimitExceededMessage";

  // -- Minimum order amount (admin-managed, 0 = disabled)
  static const String minimumOrderAmount = "minimumOrderAmount";
  static const String minimumOrderNotMet = "minimumOrderNotMet";
  static const String minimumOrderNotMetMessage = "minimumOrderNotMetMessage";
  static const String minimumOrderRequired = "minimumOrderRequired";
  static const String minimumOrderRemaining = "minimumOrderRemaining";

  // -- Checkout: card entry & on-account (CanBypassPayment) ordering
  static const String bankTransfer = "bankTransfer";
  static const String enterCardDetails = "enterCardDetails";
  static const String cardHolderName = "cardHolderName";
  static const String cardNumber = "cardNumber";
  static const String expiryDate = "expiryDate";
  static const String cvv = "cvv";
  static const String invalidCardDetails = "invalidCardDetails";
  static const String invalidCardDetailsMessage = "invalidCardDetailsMessage";
  static const String payOnAccount = "payOnAccount";
  static const String payOnAccountNote = "payOnAccountNote";

  // -- Checkout: bank transfer details (CanBypassPayment users)
  static const String bankTransferTitle = "bankTransferTitle";
  static const String bankTransferNote = "bankTransferNote";
  static const String bankBeneficiary = "bankBeneficiary";
  static const String bankIban = "bankIban";
  static const String bankBin = "bankBin";
  static const String bankBik = "bankBik";
  static const String bankKbe = "bankKbe";
  static const String bankCopy = "bankCopy";
  static const String bankCopied = "bankCopied";
  static const String bankOther = "bankOther";

  // -- FAZ 34: ödeme modu `transfer_only` + şirket başına rekvizitler
  /// Genel `transfer_only` modundaki KREDİSİZ müşteriye gösterilen başlık.
  /// Kredili müşteri bugünkü kredi kutusunu görmeye devam eder — ona
  /// "hesabınıza tanımlı kredi" demek doğru, kredisize demek yanlış olurdu.
  static const String bankTransferOnlyTitle = "bankTransferOnlyTitle";
  static const String bankTransferOnlyNote = "bankTransferOnlyNote";

  /// Sepet birden çok şirkete bölündüğünde rekvizitlerin üstündeki açıklama.
  static const String bankPerCompanyNote = "bankPerCompanyNote";

  /// O şirketin hiç aktif hesabı yok — blok sessizce boş bırakılmaz.
  static const String bankMissing = "bankMissing";

  /// Liste okunamadı. "Hesap yok" ile aynı şey DEĞİL: biri veri, öteki hata.
  static const String bankLoadError = "bankLoadError";

  /// Sipariş detayındaki havale açıklaması.
  static const String bankTransferOrderNote = "bankTransferOrderNote";

  // -- FAZ 34: kayıt anahtarları (K29.2 — kapalı bölüm HİÇ görünmez)
  static const String registrationClosedTitle = "registrationClosedTitle";
  static const String registrationClosedText = "registrationClosedText";

  /// Yalnız BİR kayıt tipi kapandığında (sunucudan 403 + `errorCode`).
  static const String registrationTypeClosed = "registrationTypeClosed";

  // -- Checkout: Halyk ePay secure payment
  static const String securePaymentTitle = "securePaymentTitle";
  static const String securePaymentNote = "securePaymentNote";
  static const String securePaymentScreenTitle = "securePaymentScreenTitle";
  static const String redirectingToPayment = "redirectingToPayment";
  static const String paymentCancelled = "paymentCancelled";
  static const String paymentModuleNotLoaded = "paymentModuleNotLoaded";
  static const String thisOrder = "thisOrder";
  static const String remainingAfterOrder = "remainingAfterOrder";
  static const String orderPlacedSubTitle = "orderPlacedSubTitle";
  static const String orderNo = "orderNo";
  static const String viewOrder = "viewOrder";
  static const String continueShopping = "continueShopping";
  static const String paymentVerifying = "paymentVerifying";
  static const String paymentConfirmed = "paymentConfirmed";
  static const String paymentNotConfirmed = "paymentNotConfirmed";
  static const String noMoreCoupon = "noMoreCoupon";
  static const String couponApplied = "couponApplied";
  static const String great = "great";
  static const String giveRating = "giveRating";
  static const String success = "success";
  static const String reviewSubmitted = "reviewSubmitted";
  static const String yourReviewSubmitted = "yourReviewSubmitted";
  static const String reviewSubmit = "reviewSubmit";

  static const String categoryUploadingSitTight = "categoryUploadingSitTight";
  static const String allCategoriesUpload = "allCategoriesUpload";
  static const String productCategoryUploading = "productCategoryUploading";
  static const String sitTightBrandUpload = "sitTightBrandUpload";
  static const String allBrandUploaded = "allBrandUploaded";
  static const String brandCategoryUploading = "brandCategoryUploading";
  static const String productsUploading = "productsUploading";
  static const String productUploaded = "productUploaded";
  static const String bannersUploading = "bannersUploading";

  //Repositories

  static const String unableUserInformation = "unableUserInformation";
  static const String wrongFetchingAddress = "wrongFetchingAddress";
  static const String wrongSavingAddress = "wrongSavingAddress";
  static const String unableUpdateAddress = "unableUpdateAddress";
  static const String somethingWrongTryAgain = "somethingWrongTryAgain";
  static const String tooManyAttempts = "tooManyAttempts";
  static const String tooManyAttemptsMessage = "tooManyAttemptsMessage";
  static const String smaNotSent = "smaNotSent";
  static const String smaNotSentMessage = "smaNotSentMessage";
  static const String somethingWrongOrderInfo = "somethingWrongOrderInfo";

  // -- GLOBAL Texts
  static const String appName = "T-Store";

  // -- Authentication Forms

  static const String newPassword = "New Password";
  static const String orSignInWith = "or sign in with";
  static const String verificationCode = "verificationCode";
  static const String resendEmailIn = "Resend email in";
  static const String couponCodeOrVouchers = "Apply Coupon/Vouchers";

  // -- Authentication Headings

  static const String emailNotReceivedMessage = "Didn’t get the email? Check your junk/spam or resend it.";
  static const String yourAccountCreatedTitle = "Your account successfully created!";
  static const String yourAccountCreatedSubTitle =
      "Welcome to Your Ultimate Shopping Destination: Your Account is Created, Unleash the Joy of Seamless Online Shopping!";

  // -- Product

  // -- Home
  static const String homeAppbarSubTitle = "Taimoor Sikander";
  static const String signupScreenTitle = "Welcome Aboard";

  static const String signupScreenSubTitle = "A one-time SMS will be sent for verification";
  static const String unableToSendOTP = "Unable to send OTP";
  static const String otpSendTitle = "OTP Send";
  static const String otpSendMessage = "OTP Send to your phone number successfully.";
  static const String invalidPin = "Invalid Pin";
  static const String inValidPinMessage = "inValidPinMessage";
  static const String pinCharacters = "Pin should be 4 Characters Long";
  static const String congratulations = "Congratulations";
  static const String pinCodeSuccessMessage = "Your Pin Code has been saved successfully.";
  static const String updatingPin = "Updating Pin...";
  static const String storingPin = "Storing Pin...";
  static const String failedToUpdateUserRecord = "Failed to update user record";
  static const String selectCountryCode = "Select Country Code";
  static const String sendingOTP = "Sending OTP";
  static const String performingPhoneAuth = "Performing Phone Authentication";
  static const String phoneVerifiedTitle = "Phone Verified";
  static const String phoneVerifiedMessage = "Your phone number has been verified.";
  static const String noInternet = "No Internet";
  static const String checkInternetConnection = "Please check your internet connection and try again.";

  static const String enter4digitPINCode = "enter4digitPINCode";
  static const String pinCodeMessage = "pinCodeMessage";
  static const String setPin = "Set Pin";
  static const String updatePinCode = "update Pin Code";
  static const String updatePinCodeMessage = "update Pin Code Message";
  static const String updatePin = "Update Pin";
  static const String verifyPin = "Verify Pin";
  static const String verifyPINCode = "verify PIN Code";
  static const String verifyPinCodeMessage = "verifyPinCodeMessage";

  static const String thenLets = "Then let’s";

  //exceptions
  static const String emailAlreadyRegistered = "emailAlreadyRegistered";
  static const String invalidEmail = "invalidEmail";
  static const String weakPassword = "weakPassword";
  static const String userDisabled = "userDisabled";
  static const String invalidLoginDetails = "invalidLoginDetails";
  static const String incorrectPassword = "incorrectPassword ";
  static const String invalidLoginCredentials = "invalidLoginCredentials ";
  static const String tooManyRequests = "tooManyRequests ";
  static const String invalidAuthArgument = "invalidAuthArgument";
  static const String incorrectPasswordTryAgain = "incorrectPasswordTryAgain ";
  static const String invalidPhoneNumber = "invalidPhoneNumber";
  static const String signInProviderDisabled = "signInProviderDisabled";
  static const String sessionExpired = "sessionExpired ";
  static const String userIdAlreadyInUse = "userIdAlreadyInUse ";
  static const String signInFailed = "signInFailed ";
  static const String networkRequestFailed = "networkRequestFailed ";
  static const String internalError = "internalError ";
  static const String invalidVerificationCode = "invalidVerificationCode ";
  static const String invalidVerificationId = "invalidVerificationId ";
  static const String quotaExceeded = "quotaExceeded";
  // Firebase Auth Exception
  static const emailAlreadyInUse = "emailAlreadyInUse";
  static const userNotFound = "userNotFound";
  static const wrongPassword = "wrongPassword";
  static const emailAlreadyExists = "emailAlreadyExists";
  static const providerAlreadyLinked = "providerAlreadyLinked";
  static const requiresRecentLogin = "requiresRecentLogin";
  static const credentialAlreadyInUse = "credentialAlreadyInUse";
  static const userMismatch = "userMismatch";
  static const accountExistsWithDifferentCredential = "accountExistsWithDifferentCredential";
  static const operationNotAllowed = "operationNotAllowed";
  static const expiredActionCode = "expiredActionCode";
  static const invalidActionCode = "invalidActionCode";
  static const missingActionCode = "missingActionCode";
  static const userTokenExpired = "userTokenExpired";
  static const invalidCredential = "invalidCredential";
  static const userTokenRevoked = "userTokenRevoked";
  static const invalidMessagePayload = "invalidMessagePayload";
  static const invalidSender = "invalidSender";
  static const invalidRecipientEmail = "invalidRecipientEmail";
  static const missingIframeStart = "missingIframeStart";
  static const missingIframeEnd = "missingIframeEnd";
  static const missingIframeSrc = "missingIframeSrc";
  static const authDomainConfigRequired = "authDomainConfigRequired";
  static const missingAppCredential = "missingAppCredential";
  static const invalidAppCredential = "invalidAppCredential";
  static const sessionCookieExpired = "sessionCookieExpired";
  static const uidAlreadyExists = "uidAlreadyExists";
  static const invalidCordovaConfiguration = "invalidCordovaConfiguration";
  static const appDeleted = "appDeleted";
  static const userTokenMismatch = "userTokenMismatch";
  static const webStorageUnsupported = "webStorageUnsupported";
  static const appNotAuthorized = "appNotAuthorized";
  static const keychainError = "keychainError";
  static const internalAuthError = "internalAuthError";
  static const unexpectedAuthError = "unexpectedAuthError";


  static const firebaseUnknownError = "firebaseUnknownError";
  static const invalidCustomTokenFormat = "invalidCustomTokenFormat";
  static const customTokenAudienceMismatch = "customTokenAudienceMismatch";
  static const firebaseUserDisabled = "firebaseUserDisabled";
  static const firebaseUserNotFound = "firebaseUserNotFound";
  static const firebaseInvalidEmail = "firebaseInvalidEmail";
  static const firebaseEmailAlreadyInUse = "firebaseEmailAlreadyInUse";
  static const firebaseWrongPassword = "firebaseWrongPassword";
  static const firebaseWeakPassword = "firebaseWeakPassword";
  static const firebaseProviderAlreadyLinked = "firebaseProviderAlreadyLinked";
  static const firebaseOperationNotAllowed = "firebaseOperationNotAllowed";
  static const firebaseInvalidCredential = "firebaseInvalidCredential";
  static const firebaseInvalidVerificationCode = "firebaseInvalidVerificationCode";
  static const firebaseInvalidVerificationId = "firebaseInvalidVerificationId";
  static const firebaseCaptchaCheckFailed = "firebaseCaptchaCheckFailed";
  static const firebaseAppNotAuthorized = "firebaseAppNotAuthorized";
  static const firebaseKeychainError = "firebaseKeychainError";
  static const firebaseInternalError = "firebaseInternalError";
  static const firebaseInvalidAppCredential = "firebaseInvalidAppCredential";
  static const firebaseUserCredentialMismatch = "firebaseUserCredentialMismatch";
  static const firebaseRequiresRecentLogin = "firebaseRequiresRecentLogin";
  static const firebaseQuotaExceeded = "firebaseQuotaExceeded";
  static const firebaseAccountExistsWithDifferentCredential = "firebaseAccountExistsWithDifferentCredential";
  static const firebaseMissingIframeStartTag = "firebaseMissingIframeStartTag";
  static const firebaseMissingIframeEndTag = "firebaseMissingIframeEndTag";
  static const firebaseMissingIframeSrc = "firebaseMissingIframeSrc";
  static const firebaseAuthDomainConfigRequired = "firebaseAuthDomainConfigRequired";
  static const firebaseMissingAppCredential = "firebaseMissingAppCredential";
  static const firebaseSessionCookieExpired = "firebaseSessionCookieExpired";
  static const firebaseUidAlreadyExists = "firebaseUidAlreadyExists";
  static const firebaseWebStorageUnsupported = "firebaseWebStorageUnsupported";
  static const firebaseAppDeleted = "firebaseAppDeleted";
  static const firebaseUserTokenMismatch = "firebaseUserTokenMismatch";
  static const firebaseInvalidMessagePayload = "firebaseInvalidMessagePayload";
  static const firebaseInvalidEmailSender = "firebaseInvalidEmailSender";
  static const firebaseInvalidRecipientEmail = "firebaseInvalidRecipientEmail";
  static const firebaseMissingActionCode = "firebaseMissingActionCode";
  static const firebaseUserTokenExpired = "firebaseUserTokenExpired";
  static const firebaseInvalidLoginCredentials = "firebaseInvalidLoginCredentials";
  static const firebaseExpiredActionCode = "firebaseExpiredActionCode";
  static const firebaseInvalidActionCode = "firebaseInvalidActionCode";
  static const firebaseCredentialAlreadyInUse = "firebaseCredentialAlreadyInUse";
  static const firebaseUnexpectedError = "firebaseUnexpectedError";

  //platform exception

  static const authInvalidCredentials = 'authInvalidCredentials';
  static const authTooManyRequests = 'authTooManyRequests';
  static const authInvalidArgument = 'authInvalidArgument';
  static const authInvalidPassword = 'authInvalidPassword';
  static const authInvalidPhoneNumber = 'authInvalidPhoneNumber';
  static const authSignInMethodDisabled = 'authSignInMethodDisabled';
  static const authSessionCookieExpired = 'authSessionCookieExpired';
  static const authUserIdAlreadyExists = 'authUserIdAlreadyExists';
  static const authSignInFailed = 'authSignInFailed';
  static const authNetworkFailure = 'authNetworkFailure';
  static const authInternalError = 'authInternalError';
  static const authInvalidVerificationCode = 'authInvalidVerificationCode';
  static const authInvalidVerificationId = 'authInvalidVerificationId';
  static const authQuotaExceeded = 'authQuotaExceeded';
  static const authUnexpectedPlatformError = 'authUnexpectedPlatformError';


  // ── FAZ 26: çoklu sipariş (sepet şirket kırılımı, alışveriş, ödeme) ──
  static const String otherCompany = "otherCompany";
  static const String cartSplitNote = "cartSplitNote";
  static const String purchaseNumber = "purchaseNumber";
  static const String ordersCreated = "ordersCreated";
  static const String totalPayment = "totalPayment";
  static const String paymentCoversOrders = "paymentCoversOrders";
  static const String ordersInPurchase = "ordersInPurchase";
  static const String partOfPurchase = "partOfPurchase";
  static const String company = "company";
  static const String completePayment = "completePayment";
  static const String orderAlreadyPaid = "orderAlreadyPaid";
  static const String orderPlacedNotPaidYet = "orderPlacedNotPaidYet";
  static const String orderPlacedNotificationBody = "orderPlacedNotificationBody";
  static const String paymentPaid = "paymentPaid";
  static const String paymentUnpaid = "paymentUnpaid";
  static const String paymentFailedShort = "paymentFailedShort";
  static const String paymentRefunded = "paymentRefunded";
  static const String statusPending = "statusPending";
  static const String statusConfirmed = "statusConfirmed";
  static const String statusProcessing = "statusProcessing";
  static const String statusShipped = "statusShipped";
  static const String statusDelivered = "statusDelivered";
  static const String statusCancelled = "statusCancelled";
  static const String statusReturned = "statusReturned";
  static const String statusRefunded = "statusRefunded";

  // -- FAZ 05: ürün detayı ve değerlendirmeler.
  // 🔴 FAZ 11 bunları 10 sözlüğe de eklemeli, yoksa ekranda anahtar adı görünür.

  static const String sku = "sku";
  static const String barcode = "barcode";
  static const String vat = "vat";
  static const String model = "model";
  static const String relatedProducts = "relatedProducts";
  static const String noDescription = "noDescription";
  static const String noReviewsYet = "noReviewsYet";
  static const String writeReview = "writeReview";
  static const String editReview = "editReview";
  static const String reviewNeedPurchase = "reviewNeedPurchase";
  static const String reviewAlreadyExists = "reviewAlreadyExists";
  static const String reviewFailed = "reviewFailed";
  static const String productNotFound = "productNotFound";

  // -- FAZ 06: sepet · favori · karşılaştırma · kupon ----------------------
  // Girişsiz kullanıcı kapısı: sepet/favori/karşılaştırma sunucuda kullanıcıya
  // bağlıdır, misafire BOŞ liste değil "önce giriş yapın" gösterilir
  // (`signInRequired` FAZ 03'te tanımlandı).
  static const String cartLoginText = "cartLoginText";
  static const String wishlistLoginText = "wishlistLoginText";
  static const String compareLoginText = "compareLoginText";

  /// Boş durum açıklamaları (TASARIM.md §6: başlık + açıklama + tek düğme).
  static const String cartEmptyText = "cartEmptyText";
  static const String wishlistEmptyText = "wishlistEmptyText";
  static const String comparisonEmptyText = "comparisonEmptyText";
  static const String couponEmpty = "couponEmpty";
  static const String couponEmptyText = "couponEmptyText";

  /// Karşılaştırma tablosunun satır başlıkları.
  static const String rating = "rating";
  static const String actions = "actions";
  static const String remove = "remove";

  /// Favorilerde toplu işlem. `addedToCartCount` `trParams` ile `{count}` alır.
  static const String addAllToCart = "addAllToCart";
  static const String noneInStock = "noneInStock";
  static const String addedToCartCount = "addedToCartCount";

  /// Kupon ekranı.
  static const String coupon = "coupon";
  static const String couponCode = "couponCode";
  static const String redeemCoupon = "redeemCoupon";

  /// Favori isteği sunucuda başarısız olunca gösterilen uyarılar; ayna geri
  /// alınırken kullanıcıya sebep söylenmeli, kalp sessizce sönmemeli.
  static const String wishlistAddFailed = 'wishlistAddFailed';
  static const String wishlistRemoveFailed = 'wishlistRemoveFailed';


  // -- FAZ 07: ödeme ekranı ------------------------------------------------
  /// Fatura özeti satırları (referansta İngilizce gömülüydü; FAZ 11 sözlüğe
  /// eklesin diye anahtarlaştırıldı).
  static const String shippingFee = "shippingFee";
  static const String taxFee = "taxFee";
  static const String orderTotal = "orderTotal";
  static const String free = "free";

  /// Ödeme yöntemi seçici (yalnız `gateway` modunda çizilir).
  static const String paymentMethods = "paymentMethods";
  static const String creditCard = "creditCard";
  static const String creditCardText = "creditCardText";
  static const String bankTransferText = "bankTransferText";
  static const String cashOnDeliveryText = "cashOnDeliveryText";
  static const String paymentPendingApproval = "paymentPendingApproval";
  static const String paymentPendingApprovalText = "paymentPendingApprovalText";

  /// Sipariş notu (sunucuya `CustomerNote` olarak gider).
  static const String orderNotes = "orderNotes";
  static const String orderNotesPlaceholder = "orderNotesPlaceholder";

  /// Limit kutusu — düğme kapalıyken sebebini yazan metinler.
  static const String cartTotal = "cartTotal";
  static const String orderBlockedTitle = "orderBlockedTitle";

  /// Adres formu (FAZ 09'un ekranları erken geldi; bkz. DURUM.md).
  static const String street = "street";
  static const String addressLine2 = "addressLine2";
  static const String postalCode = "postalCode";
  static const String city = "city";
  static const String state = "state";
  static const String country = "country";
  static const String save = "save";
  static const String addNewAddress = "addNewAddress";
  static const String updateAddress = "updateAddress";
  static const String billingAddressLocked = "billingAddressLocked";

  /// Adres silme (FAZ 09'un metinleri; `AddressController` onlarla birlikte
  /// erken geldiği için burada).
  static const String deleteAddress = "deleteAddress";
  static const String deleteAddressMessage = "deleteAddressMessage";
  static const String addressDeleted = "addressDeleted";
  static const String addressDeleteFailed = "addressDeleteFailed";


  // ── FAZ 08 — siparişler, sipariş takibi, iade talepleri ────────────────
  // Referans ekranlarda bu metinlerin çoğu İngilizce GÖMÜLÜYDÜ; FAZ 11
  // sözlüklere ekleyebilsin diye anahtarlaştırıldı.

  /// Sipariş listesi (alışveriş = grup)
  static const String view = "view";
  static const String orderItems = "orderItems";
  static const String orderNoItems = "orderNoItems";
  static const String orderItemsLoadError = "orderItemsLoadError";
  static const String orderNumber = "orderNumber";
  static const String orderCount = "orderCount";
  static const String paymentStatus = "paymentStatus";

  /// Sipariş detayı — grup görünümü
  static const String purchaseDetails = "purchaseDetails";
  static const String subOrders = "subOrders";
  static const String groupSplitNote = "groupSplitNote";
  static const String viewWholePurchase = "viewWholePurchase";
  static const String purchaseNotFound = "purchaseNotFound";
  static const String orderNotFound = "orderNotFound";
  static const String backToOrders = "backToOrders";

  /// Sipariş detayı — kargo bilgisi (yalnız sunucu doldurduysa çizilir)
  static const String shippingCompany = "shippingCompany";
  static const String trackingNumber = "trackingNumber";
  static const String shippedAt = "shippedAt";
  static const String deliveredAt = "deliveredAt";

  /// Sipariş detayı — özet ve geçmiş
  static const String discount = "discount";
  static const String orderHistory = "orderHistory";
  static const String historyChangedBy = "historyChangedBy";
  static const String unitPrice = "unitPrice";
  static const String cancelOrder = "cancelOrder";
  static const String cancelOrderConfirm = "cancelOrderConfirm";
  static const String returnOrder = "returnOrder";
  static const String reviewProduct = "reviewProduct";
  static const String reviewed = "reviewed";
  static const String edit = "edit";

  /// İade talebi — oluşturma
  static const String returnPolicy = "returnPolicy";
  static const String returnPolicyText = "returnPolicyText";
  static const String returnType = "returnType";
  static const String returnForRefund = "returnForRefund";
  static const String returnExchange = "returnExchange";
  static const String returnAndExchangeType = "returnAndExchangeType";
  static const String selectItemsToReturn = "selectItemsToReturn";
  static const String selectItemsToReturnText = "selectItemsToReturnText";
  static const String reasonForReturn = "reasonForReturn";
  static const String selectReason = "selectReason";
  static const String additionalDetails = "additionalDetails";
  static const String additionalDetailsHint = "additionalDetailsHint";
  static const String submitReturnRequest = "submitReturnRequest";
  static const String returnPhotos = "returnPhotos";
  static const String returnPhotosHint = "returnPhotosHint";
  static const String photoUrlHint = "photoUrlHint";
  static const String addPhoto = "addPhoto";

  /// İade sebepleri
  static const String reasonDamagedProduct = "reasonDamagedProduct";
  static const String reasonWrongItem = "reasonWrongItem";
  static const String reasonSizeIssue = "reasonSizeIssue";
  static const String reasonQualityIssue = "reasonQualityIssue";
  static const String reasonNotAsDescribed = "reasonNotAsDescribed";
  static const String reasonChangedMind = "reasonChangedMind";
  static const String reasonOther = "reasonOther";

  /// İade durumları
  static const String returnStatusRequested = "returnStatusRequested";
  static const String returnStatusUnderReview = "returnStatusUnderReview";
  static const String returnStatusApproved = "returnStatusApproved";
  static const String returnStatusRejected = "returnStatusRejected";
  static const String returnStatusRefundProcessed = "returnStatusRefundProcessed";
  static const String returnStatusExchangeProcessed = "returnStatusExchangeProcessed";
  static const String returnStatusCompleted = "returnStatusCompleted";
  static const String returnStatusCanceled = "returnStatusCanceled";

  /// İade talebi — ilerleme adımları
  static const String returnStepRequested = "returnStepRequested";
  static const String returnStepReview = "returnStepReview";
  static const String returnStepAction = "returnStepAction";
  static const String returnStepFinalized = "returnStepFinalized";

  /// İade talebi — detay bölümleri
  static const String requestId = "requestId";
  static const String requestOverview = "requestOverview";
  static const String photoEvidence = "photoEvidence";
  static const String adminResponse = "adminResponse";
  static const String shipmentTracking = "shipmentTracking";
  static const String requestTimeline = "requestTimeline";
  static const String requestedResolution = "requestedResolution";
  static const String returnReason = "returnReason";
  static const String customerNotes = "customerNotes";
  static const String respondedOn = "respondedOn";
  static const String returnTrackingNumber = "returnTrackingNumber";
  static const String exchangeTrackingNumber = "exchangeTrackingNumber";
  static const String exchangeCarrier = "exchangeCarrier";
  static const String requestSubmitted = "requestSubmitted";
  static const String requestApproved = "requestApproved";
  static const String requestRejected = "requestRejected";
  static const String refundProcessed = "refundProcessed";
  static const String exchangeShipped = "exchangeShipped";
  static const String returnProcessCompleted = "returnProcessCompleted";
  static const String imageLoadFailed = "imageLoadFailed";

  /// İade talebi — eylemler ve uyarılar
  static const String cancelRequest = "cancelRequest";
  static const String cancelRequestHint = "cancelRequestHint";
  static const String cancelRequestConfirmTitle = "cancelRequestConfirmTitle";
  static const String cancelRequestConfirmMessage = "cancelRequestConfirmMessage";
  static const String keepRequest = "keepRequest";
  static const String yesCancelIt = "yesCancelIt";
  static const String returnApprovedHint = "returnApprovedHint";
  static const String returnRejectedHint = "returnRejectedHint";
  static const String returnCompletedHint = "returnCompletedHint";
  static const String returnCanceledHint = "returnCanceledHint";
  static const String contactSupport = "contactSupport";
  static const String trackStatus = "trackStatus";
  static const String returnRequestCancelled = "returnRequestCancelled";

  /// İade talebi — hata ve boş durumlar
  static const String returnSelectItemError = "returnSelectItemError";
  static const String returnDescriptionError = "returnDescriptionError";
  static const String returnSubmitFailed = "returnSubmitFailed";
  static const String returnCancelFailed = "returnCancelFailed";
  static const String returnLoadFailed = "returnLoadFailed";
  static const String returnNotSupported = "returnNotSupported";
  static const String startReturnTitle = "startReturnTitle";
  static const String startReturnText = "startReturnText";
  static const String selectOrderFromHistory = "selectOrderFromHistory";


  // ==========================================================================
  // FAZ 09 — hesap, adres defteri, ayarlar, dil, bildirimler
  // 🔴 FAZ 11 bu anahtarların hepsini ON sözlüğe de eklemek zorunda; yoksa o
  // dilde ekranda ham anahtar görünür (bkz. DURUM.md FAZ 11 notu).
  // ==========================================================================

  /// Hesap kimliği
  static const String accountType = "accountType";
  static const String accountTypeRetail = "accountTypeRetail";
  static const String accountTypeCompany = "accountTypeCompany";
  static const String companyName = "companyName";
  static const String director = "director";
  static const String iinBin = "iinBin";
  static const String companyDataFrom1C = "companyDataFrom1C";
  static const String priceCategory = "priceCategory";

  /// Güvenlik ve şifre
  static const String security = "security";
  static const String changePassword = "changePassword";
  static const String changePasswordHint = "changePasswordHint";
  static const String currentPassword = "currentPassword";
  static const String confirmNewPassword = "confirmNewPassword";
  static const String passwordsDoNotMatch = "passwordsDoNotMatch";
  static const String passwordChanged = "passwordChanged";
  static const String changeName = "changeName";
  static const String changeNameHint = "changeNameHint";
  static const String reAuthenticateUser = "reAuthenticateUser";
  static const String verify = "verify";

  /// Kredi limiti
  static const String creditTotal = "creditTotal";
  static const String creditAvailableShare = "creditAvailableShare";

  /// Adres defteri
  static const String addresses = "addresses";
  static const String addressBookHint = "addressBookHint";
  static const String savedAddresses = "savedAddresses";
  static const String noSavedAddresses = "noSavedAddresses";
  static const String editAddress = "editAddress";
  static const String setAsDefault = "setAsDefault";
  static const String defaultAddress = "defaultAddress";
  static const String companyBillingLocked = "companyBillingLocked";
  static const String addressLabelName = "addressLabelName";
  static const String addressLabelCompany = "addressLabelCompany";
  static const String addressLabelDirector = "addressLabelDirector";
  static const String addressLabelCity = "addressLabelCity";
  static const String addressLabelCountry = "addressLabelCountry";
  static const String addressLabelPostcode = "addressLabelPostcode";
  static const String addressLabelPhone = "addressLabelPhone";
  static const String addressLabelAddress = "addressLabelAddress";
  static const String addressLabelAddress2 = "addressLabelAddress2";

  /// Ayarlar
  static const String comingSoon = "comingSoon";
  static const String guestUser = "guestUser";
  static const String guestSignInPrompt = "guestSignInPrompt";

  /// Bildirimler
  static const String notification = "notification";
  static const String noNotifications = "noNotifications";
  static const String noNotificationsHint = "noNotificationsHint";
  static const String notificationRedirect = "notificationRedirect";
  static const String notificationTitleLabel = "notificationTitleLabel";
  static const String notificationMessageLabel = "notificationMessageLabel";

  /// Dil
  static const String selectLanguage = "selectLanguage";
  static const String chooseYourLanguage = "chooseYourLanguage";
  static const String allLanguages = "allLanguages";
  static const String defaultLabel = "defaultLabel";

  //Format Exception

  static const formatInvalidEmail = 'formatInvalidEmail';
  static const formatInvalidPhoneNumber = 'formatInvalidPhoneNumber';
  static const formatInvalidDate = 'formatInvalidDate';
  static const formatInvalidUrl = 'formatInvalidUrl';
  static const formatInvalidCreditCard = 'formatInvalidCreditCard';
  static const formatInvalidNumeric = 'formatInvalidNumeric';




//




  // ---- FAZ 10 — Destek sohbeti ----
  // Bu blok FAZ 11'de 10 dilin sözlüğüne de eklenmelidir; eklenmezse ekranda
  // çeviri yerine anahtarın kendisi ("supportChat") görünür.
  static const String supportChat = "supportChat";
  static const String supportTeam = "supportTeam";
  static const String supportOnline = "supportOnline";
  static const String liveSupport = "liveSupport";
  static const String chats = "chats";
  static const String chatSignInPrompt = "chatSignInPrompt";
  static const String chatWelcomeMessage = "chatWelcomeMessage";
  static const String chatInputHint = "chatInputHint";
  static const String noChatsYet = "noChatsYet";
  static const String noRecentMessage = "noRecentMessage";
  static const String imageMessage = "imageMessage";
  static const String audioMessage = "audioMessage";
  static const String chatLoadFailed = "chatLoadFailed";
  static const String send = "send";

  // ---- FAZ 11 — Yerelleştirme sırasında anahtarlanan gömülü metinler ----
  // Bu sabitler referansta YOK; ekranda düz İngilizce yazan yerler için
  // açıldı (fazın "hard-coded metin bırakma" kabul kriteri). Hepsi on dilin
  // sözlüğünde de var.
  static const String warning = "warning";
  static const String userFetchFailed = "userFetchFailed";
  static const String dataNotSaved = "dataNotSaved";
  static const String dataNotSavedMessage = "dataNotSavedMessage";
  static const String passwordResetDone = "passwordResetDone";

  // Dil adları: referans sekiz dili sayıyordu, Kazakça ile Türkçe eklendi
  // (`localization_helper.dart` bu iki dalı da tanıyor).
  static const String turkish = "turkish";
  static const String kazakh = "kazakh";

  // Form doğrulayıcıları (`utils/validators/validation.dart`). Referansta düz
  // İngilizce metin döndürüyorlardı; hata balonu kullanıcıya görünen metin
  // olduğu için anahtarlandı.
  static const String isRequired = "isRequired";
  static const String usernameRequired = "usernameRequired";
  static const String usernameInvalid = "usernameInvalid";
  static const String emailRequired = "emailRequired";
  static const String emailInvalid = "emailInvalid";
  static const String passwordRequired = "passwordRequired";
  static const String passwordMinLength = "passwordMinLength";
  static const String passwordUppercase = "passwordUppercase";
  static const String passwordNumber = "passwordNumber";
  static const String passwordSpecialChar = "passwordSpecialChar";
  static const String phoneRequired = "phoneRequired";

}
