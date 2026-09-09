import '../../../features/chat/models/chat_model.dart';
import '../../../features/chat/models/message_model.dart';
import '../../../utils/constants/enums.dart';

/// Sohbet repository sözleşmesi.
abstract class ChatRepository {
  Future<void> connectSignalR(String userId);
  Stream<List<MessageModel>> listenToMessages(String chatId);
  Stream<List<ChatModel>> listenToAllChats(ChatType chatType);
  Future<List<ChatModel>> fetchUserChats(String currentUserId);
  Future<List<MessageModel>> fetchMessages(String chatId);
  Future<void> markMessagesAsSeen(String chatId, String currentUserId);
  Future<ChatModel?> createChat(ChatModel chat);
  Future<String> sendMessage(String chatId, MessageModel message);
  Future<List<ChatModel>> getChatsByType(String currentUserId, ChatType chatType);
  Future<List<ChatModel>> getChatsByTypeOnly(ChatType chatType);
  Future<ChatModel> getChatById(String chatId);
  Future<void> markChatAsRead(String chatId);

  /// Destek sohbetini web ile aynı gövdeyle açar (yalnız kendi kimliğimiz).
  Future<ChatModel?> createSupportChat(String userId);
}
