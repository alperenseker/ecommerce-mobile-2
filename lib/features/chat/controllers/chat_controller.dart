/// Destek sohbetinin durumu: sohbeti bul-ya-da-aç, mesajları yükle, gönder,
/// okundu bilgisini yaz ve panel açıkken **yoklama** ile yenile.
///
/// 🔴 **SOHBET KULLANICI BAŞINA TEKTİR.** Ekran her açıldığında önce var olan
/// `support` sohbeti aranır (`chat/user/{userId}/type/support`); yalnız hiç
/// yoksa yeni sohbet açılır. Her açılışta yeni sohbet yaratmak destek
/// ekibinde aynı kişiyi 20 ayrı konu hâline getiriyordu (web'de de aynı kural:
/// `services/chat.service.js` → `Chat.ensure`).
///
/// 🔴 **Yeni mesajlar YOKLAMA ile alınır, SignalR ile değil.** Yoklama YALNIZ
/// sohbet ekranı açıkken çalışır; ekran kapanınca ya da uygulama arka plana
/// düşünce durur — kapalı panelde 8 saniyede bir istek atmak sunucuyu boşuna
/// yorar ve pil yakar. Referanstaki SignalR yardımcıları (`notifyTyping`,
/// `onUserTyping`, `stopTyping`) silinmedi; hub bağlı değilken sessizce boşa
/// düşerler.
library;

import 'dart:async';
import 'dart:typed_data';

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

  /// Yoklama aralığı. Web'deki `App.config.CHAT_POLL` ile aynı (8 sn):
  /// destek sohbetinde birkaç saniye gecikme sorun değil, daha sıkı yoklama
  /// yalnız sunucuyu yorar.
  static const Duration pollInterval = Duration(seconds: 8);

  /// Sunucudaki kimliği henüz bilinmeyen, yerel olarak çizilmiş mesajların
  /// kimlik öneki. Gerçek mesaj gelince bunlar kopya bırakmadan eşleştirilir.
  static const String tempIdPrefix = 'temp_';

  // -- Gözlemlenebilir durum
  final chats = <ChatModel>[].obs;

  /// Mesajlar **yeniden eskiye** dizilidir (index 0 = en yeni) — `flutter_chat_ui`
  /// listeyi bu sırayla bekliyor.
  final messages = <MessageModel>[].obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final isSending = false.obs;
  final isUploading = false.obs;
  final currentChatId = ''.obs;
  final currentChat = ChatModel.empty().obs;
  final admin = UserModel.empty().obs;
  final isOtherTyping = false.obs;

  /// Sohbet hiç açılamadıysa (uç 401/500) ekran boş balon yerine hata
  /// durumunu gösterir; kullanıcı yeniden deneyebilsin.
  final hasError = false.obs;

  Timer? _pollTimer;
  Timer? _typingDebounce;

  /// Panel (sohbet ekranı) açık mı — yoklamanın birinci koşulu.
  bool _panelOpen = false;

  /// Uygulama ön planda mı — yoklamanın ikinci koşulu.
  bool _appResumed = true;

  /// Aynı anda ikinci bir yoklama başlamasın (yavaş ağda istekler üst üste
  /// binip listeyi zıplatıyordu).
  bool _polling = false;

  /// Devam eden "sohbeti bul-ya-da-aç" işi. İki çağrı üst üste gelirse
  /// (ekran açılışı + ilk mesaj) İKİSİ DE sohbet açmasın diye paylaşılır.
  Future<ChatModel>? _ensureFuture;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    super.onClose();
  }

  // ─── Yoklama ──────────────────────────────────────────────────────────────

  /// Yoklamanın çalışması gereken durum. **Saf fonksiyon** (test edilebilir):
  /// panel kapalıysa, uygulama arka plandaysa ya da kullanıcı misafirse
  /// sayaç boşa dönmemeli.
  static bool shouldPoll({
    required bool panelOpen,
    required bool appResumed,
    required bool isGuest,
    required bool hasChat,
  }) =>
      panelOpen && appResumed && !isGuest && hasChat;

  bool get _shouldPoll => shouldPoll(
        panelOpen: _panelOpen,
        appResumed: _appResumed,
        isGuest: AuthenticationRepository.instance.isGuestUser,
        hasChat: currentChatId.value.isNotEmpty,
      );

  /// Yoklama sayacı ayakta mı (test ve ekran için).
  bool get isPolling => _pollTimer?.isActive ?? false;

  void startPolling() {
    stopPolling();
    if (!_shouldPoll) return;
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appResumed = state == AppLifecycleState.resumed;

    if (!_appResumed) {
      // Arka planda yoklama YOK — kabul kriteri: sayaç boşa dönmemeli.
      stopPolling();
      return;
    }

    if (_panelOpen) {
      // Öne dönerken beklemeden bir kez tazele; 8 sn'lik boşluk kullanıcıya
      // "mesaj gelmemiş" gibi görünüyordu.
      _poll();
      startPolling();
    }
  }

  /// Tek yoklama turu: mesajları çeker, yerel iyimser mesajlarla birleştirir
  /// ve yeni gelen varsa okundu bilgisini yazar.
  Future<void> _poll() async {
    if (_polling || !_shouldPoll) return;
    _polling = true;
    try {
      final fresh = await _chatRepository.fetchMessages(currentChatId.value);
      final beforeIds = messages.map((m) => m.id).toSet();
      messages.value = mergeMessages(fresh, messages);
      final gotNew = messages.any((m) => !beforeIds.contains(m.id));
      if (gotNew) markMessagesAsSeen();
    } catch (e) {
      // Yoklama hatası sessizdir: ağ bir tur düşerse kullanıcıya balon
      // göstermenin anlamı yok, bir sonraki tur zaten deneyecek.
      TLoggerHelper.warning('Sohbet yoklaması başarısız: $e');
    } finally {
      _polling = false;
    }
  }

  // ─── Mesaj birleştirme ────────────────────────────────────────────────────

  /// Sunucu listesiyle yerel iyimser mesajları birleştirir. **Saf fonksiyon.**
  ///
  /// Sunucu her yoklamada TÜM geçmişi döndürüyor; onu doğrudan yazmak, henüz
  /// sunucuya ulaşmamış (ya da gönderilemeyip `failed` kalmış) yerel mesajları
  /// ekrandan siliyordu. Bu yüzden geçici kimlikli mesajlar, sunucuda karşılığı
  /// **bulunamayanlar** kadar korunur; karşılığı bulunan her biri tek bir
  /// sunucu mesajını "sahiplenir" (aynı metni iki kez yazan kullanıcıda ikinci
  /// mesaj kaybolmasın).
  static List<MessageModel> mergeMessages(
    List<MessageModel> serverMessages,
    List<MessageModel> localMessages,
  ) {
    final server = [...serverMessages]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final claimed = <int>{};
    final pending = <MessageModel>[];

    for (final local in localMessages) {
      if (!local.id.startsWith(tempIdPrefix)) continue;

      var matched = false;
      for (var i = 0; i < server.length; i++) {
        if (claimed.contains(i)) continue;
        final candidate = server[i];
        if (candidate.senderId == local.senderId &&
            candidate.content == local.content &&
            candidate.type == local.type) {
          claimed.add(i);
          matched = true;
          break;
        }
      }
      if (!matched) pending.add(local);
    }

    pending.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return [...pending, ...server];
  }

  // ─── Sohbeti aç ───────────────────────────────────────────────────────────

  /// Sohbet ekranının giriş noktası: hangi sohbetin gösterileceğini çözer
  /// (ilk kullanımda destek sohbetini açar) ve mesajlarını yükler.
  ///
  /// Ekranın kendi (kapatılabilir) yükleme durumunun arkasında çalışır; yavaş
  /// ya da başarısız bir çağrı kullanıcıyı engelleyici bir diyalogda hapsetmez.
  Future<void> openSupportChat() async {
    _panelOpen = true;
    hasError.value = false;

    // Misafir kullanıcı hiçbir uca gitmez: mesaj sunucuda kullanıcıya
    // bağlanıyor. Ekran giriş bağlantısını gösterir (duvara çarptırma yok).
    if (AuthenticationRepository.instance.isGuestUser) {
      isLoading.value = false;
      return;
    }

    try {
      if (currentChatId.value.isEmpty) {
        final chat = await ensureSupportChat();
        currentChat.value = chat;
        currentChatId.value = chat.id;
      }

      await fetchMessages();
      markMessagesAsSeen();
      startPolling();
    } catch (e) {
      TLoggerHelper.error('Destek sohbeti açılamadı', e);
      isLoading.value = false;
      hasError.value = true;
      TLoaders.errorSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableFetchMessage.tr,
      );
    }
  }

  /// Sohbet ekranı kapanırken çağrılır: yoklama durur.
  void closeSupportChat() {
    _panelOpen = false;
    stopPolling();
  }

  /// Var olan destek sohbetini döndürür, yoksa **bir kez** açar.
  ///
  /// 🔴 Yeni sohbet açmadan önce DAİMA arama yapılır. Arama ucu hata verirse
  /// (uç yok / geçici sorun) web'deki gibi açmaya geçilir; ama iki eşzamanlı
  /// çağrı aynı işi paylaşır, ikinci bir sohbet yaratılmaz.
  Future<ChatModel> ensureSupportChat() {
    return _ensureFuture ??= _ensureSupportChat().whenComplete(() {
      _ensureFuture = null;
    });
  }

  Future<ChatModel> _ensureSupportChat() async {
    try {
      isLoading.value = true;
      final userId = AuthenticationRepository.instance.getUserID;

      // Admin bilgisi yalnız başlıkta/ listede isim göstermek için; bulunamazsa
      // sohbet yine de açılmalı — referansta bu çağrı zincirin başındaydı ve
      // 401 alınca sohbet hiç açılmıyordu.
      await fetchAdmin();

      try {
        final existing = await _chatRepository.getChatsByType(
          userId,
          ChatType.support,
        );
        if (existing.isNotEmpty) {
          chats.assignAll(existing);
          currentChat.value = existing.first;
          currentChatId.value = existing.first.id;
          return existing.first;
        }
      } catch (e) {
        // Arama başarısızsa aşağıda açmayı deneriz (web ile aynı davranış).
        TLoggerHelper.warning('Var olan destek sohbeti aranamadı: $e');
      }

      final created = await _chatRepository.createSupportChat(userId);
      if (created == null || created.id.isEmpty) {
        throw TTexts.unableFindChat.tr;
      }

      currentChat.value = created;
      currentChatId.value = created.id;
      if (!chats.any((c) => c.id == created.id)) chats.add(created);
      return created;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSupportChat() async {
    try {
      isLoading.value = true;
      chats.clear();
      final userId = AuthenticationRepository.instance.getUserID;
      await fetchChatsByType(userId, ChatType.support);
      await fetchAdmin();
    } catch (e) {
      TLoggerHelper.warning('Sohbet listesi alınamadı: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserChats() async {
    final userId = AuthenticationRepository.instance.getUserID;
    await fetchChatsByType(userId, ChatType.support);
  }

  /// Referanstan taşındı: belirli bir "referans kimliği" (eski sürümde yolculuk)
  /// için açılmış sohbeti bulur. Bu uygulamada `referenceId` boş geliyor ama
  /// işlev eksiltilmedi.
  Future<ChatModel> getChatsForSpecificRide(
    String rideId,
    String driverId,
  ) async {
    await fetchUserChats();

    final chat = chats.firstWhereOrNull(
      (chat) =>
          chat.referenceId == rideId &&
          chat.participants.any(
            (part) => part.userId == AuthenticationRepository.instance.getUserID,
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

  // ─── Mesajlar ─────────────────────────────────────────────────────────────

  /// Geçerli sohbetin mesajlarını sunucudan yükler (tek seferlik; sürekli
  /// yenileme yoklamayla).
  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;

      if (currentChat.value.id.isEmpty && currentChatId.value.isNotEmpty) {
        currentChat.value = await _chatRepository.getChatById(
          currentChatId.value,
        );
      }

      if (currentChatId.value.isEmpty) {
        messages.clear();
        return;
      }

      final fresh = await _chatRepository.fetchMessages(currentChatId.value);
      messages.value = mergeMessages(fresh, messages);
      hasError.value = false;
    } catch (e) {
      TLoggerHelper.error('Mesajlar yüklenemedi', e);
      hasError.value = true;
      TLoaders.errorSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableFetchMessage.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Okundu bilgisi (`chat/{chatId}/seen`).
  ///
  /// Sessizdir: okundu yazılamadı diye mesajlaşma durmamalı (web de
  /// `.catch(function () {})` ile yutuyor).
  Future<void> markMessagesAsSeen() async {
    if (currentChatId.value.isEmpty) return;
    final currentUserId = UserController.instance.user.value.id;
    try {
      await _chatRepository.markMessagesAsSeen(
        currentChatId.value,
        currentUserId,
      );
    } catch (e) {
      TLoggerHelper.warning('Okundu bilgisi yazılamadı: $e');
    }
  }

  /// Referanstaki genel sohbet açma yolu (katılımcı listesiyle). Destek
  /// sohbeti için [createSupportChat] kullanılır; bu işlev eksiltilmedi.
  Future<void> createChat({
    required ParticipantModel receiver,
    required ChatType chatType,
    String? referenceId,
  }) async {
    try {
      isLoading.value = true;
      final participants = <ParticipantModel>[
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

  Future<void> markChatAsRead(String chatId) async {
    try {
      await _chatRepository.markChatAsRead(chatId);
    } catch (e) {
      TLoggerHelper.warning('Sohbet okundu işaretlenemedi: $e');
    }
  }

  // ─── Gönderme ─────────────────────────────────────────────────────────────

  Future<void> sendTextMessage(String content) =>
      _sendMessage(content.trim(), MessageType.text);

  /// Ek gönderir: önce `chat/{chatId}/upload`, sonra `mediaUrl`li bir görsel
  /// mesajı. Yükleme desteklenmiyorsa **uygulama kırılmaz**, yalnız uyarı
  /// balonu çıkar (web `Chat.upload` ile aynı).
  Future<bool> sendAttachment({
    required Uint8List fileData,
    required String filename,
    required String mimeType,
  }) async {
    final chatId = await _resolveChatId();
    if (chatId.isEmpty) return false;

    try {
      isUploading.value = true;
      final url = await _chatRepository.uploadAttachment(
        chatId: chatId,
        fileData: fileData,
        filename: filename,
        mimeType: mimeType,
      );
      if (url == null) {
        TLoaders.warningSnackBar(
          title: TTexts.ohSnap.tr,
          message: TTexts.attachmentFailed.tr,
        );
        return false;
      }
      await sendImageMessage(url: url, name: filename);
      return true;
    } finally {
      isUploading.value = false;
    }
  }

  /// Hazır bir adresle görsel mesajı gönderir (yükleme ucu kullanılmadan).
  ///
  /// İçerik alanına dosya adı yazılır (web `Chat.upload` ile aynı), adres
  /// `mediaUrl`'e gider; adı bilinmiyorsa adresin kendisi içerik olur.
  Future<void> sendImageMessage({required String url, String? name}) {
    final address = url.trim();
    final label = (name ?? '').trim();
    return _sendMessage(
      label.isEmpty ? address : label,
      MessageType.image,
      mediaUrl: address,
    );
  }

  Future<void> _sendMessage(
    String content,
    MessageType messageType, {
    String? mediaUrl,
  }) async {
    if (content.isEmpty) return;

    final chatId = await _resolveChatId();
    if (chatId.isEmpty) return;

    // Geçici kimlik: gerçek kimlik gelene kadar mesajı listede tekil tutar
    // (boş kimlik diğer mesajlarla çakışıp listeyi düşürüyordu).
    final tempId = '$tempIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: tempId,
      senderId: AuthenticationRepository.instance.getUserID,
      content: content,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sending,
      type: messageType,
      mediaUrl: mediaUrl,
    );

    // İyimser çizim: mesaj hemen görünsün, sunucu sonra onaylasın.
    messages.insert(0, newMessage);
    updateChatLastMessage(newMessage);
    isEditing.value = false;

    try {
      isSending.value = true;
      final messageId = await _chatRepository.sendMessage(chatId, newMessage);

      final tempIndex = messages.indexWhere((msg) => msg.id == tempId);
      if (tempIndex != -1) {
        if (messageId.isNotEmpty) newMessage.id = messageId;
        newMessage.status = ChatMessageStatus.sent;
        messages[tempIndex] = newMessage;
      }

      _touchChatListEntry(newMessage);

      // Gönderdikten sonra sunucudan tazele: karşı taraf bu arada yazmışsa
      // yoklamanın turunu beklemeden görünsün.
      await refreshMessages();
      markMessagesAsSeen();
    } catch (e) {
      TLoggerHelper.error('Mesaj gönderilemedi', e);
      final failedIndex = messages.indexWhere((msg) => msg.id == tempId);
      if (failedIndex != -1) {
        messages[failedIndex].status = ChatMessageStatus.failed;
        messages.refresh();
      }
      TLoaders.warningSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableSendMessage.tr,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Mesajları sessizce tazeler (gönderme sonrası / elle yenileme).
  Future<void> refreshMessages() async {
    if (currentChatId.value.isEmpty) return;
    try {
      final fresh = await _chatRepository.fetchMessages(currentChatId.value);
      messages.value = mergeMessages(fresh, messages);
    } catch (e) {
      TLoggerHelper.warning('Mesajlar tazelenemedi: $e');
    }
  }

  /// Gönderim anında sohbet henüz açılmamış olabilir (ekran yüklenirken
  /// kullanıcı hızlı yazdıysa); tek sohbet kuralını bozmadan çözer.
  Future<String> _resolveChatId() async {
    if (currentChatId.value.isNotEmpty) return currentChatId.value;
    try {
      final chat = await ensureSupportChat();
      return chat.id;
    } catch (e) {
      TLoggerHelper.error('Sohbet çözümlenemedi', e);
      TLoaders.warningSnackBar(
        title: TTexts.ohSnap.tr,
        message: TTexts.unableSendMessage.tr,
      );
      return '';
    }
  }

  void updateChatLastMessage(MessageModel message) {
    currentChat.value.lastMessage = message.content;
    currentChat.value.lastMessageType = message.type;
    currentChat.value.lastMessageStatus = message.status;
    currentChat.value.lastMessageTime = message.timestamp;
    currentChat.value.lastMessageSenderId = message.senderId;
  }

  /// Sohbet listesindeki satırın son mesaj özetini günceller (liste ekranı
  /// açıldığında eski özeti göstermesin).
  void _touchChatListEntry(MessageModel message) {
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

  // ─── Yazıyor bilgisi (SignalR yokken sessizce boşa düşer) ─────────────────

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

  // ─── Destek kullanıcısı ───────────────────────────────────────────────────

  /// Destek (admin) kullanıcısını bulur; yalnız başlıkta/listede isim ve
  /// avatar göstermek için. Bulunamazsa boş kalır ve ekran "Destek" yazar —
  /// bu çağrı sohbeti açmanın ön koşulu DEĞİLDİR.
  Future<void> fetchAdmin() async {
    try {
      final admins = await ApiUserRepository.instance
          .fetchFilteredPaginatedItems(limit: 1, isEqualTo: {'role': 'admin'});
      admin.value = admins.isNotEmpty ? admins.first : UserModel.empty();
    } catch (e) {
      TLoggerHelper.warning('Destek kullanıcısı bulunamadı: $e');
      admin.value = UserModel.empty();
    }
  }
}
