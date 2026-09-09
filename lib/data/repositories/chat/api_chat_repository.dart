import 'dart:async';

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../features/chat/models/chat_model.dart';
import '../../../features/chat/models/message_model.dart';
// FAZ 09 — UserController o fazda geliyor. O zamana kadar aynı değeri
// (oturumdaki kullanıcı kimliği) AuthenticationRepository'den okuyoruz.
// import '../../../features/personalization/controllers/user_controller.dart';
import '../authentication/authentication_repository.dart';
import '../../../utils/constants/enums.dart';
import 'chat_repository.dart';

/// Destek sohbeti uçları (`chat/...`) ve SignalR canlı bağlantısı.
///
/// Mesajlar hem HTTP ile çekilir hem de hub üzerinden anlık gelir; yazıyor/okundu
/// bildirimleri kendi yankımızı ayıklamak için gönderen kimliğine bakar.
class ApiChatRepository extends TApiRepositoryController<ChatModel>
    implements ChatRepository {
  static ApiChatRepository get instance => Get.find();

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
      if (typingUserId == AuthenticationRepository.instance.getUserID) return;

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
        final List data = (dataOf(response.data) as List?) ?? [];
        return data.map((e) => ChatModel.fromJson(e)).toList();
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
        final List data = (dataOf(response.data) as List?) ?? [];
        // print(
          // '📨 [FETCH MESSAGES] raw first: ${data.isNotEmpty ? data[0] : 'EMPTY'}',
        // );
        // print('📨 [FETCH MESSAGES] total count: ${data.length}');
        // print(
          // '📨 [FETCH MESSAGES] all ids: ${data.map((e) => e['Id'] ?? e['id']).toList()}',
        // );
        return data.map((e) => MessageModel.fromJson(e)).toList();
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
        return ChatModel.fromJson(Map<String, dynamic>.from(dataOf(response.data) as Map));
      }
      throw messageOf(response.data) ?? 'Failed to create chat';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── createSupportChat ────────────────────────────────────────────────────

  /// Destek sohbetini web ile **birebir aynı** gövdeyle açar.
  ///
  /// 🔴 Referans mobil uygulama önce `users?role=admin` ile yönetici kimliğini
  /// arayıp katılımcı listesine yazıyordu; o sorgu normal kullanıcı jetonuyla
  /// 401 dönünce sohbet hiç açılamıyordu. Web (`chat.service.js` → `ensure()`)
  /// yalnız kendi kimliğini gönderiyor, karşı tarafı sunucu ekliyor.
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
        final data = dataOf(response.data);
        if (data is Map) {
          return ChatModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw messageOf(response.data) ?? 'Failed to create support chat';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── sendMessage ──────────────────────────────────────────────────────────

  @override
  Future<String> sendMessage(String chatId, MessageModel message) async {
    try {
      // Her zaman HTTP ile gönder — id güvenli gelsin
      final response = await dio.post(
        '${getEndpoint()}/$chatId/messages',
        data: message.toMap(),
      );
      if (isSuccess(response.data)) {
        final sent = dataOf(response.data);
        final sentId =
            (sent is Map
                ? (sent['Id'] ?? sent['id'])?.toString()
                : null) ??
            message.id;
        _lastSentMessageId = sentId;
        // print('✅ [SEND HTTP] messageId: $sentId');
        return sentId;
      }
      throw messageOf(response.data) ?? 'Failed to send message';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── getChatsByType ───────────────────────────────────────────────────────

  Future<List<ChatModel>> getChatsByType(
    String currentUserId,
    ChatType chatType,
  ) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/user/$currentUserId/type/${chatType.name}',
      );
      if (isSuccess(response.data)) {
        final List data = (dataOf(response.data) as List?) ?? [];
        // print('🔍 [CHATS] raw data: $data');

        // Her item'ı tek tek parse et, hangisi patlıyor görelim
        final chats = <ChatModel>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final chat = ChatModel.fromJson(data[i] as Map<String, dynamic>);
            // print('🔍 [CHATS] parsed[$i] id: ${chat.id}');
            chats.add(chat);
          } catch (e) {
            // print('❌ [CHATS] parse error at [$i]: $e');
            // print('❌ [CHATS] item[$i]: ${data[i]}');
          }
        }
        return chats;
      }
      throw messageOf(response.data) ?? 'Failed to fetch chats by type';
    } catch (e) {
      // print('❌ [CHATS] exception: $e');
      throw handleException(e);
    }
  }

  // ─── getChatsByTypeOnly ───────────────────────────────────────────────────

  @override
  Future<List<ChatModel>> getChatsByTypeOnly(ChatType chatType) async {
    try {
      final userId = AuthenticationRepository.instance.getUserID;
      final response = await dio.get(
        '${getEndpoint()}/user/$userId/type/${chatType.name}',
      );

      if (isSuccess(response.data)) {
        final List data = (dataOf(response.data) as List?) ?? [];
        return data.map((e) => ChatModel.fromJson(e)).toList();
      }
      throw messageOf(response.data) ?? 'Failed to fetch chats';
    } catch (e) {
      throw handleException(e);
    }
  }

  // ─── getChatById ──────────────────────────────────────────────────────────

  @override
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final response = await dio.get('${getEndpoint()}/$chatId');
      if (isSuccess(response.data)) {
        return ChatModel.fromJson(Map<String, dynamic>.from(dataOf(response.data) as Map));
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
