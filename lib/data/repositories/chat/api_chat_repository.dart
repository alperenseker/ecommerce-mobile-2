/// Destek sohbeti uçları (`chat/...`).
///
/// 🔴 **Yeni mesajlar YOKLAMA ile alınır, SignalR ile değil.** Hub kodu
/// (bağlanma, `ReceiveMessage`, yazıyor/okundu olayları) referansla birebir
/// duruyor ve silinmedi; ama `ChatController` ona bağlanmıyor — web
/// (`services/chat.service.js`) da yoklama kullanıyor: her sunucuda çalışır,
/// kurulum istemez ve destek sohbetinde birkaç saniye gecikme sorun değil.
/// Hub adresi yanlış/kapalıysa uygulama sessizce yoklamaya devam eder.
///
/// Yanıt zarfı iki yazımla da gelebildiği için (`Success`/`success`) okuma
/// DAİMA temel sınıfın `isSuccess` / `dataOf` / `messageOf` yardımcılarından
/// geçer; bu dosya önceden yalnız küçük harfli yazımı kabul ediyordu ve
/// .NET'in varsayılan serileştirmesinde sohbet sessizce boş kalıyordu.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:signalr_netcore/signalr_client.dart';
import '../../../features/chat/models/chat_model.dart';
import '../../../features/chat/models/message_model.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/logging/logger.dart';
import 'chat_repository.dart';

class ApiChatRepository extends TApiRepositoryController<ChatModel>
    implements ChatRepository {
  static ApiChatRepository get instance => Get.isRegistered<ApiChatRepository>()
      ? Get.find<ApiChatRepository>()
      : Get.put(ApiChatRepository());

  HubConnection? _hubConnection;

  final Map<String, StreamController<List<MessageModel>>> _messageControllers =
      {};
  final Map<String, StreamController<List<ChatModel>>> _chatControllers = {};
  final Map<String, StreamController<bool>> _typingControllers = {};
  final Map<String, StreamController<String>> _seenControllers = {};

  String? _activeChatId;
  String? _lastSentMessageId;

  ApiChatRepository()
    : super(
        fromJson: (json) => ChatModel.fromJson(json),
        toJson: (chat) => chat.toJson(),
        getId: (chat) => chat.id,
      );

  @override
  String getEndpoint() => 'chat';

  // ─── SignalR ──────────────────────────────────────────────────────────────
  @override
  Future<void> connectSignalR(String userId) async {
    if (_hubConnection != null &&
        _hubConnection!.state == HubConnectionState.Connected)
      return;

    final hubUrl = '${dio.options.baseUrl.replaceAll('/api', '')}chathub';

    _hubConnection =
        HubConnectionBuilder().withUrl(hubUrl).withAutomaticReconnect().build();

    _hubConnection!.on('ReceiveMessage', (args) {
      if (args == null || args.isEmpty) return;
      // print('📨 [RECEIVE] raw args: $args');
      // print('📨 [RECEIVE] args[0]: ${args[0]}');

      final msg = MessageModel.fromJson(args[0] as Map<String, dynamic>);
      // print('📨 [RECEIVE] parsed id: ${msg.id}');
      // print('📨 [RECEIVE] parsed content: ${msg.content}');
      // print('📨 [RECEIVE] parsed senderId: ${msg.senderId}');

      if (msg.id == _lastSentMessageId) return;

      final controller = _messageControllers[_activeChatId];
      if (controller != null && !controller.isClosed) {
        controller.add([msg]);
      }
    });

    _hubConnection!.on('ChatUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final chat = ChatModel.fromJson(args[0] as Map<String, dynamic>);
      for (final controller in _chatControllers.values) {
        if (!controller.isClosed) controller.add([chat]);
      }
    });

    // args: [chatId, userId, isTyping] — ignore our own typing echo.
    _hubConnection!.on('UserTyping', (args) {
      if (args == null || args.length < 3) return;
      final chatId = args[0]?.toString() ?? '';
      final typingUserId = args[1]?.toString() ?? '';
      final isTyping = args[2] == true;
      if (typingUserId == UserController.instance.user.value.id) return;

      final controller = _typingControllers[chatId];
      if (controller != null && !controller.isClosed) controller.add(isTyping);
    });

    // args: [chatId, userId] — the other participant marked messages as seen.
    _hubConnection!.on('MessagesRead', (args) {
      if (args == null || args.isEmpty) return;
      final chatId = args[0]?.toString() ?? '';
      final readerUserId = args.length > 1 ? (args[1]?.toString() ?? '') : '';

      final controller = _seenControllers[chatId];
      if (controller != null && !controller.isClosed)
        controller.add(readerUserId);
    });

    await _hubConnection!.start();
    await _hubConnection!.invoke('JoinUserChannel', args: [userId]);
  }

  Future<void> joinChat(String chatId) async {
    _activeChatId = chatId;
    await _hubConnection?.invoke('JoinChat', args: [chatId]);
  }

  Future<void> leaveChat(String chatId) async {
    await _hubConnection?.invoke('LeaveChat', args: [chatId]);
    _messageControllers[chatId]?.close();
    _messageControllers.remove(chatId);
    _typingControllers[chatId]?.close();
    _typingControllers.remove(chatId);
    _seenControllers[chatId]?.close();
    _seenControllers.remove(chatId);
    if (_activeChatId == chatId) _activeChatId = null;
  }

  Future<void> sendTyping(String chatId, String userId, bool isTyping) async {
    await _hubConnection?.invoke('Typing', args: [chatId, userId, isTyping]);
  }

  /// Emits `true`/`false` whenever the other participant starts/stops typing
  /// in [chatId] (SignalR `UserTyping` event).
  Stream<bool> listenToTyping(String chatId) {
    _typingControllers[chatId]?.close();
    final controller = StreamController<bool>.broadcast();
    _typingControllers[chatId] = controller;
    return controller.stream;
  }

  /// Emits the reader's userId whenever the other participant marks messages
  /// in [chatId] as seen (SignalR `MessagesRead` event).
  Stream<String> listenToSeenEvents(String chatId) {
    _seenControllers[chatId]?.close();
    final controller = StreamController<String>.broadcast();
    _seenControllers[chatId] = controller;
    return controller.stream;
  }

  // ─── listenToMessages ─────────────────────────────────────────────────────

  @override
  Stream<List<MessageModel>> listenToMessages(String chatId) {
    _messageControllers[chatId]?.close();
    _messageControllers.remove(chatId);

    final controller = StreamController<List<MessageModel>>.broadcast();
    _messageControllers[chatId] = controller;

    joinChat(chatId).then((_) async {
      final messages = await fetchMessages(chatId);
      if (!controller.isClosed) controller.add(messages);
    });

    return controller.stream;
  }

  // ─── listenToAllChats ─────────────────────────────────────────────────────

  @override
  Stream<List<ChatModel>> listenToAllChats(ChatType chatType) {
    final key = chatType.name;
    _chatControllers[key]?.close();
    _chatControllers.remove(key);

    final controller = StreamController<List<ChatModel>>.broadcast();
    _chatControllers[key] = controller;

    getChatsByTypeOnly(chatType).then((chats) {
      if (!controller.isClosed) controller.add(chats);
    });

    return controller.stream;
  }

  // ─── fetchUserChats ───────────────────────────────────────────────────────

  @override
  Future<List<ChatModel>> fetchUserChats(String currentUserId) async {
    try {
      final response = await dio.get('${getEndpoint()}/user/$currentUserId');
      if (isSuccess(response.data)) {
        final List data = (dataOf(response.data) as List?) ?? const [];
        return data
            .map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      throw messageOf(response.data) ?? 'Failed to fetch chats';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── fetchMessages ────────────────────────────────────────────────────────

  @override
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$chatId/messages');
      if (isSuccess(response.data)) {
        final List data = (dataOf(response.data) as List?) ?? const [];
        return data
            .map(
              (e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      throw messageOf(response.data) ?? 'Failed to fetch messages';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── markMessagesAsSeen ───────────────────────────────────────────────────

  @override
  Future<void> markMessagesAsSeen(String chatId, String currentUserId) async {
    try {
      final response = await dio.put(
        '${getEndpoint()}/$chatId/seen',
        data: {'userId': currentUserId},
      );
      if (!isSuccess(response.data)) {
        throw messageOf(response.data) ?? 'Failed to mark as seen';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── createChat ───────────────────────────────────────────────────────────

  @override
  Future<ChatModel?> createChat(ChatModel chat) async {
    try {
      final response = await dio.post(getEndpoint(), data: chat.toJson());
      if (isSuccess(response.data)) {
        return ChatModel.fromJson(
          Map<String, dynamic>.from(dataOf(response.data) as Map),
        );
      }
      throw messageOf(response.data) ?? 'Failed to create chat';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── createSupportChat ────────────────────────────────────────────────────

  /// Kullanıcının destek sohbetini açar.
  ///
  /// 🔴 Gövde **web ile birebir** (`services/chat.service.js` → `Chat.ensure`):
  /// yalnız `participantIds`, `chatType` ve `title`. Destek tarafını sunucu
  /// kendisi ekliyor; istemcinin admin kullanıcısını bulup katılımcı listesine
  /// yazması gerekmiyor — admin sorgusu 401 verdiğinde sohbet hiç açılmıyordu.
  @override
  Future<ChatModel?> createSupportChat(String userId) async {
    try {
      final response = await dio.post(
        getEndpoint(),
        data: {
          'participantIds': [userId],
          'chatType': ChatType.support.name,
          'title': 'Support Chat',
        },
      );
      if (isSuccess(response.data)) {
        return ChatModel.fromJson(
          Map<String, dynamic>.from(dataOf(response.data) as Map),
        );
      }
      throw messageOf(response.data) ?? 'Failed to create chat';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── sendMessage ──────────────────────────────────────────────────────────

  @override
  Future<String> sendMessage(String chatId, MessageModel message) async {
    try {
      // Her zaman HTTP ile gönder — id güvenli gelsin.
      final response = await dio.post(
        '${getEndpoint()}/$chatId/messages',
        data: message.toMap(),
      );
      if (isSuccess(response.data)) {
        final data = dataOf(response.data);
        final sentId = data is Map
            ? (data['Id'] ?? data['id'])?.toString() ?? message.id
            : message.id;
        _lastSentMessageId = sentId;
        return sentId;
      }
      throw messageOf(response.data) ?? 'Failed to send message';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── uploadAttachment ─────────────────────────────────────────────────────

  /// Sohbete dosya eki yükler (`chat/{chatId}/upload`, multipart).
  ///
  /// 🔴 **Sunucu bu ucu desteklemiyorsa sessizce `null` döner** — web
  /// (`Chat.upload`) de öyle yapıyor. Ek atılamadı diye sohbetin tamamı
  /// çökmemeli; çağıran yalnız "gönderilemedi" der ve yazışma devam eder.
  /// Dönen değer, mesaja `mediaUrl` olarak yazılacak adrestir.
  @override
  Future<String?> uploadAttachment({
    required String chatId,
    required Uint8List fileData,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileData,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await dio.post(
        '${getEndpoint()}/$chatId/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (!isSuccess(response.data)) return null;

      // Uç ya düz metin (adres) ya da `{ mediaUrl | url }` nesnesi döndürüyor.
      final data = dataOf(response.data);
      if (data is String) return data.isEmpty ? null : data;
      if (data is Map) {
        final url = (data['MediaUrl'] ??
                data['mediaUrl'] ??
                data['Url'] ??
                data['url'])
            ?.toString();
        return (url == null || url.isEmpty) ? null : url;
      }
      return null;
    } catch (e) {
      TLoggerHelper.warning('Sohbet eki yüklenemedi: $e');
      return null;
    }
  }

  // ─── getChatsByType ───────────────────────────────────────────────────────

  @override
  Future<List<ChatModel>> getChatsByType(
    String currentUserId,
    ChatType chatType,
  ) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/user/$currentUserId/type/${chatType.name}',
      );
      if (isSuccess(response.data)) {
        final List data = (dataOf(response.data) as List?) ?? const [];

        // Tek bir bozuk kayıt bütün listeyi düşürmesin: sohbeti bulamayınca
        // istemci YENİSİNİ açar ve destek ekibinde ikinci bir konu oluşur.
        final chats = <ChatModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            chats.add(ChatModel.fromJson(Map<String, dynamic>.from(data[i] as Map)));
          } catch (e) {
            TLoggerHelper.warning('Sohbet çözümlenemedi [$i]: $e');
          }
        }
        return chats;
      }
      throw messageOf(response.data) ?? 'Failed to fetch chats by type';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── getChatsByTypeOnly ───────────────────────────────────────────────────

  @override
  Future<List<ChatModel>> getChatsByTypeOnly(ChatType chatType) async {
    final userId = UserController.instance.user.value.id;
    return getChatsByType(userId, chatType);
  }

  // ─── getChatById ──────────────────────────────────────────────────────────

  @override
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$chatId');
      if (isSuccess(response.data)) {
        return ChatModel.fromJson(
          Map<String, dynamic>.from(dataOf(response.data) as Map),
        );
      }
      throw messageOf(response.data) ?? 'Chat not found';
    } catch (e) {
      throw handleException(e);
    }
  }
  // ─── markChatAsRead ───────────────────────────────────────────────────────

  @override
  Future<void> markChatAsRead(String chatId) async {
    await markMessagesAsSeen(chatId, '');
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    super.dispose();
    for (final c in _messageControllers.values) c.close();
    for (final c in _chatControllers.values) c.close();
    for (final c in _typingControllers.values) c.close();
    for (final c in _seenControllers.values) c.close();
    _hubConnection?.stop();
  }
}
