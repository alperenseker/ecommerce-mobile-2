/// Sohbet repository'sinin arayüzü.
///
/// Uçlar `faz/API.md` → **Sohbet** bölümüyle birebirdir:
/// `chat/user/{userId}/type/{chatType}` · `chat` (POST) ·
/// `chat/{chatId}/messages` (GET/POST) · `chat/{chatId}/seen` (PUT) ·
/// `chat/{chatId}/upload` (multipart).
library;

import 'dart:typed_data';

import '../../../features/chat/models/chat_model.dart';
import '../../../features/chat/models/message_model.dart';
import '../../../utils/constants/enums.dart';

abstract class ChatRepository {
  Future<void> connectSignalR(String userId);
  Stream<List<MessageModel>> listenToMessages(String chatId);
  Stream<List<ChatModel>> listenToAllChats(ChatType chatType);
  Future<List<ChatModel>> fetchUserChats(String currentUserId);
  Future<List<MessageModel>> fetchMessages(String chatId);
  Future<void> markMessagesAsSeen(String chatId, String currentUserId);
  Future<ChatModel?> createChat(ChatModel chat);

  /// Destek sohbetini web ile birebir gövdeyle açar
  /// (`{ participantIds, chatType, title }`).
  Future<ChatModel?> createSupportChat(String userId);

  Future<String> sendMessage(String chatId, MessageModel message);

  /// Dosya ekini yükler; **sunucu desteklemiyorsa `null` döner**, fırlatmaz.
  Future<String?> uploadAttachment({
    required String chatId,
    required Uint8List fileData,
    required String filename,
    required String mimeType,
  });

  Future<List<ChatModel>> getChatsByType(String currentUserId, ChatType chatType);
  Future<List<ChatModel>> getChatsByTypeOnly(ChatType chatType);
  Future<ChatModel> getChatById(String chatId);
  Future<void> markChatAsRead(String chatId);
}
