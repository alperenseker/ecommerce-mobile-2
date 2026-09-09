/// Destek sohbetinin tüm iş kuralları: sohbeti bul-ya-da-aç, mesajları çek,
/// gönder, okundu işaretle ve **yoklama** ile tazele.
///
/// Referans mobil uygulama mesajları SignalR (`chathub`) üzerinden canlı
/// alıyordu; bu sunucuda hub açık değil. Web projesi (`chat.service.js`) aynı
/// işi 8 saniyelik yoklamayla yapıyor — destek sohbetinde birkaç saniye
/// gecikme sorun değil, buna karşılık her sunucuda kurulumsuz çalışıyor.
/// Repository'deki hub kodu **silinmedi**; sunucuda `chathub` açılırsa
/// burada yalnız bağlanma çağrısı geri açılır.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/chat/api_chat_repository.dart';
import '../../../data/repositories/user/api_user_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/logging/logger.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../personalization/models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/participant_model.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  static ChatController get instance => Get.find();
  final _chatRepository = ApiChatRepository.instance;

  /// Yoklama aralığı. Web'deki `App.config.CHAT_POLL` ile **aynı** olmalı;
  /// iki istemcinin destek ekibine farklı hızda görünmesi kafa karıştırıyor.
  static const Duration pollInterval = Duration(seconds: 8);

  /// Sunucuya henüz gitmemiş (iyimser) mesajların kimlik ön eki. Boş kimlik
  /// listede çakışıp çizimi düşürdüğü için geçici kimlik veriliyor.
  static const String tempIdPrefix = 'temp_';

  // ─── Gözlenenler ──────────────────────────────────────────────────────────
  var chats = <ChatModel>[].obs;
  var messages = <MessageModel>[].obs;
  var isLoading = true.obs;
  var isEditing = false.obs;
  var isSending = false.obs;
  var hasError = false.obs;
  var currentChatId = ''.obs;
  var currentChat = ChatModel.empty().obs;
  var admin = UserModel.empty().obs;
  var isOtherTyping = false.obs;

  StreamSubscription<bool>? _typingSubscription;
  StreamSubscription<String>? _seenSubscription;
  Timer? _typingDebounce;

  Timer? _pollTimer;

  /// Panel (sohbet ekranı) açık mı. Yoklama yalnız açıkken döner; kapalı
  /// panelde 8 saniyede bir istek atmak sunucuyu boşuna yoruyor.
  bool _panelOpen = false;

  /// Uygulama önde mi. Arka plandayken sayaç boşa dönmesin.
  bool _appResumed = true;

  /// Aynı anda iki yerden gelen "sohbeti hazırla" çağrısı (ekran açılışı ve
  /// hızla yazılan ilk mesaj) tek `Future`'ı paylaşsın; yoksa ikisi de "sohbet
  /// yok" görüp **iki ayrı sohbet** açıyor.
  Future<ChatModel>? _ensureFuture;

  bool get isPolling => _pollTimer?.isActive ?? false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingSubscription?.cancel();
    _seenSubscription?.cancel();
    _typingDebounce?.cancel();
    stopPolling();
    super.onClose();
  }

  // ─── Yaşam döngüsü ────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appResumed = state == AppLifecycleState.resumed;

    if (_appResumed) {
      // Öne dönüşte bir kez hemen tazele; kullanıcı 8 saniye boş ekrana
      // bakmasın.
      if (_panelOpen) {
        refreshMessages();
        startPolling();
      }
    } else {
      stopPolling();
    }
  }

  // ─── Yoklama ──────────────────────────────────────────────────────────────

  /// Yoklamanın dönmesi gereken durum. **Saf** tutuldu ki testte donanım
  /// olmadan sabitlenebilsin: sayacın "boşa dönmesi" en kolay gözden kaçan
  /// pil/veri kaybı.
  static bool shouldPoll({
    required bool panelOpen,
    required bool appResumed,
    required bool isGuest,
    required bool hasChat,
  }) =>
      panelOpen && appResumed && !isGuest && hasChat;

  void startPolling() {
    stopPolling();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      if (!shouldPoll(
        panelOpen: _panelOpen,
        appResumed: _appResumed,
        isGuest: AuthenticationRepository.instance.isGuestUser,
        hasChat: currentChat.value.id.isNotEmpty,
      )) {
        stopPolling();
        return;
      }
      refreshMessages();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Ekran kapanırken çağrılır: sayaç durur, panel kapalı işaretlenir.
  void closeSupportChat() {
    _panelOpen = false;
    stopPolling();
  }

  // ─── Sohbeti bul ya da aç ─────────────────────────────────────────────────

  /// 🔴 **Destek sohbeti kullanıcı başına TEKTİR.** Önce var olan `support`
  /// sohbeti aranır; **yalnız hiç sonuç yoksa** yenisi açılır. Her açılışta
  /// yeni sohbet yaratmak destek ekibinde aynı kişiyi ayrı ayrı konu hâline
  /// getiriyordu. Sohbet açan başka bir yer yazma — bu kapıyı çağır.
  Future<ChatModel> ensureSupportChat() {
    if (currentChat.value.id.isNotEmpty) {
      return Future.value(currentChat.value);
    }
    return _ensureFuture ??= _ensureSupportChat().whenComplete(() {
      _ensureFuture = null;
    });
  }

  Future<ChatModel> _ensureSupportChat() async {
    try {
      isLoading.value = true;
      final userId = AuthenticationRepository.instance.getUserID;

      // Başlıkta isim/avatar göstermek için; sorgu 401 verirse sohbet yine de
      // açılmalı, bu yüzden hata yutuluyor.
      await fetchAdmin();

      final existingChats = await _chatRepository.getChatsByType(
        userId,
        ChatType.support,
      );
      if (existingChats.isNotEmpty) {
        currentChat.value = existingChats.first;
        currentChatId.value = existingChats.first.id;
        return existingChats.first;
      }

      final created = await _chatRepository.createSupportChat(userId);
      if (created != null && created.id.isNotEmpty) {
        currentChat.value = created;
        currentChatId.value = created.id;
        chats.add(created);
        return created;
      }
      return ChatModel.empty();
    } finally {
      isLoading.value = false;
    }
  }

  /// Sohbet ekranının giriş noktası: sohbeti çözer, mesajları yükler ve
  /// yoklamayı başlatır.
  ///
  /// Girişsiz kullanıcı hiçbir sohbet ucuna gitmez ve yoklama başlamaz;
  /// ekranda giriş bağlantısı gösterilir (web `support-widget.js` ile aynı).
  Future<void> openSupportChat() async {
    _panelOpen = true;

    if (AuthenticationRepository.instance.isGuestUser ||
        AuthenticationRepository.instance.getUserID.isEmpty) {
      isLoading.value = false;
      return;
    }

    try {
      hasError.value = false;

      if (currentChat.value.id.isEmpty) {
        // Liste ekranından kimlikle gelindiyse doğrudan o sohbet açılır.
        if (currentChatId.value.isNotEmpty) {
          currentChat.value = await _chatRepository.getChatById(
            currentChatId.value,
          );
        } else {
          await ensureSupportChat();
        }
      }

      await fetchMessages();
      startPolling();
    } catch (e) {
      hasError.value = true;
      isLoading.value = false;
      TLoggerHelper.error('Destek sohbeti açılamadı', e);
      TLoaders.errorSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableFetchMessage.tr,
      );
    }
  }

  // ─── Mesajlar ─────────────────────────────────────────────────────────────

  /// 🔴 Sunucu her çağrıda **tüm geçmişi** ve **eskiden yeniye** döndürüyor
  /// (2026-09-09'da canlı doğrulandı). `flutter_chat_ui` ise listeyi
  /// **yeniden eskiye** bekliyor (index 0 = en yeni), bu yüzden ters çevrilir.
  List<MessageModel> _normalize(List<MessageModel> serverMessages) {
    final sorted = List<MessageModel>.from(serverMessages)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// Sunucu geçmişini yerel listeyle birleştirir. **Saf** fonksiyon.
  ///
  /// Sunucu her yoklamada tüm geçmişi döndürdüğü için listeyi doğrudan
  /// üzerine yazmak, henüz gitmemiş ya da `failed` kalmış yerel mesajları
  /// ekrandan **siliyordu**. Kural: geçici kimlikli mesaj, sunucuda karşılığı
  /// bulunana kadar korunur; karşılığı bulunan her biri **tek** bir sunucu
  /// mesajını sahiplenir — aynı metni iki kez yazan kullanıcıda ikinci mesaj
  /// kaybolmasın.
  ///
  /// Her iki liste de **yeniden eskiye** dizilidir.
  static List<MessageModel> mergeMessages(
    List<MessageModel> local,
    List<MessageModel> server,
  ) {
    final claimed = <int>{};
    final pending = <MessageModel>[];

    for (final message in local) {
      if (!message.id.startsWith(tempIdPrefix)) continue;

      var matched = false;
      for (var i = 0; i < server.length; i++) {
        if (claimed.contains(i)) continue;
        final candidate = server[i];
        if (candidate.senderId == message.senderId &&
            candidate.content == message.content &&
            candidate.type == message.type) {
          claimed.add(i);
          matched = true;
          break;
        }
      }
      if (!matched) pending.add(message);
    }

    return [...pending, ...server];
  }

  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;

      if (currentChat.value.id.isEmpty && currentChatId.value.isNotEmpty) {
        currentChat.value = await _chatRepository.getChatById(
          currentChatId.value,
        );
      }

      if (currentChat.value.id.isEmpty) {
        messages.value = [];
        return;
      }

      currentChatId.value = currentChat.value.id;
      final fetched = await _chatRepository.fetchMessages(
        currentChat.value.id,
      );
      messages.value = mergeMessages(messages, _normalize(fetched));
      hasError.value = false;

      markMessagesAsSeen();
    } catch (e) {
      hasError.value = true;
      TLoggerHelper.error('Sohbet mesajları alınamadı', e);
      TLoaders.errorSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableFetchMessage.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Yoklamanın çağırdığı sessiz tazeleme: yükleniyor göstergesi çizilmez ve
  /// hata balonu atılmaz — 8 saniyede bir "bağlantı yok" balonu çıkarmak
  /// yazışmayı okunmaz hâle getiriyor.
  Future<void> refreshMessages() async {
    if (currentChat.value.id.isEmpty) return;
    try {
      final fetched = await _chatRepository.fetchMessages(
        currentChat.value.id,
      );
      messages.value = mergeMessages(messages, _normalize(fetched));
      hasError.value = false;
      markMessagesAsSeen();
    } catch (e) {
      TLoggerHelper.warning('Yoklama başarısız: $e');
    }
  }

  /// Okundu bilgisi. Başarısızlığı kullanıcıya yansıtılmaz: mesaj gitti
  /// sayılır (web `chat.service.js` de bu çağrının hatasını yutuyor).
  void markMessagesAsSeen() async {
    if (currentChatId.value.isEmpty) return;
    final currentUserId = AuthenticationRepository.instance.getUserID;
    try {
      await _chatRepository.markMessagesAsSeen(
        currentChatId.value,
        currentUserId,
      );
    } catch (e) {
      TLoggerHelper.warning('Okundu bilgisi gönderilemedi: $e');
    }
  }

  // ─── Gönderme ─────────────────────────────────────────────────────────────

  Future<void> sendTextMessage(String content) async {
    final body = content.trim();
    if (body.isEmpty) return;
    await _sendMessage(body, MessageType.text);
  }

  Future<void> _sendMessage(String content, MessageType messageType) async {
    final chat = await ensureSupportChat();
    if (chat.id.isEmpty) {
      TLoaders.warningSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableSendMessage.tr,
      );
      return;
    }

    // Geçici kimlik: sunucu kimliği gelene kadar mesajı listede benzersiz
    // tutar (boş kimlik diğerleriyle çakışıp çizimi düşürüyordu).
    final tempId = '$tempIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: tempId,
      senderId: AuthenticationRepository.instance.getUserID,
      content: content,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sending,
      type: messageType,
    );

    // Anında görünsün (iyimser ekleme); liste yeniden eskiye dizili.
    messages.insert(0, newMessage);
    updateChatLastMessage(newMessage);
    isEditing.value = false;

    try {
      isSending.value = true;
      final messageId = await _chatRepository.sendMessage(chat.id, newMessage);

      final tempIndex = messages.indexWhere((msg) => msg.id == tempId);
      if (messageId.isNotEmpty && tempIndex != -1) {
        final alreadyThere = messages.indexWhere((msg) => msg.id == messageId);
        if (alreadyThere != -1 && alreadyThere != tempIndex) {
          // Yoklama sunucu sürümünü çoktan getirmiş — geçici olanı düşür.
          messages.removeAt(tempIndex);
        } else {
          newMessage.id = messageId;
          newMessage.status = ChatMessageStatus.sent;
          messages[tempIndex] = newMessage;
        }
      }

      _syncChatListEntry(newMessage);
      messages.refresh();
    } catch (e) {
      final failedIndex = messages.indexWhere((msg) => msg.id == tempId);
      if (failedIndex != -1) {
        messages[failedIndex].status = ChatMessageStatus.failed;
        messages.refresh();
      }
      TLoggerHelper.error('Mesaj gönderilemedi', e);
      TLoaders.warningSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableSendMessage.tr,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Liste ekranındaki satırın son mesajını da güncel tutar.
  void _syncChatListEntry(MessageModel message) {
    final index = chats.indexWhere((chat) => chat.id == currentChat.value.id);
    if (index == -1) return;
    final entry = chats[index];
    entry.lastMessage = message.content;
    entry.lastMessageType = message.type;
    entry.lastMessageTime = message.timestamp;
    entry.lastMessageStatus = message.status;
    entry.lastMessageSenderId = message.senderId;
    chats[index] = entry;
  }

  void updateChatLastMessage(MessageModel message) {
    currentChat.value.lastMessage = message.content;
    currentChat.value.lastMessageType = message.type;
    currentChat.value.lastMessageStatus = message.status;
    currentChat.value.lastMessageTime = message.timestamp;
    currentChat.value.lastMessageSenderId = message.senderId;
  }

  // ─── Sohbet listesi ───────────────────────────────────────────────────────

  Future<void> fetchSupportChat() async {
    if (AuthenticationRepository.instance.isGuestUser) {
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      chats.clear();
      final userId = AuthenticationRepository.instance.getUserID;
      await fetchChatsByType(userId, ChatType.support);
      await fetchAdmin();
    } catch (e) {
      hasError.value = true;
      TLoggerHelper.error('Sohbet listesi alınamadı', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserChats() async {
    final userId = AuthenticationRepository.instance.getUserID;
    await fetchChatsByType(userId, ChatType.support);
  }

  Future<void> fetchChatsByType(String currentUserId, ChatType chatType) async {
    try {
      isLoading.value = true;
      final typedChats = await _chatRepository.getChatsByType(
        currentUserId,
        chatType,
      );
      chats.assignAll(typedChats);
    } finally {
      isLoading.value = false;
    }
  }

  /// Referanstaki sürücü/yolculuk sohbeti araması. Bu uygulamada yalnız
  /// `support` türü var; işlev **eksiltilmedi**, referansla aynı duruyor.
  Future<ChatModel> getChatsForSpecificRide(
    String rideId,
    String driverId,
  ) async {
    await fetchUserChats();

    final chat = chats.firstWhereOrNull(
      (chat) =>
          chat.referenceId == rideId &&
          chat.participants.any(
            (part) =>
                part.userId == AuthenticationRepository.instance.getUserID,
          ) &&
          chat.participants.any((part) => part.userId == driverId),
    );

    if (chat != null) return chat;

    TLoaders.errorSnackBar(
      title: TTexts.ohSnap.tr,
      message: TTexts.unableFindChat.tr,
    );
    return ChatModel.empty();
  }

  /// Referanstaki genel sohbet açma yolu (alıcıyı çağıran belirler).
  ///
  /// ⚠️ Destek sohbeti için bunu **çağırma** — [ensureSupportChat] kullan;
  /// bu yol var olanı aramadığı için ikinci bir sohbet açar.
  Future<void> createChat({
    required ParticipantModel receiver,
    required ChatType chatType,
    String? referenceId,
  }) async {
    try {
      isLoading.value = true;
      final participants = [
        ParticipantModel(
          userId: UserController.instance.user.value.id,
          name: UserController.instance.user.value.fullName,
          profileImageURL: UserController.instance.user.value.profilePicture,
        ),
        receiver,
      ];

      final chat = ChatModel(
        id: '',
        participants: participants,
        lastMessageTime: DateTime.now(),
        chatType: chatType,
        participantIds: participants.map((p) => p.userId).toList(),
        referenceId: referenceId ?? '',
      );

      final receivedChat = await _chatRepository.createChat(chat);
      if (receivedChat != null) {
        currentChat.value = receivedChat;
        currentChatId.value = receivedChat.id;
        chats.add(receivedChat);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    await _chatRepository.markChatAsRead(chatId);
  }

  // ─── Yazıyor bilgisi (hub'a bağlı) ────────────────────────────────────────

  /// Hub bağlı olmadığı için bu bildirimler sessizce boşa düşer ve
  /// [isOtherTyping] daima `false` kalır. İşlev referanstan **eksiltilmedi**:
  /// sunucuda `chathub` açılırsa çalışmaya başlar.
  void notifyTyping(bool isTyping) {
    if (currentChat.value.id.isEmpty) return;
    _chatRepository.sendTyping(
      currentChat.value.id,
      AuthenticationRepository.instance.getUserID,
      isTyping,
    );
  }

  void onUserTyping() {
    notifyTyping(true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(
      const Duration(milliseconds: 1500),
      () => notifyTyping(false),
    );
  }

  void stopTyping() {
    _typingDebounce?.cancel();
    notifyTyping(false);
  }

  // ─── Yönetici ─────────────────────────────────────────────────────────────

  /// Başlıkta destek tarafının adını/avatarını göstermek için. Normal
  /// kullanıcı jetonuyla `users?role=admin` 401 dönebiliyor; sohbetin açılması
  /// buna **bağlı olmamalı**, bu yüzden hata yutuluyor.
  Future<void> fetchAdmin() async {
    try {
      final admins = await ApiUserRepository.instance
          .fetchFilteredPaginatedItems(
            limit: 1,
            isEqualTo: {'role': 'admin'},
          );
      admin.value = admins.isNotEmpty ? admins.first : UserModel.empty();
    } catch (e) {
      TLoggerHelper.warning('Yönetici bilgisi alınamadı: $e');
      admin.value = UserModel.empty();
    }
  }
}
