import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../../../utils/constants/enums.dart';
import 'message_model.dart';
import 'participant_model.dart';

/// Sohbet başlığı (katılımcılar, son mesaj, okunmamış sayısı).
class ChatModel {
  String id;
  List<ParticipantModel> participants; // List of ParticipantModel instances
  String lastMessage;
  MessageType lastMessageType;
  DateTime lastMessageTime;
  ChatMessageStatus lastMessageStatus;
  bool isGroupChat;
  String lastMessageSenderId;
  ChatType chatType;
  List<String> participantIds; // List of participant userIds for querying
  String referenceId;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantIds, // New field
    this.lastMessageType = MessageType.text,
    this.lastMessage = '',
    this.lastMessageStatus = ChatMessageStatus.failed,
    required this.lastMessageTime,
    this.isGroupChat = false,
    this.lastMessageSenderId = '',
    required this.chatType,
    required this.referenceId,
  });

  factory ChatModel.empty() => ChatModel(
    id: '',
    participants: [],
    participantIds: [],
    lastMessageTime: DateTime.now(),
    chatType: ChatType.support,
    referenceId: '',
  );

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['Id']?.toString() ?? json['id']?.toString() ?? '',
      participants:
          ((json['Participants'] ?? json['participants']) as List?)
              ?.map(
                (p) => ParticipantModel.fromJson(Map<String, dynamic>.from(p)),
              )
              .toList() ??
          [],
      participantIds:
          ((json['ParticipantIds'] ?? json['participantIds']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastMessage: json['LastMessage'] ?? json['lastMessage'] ?? '',
      lastMessageType:
          (json['LastMessageType'] ?? json['lastMessageType']) != null
              ? MessageModel.messageTypeFromString(
                json['LastMessageType'] ?? json['lastMessageType'],
              )
              : MessageType.text,
      lastMessageTime:
          (json['LastMessageTime'] ?? json['lastMessageTime']) != null
              ? DateTime.tryParse(
                    (json['LastMessageTime'] ?? json['lastMessageTime'])
                        .toString(),
                  ) ??
                  DateTime.now()
              : DateTime.now(),
      lastMessageStatus:
          (json['LastMessageStatus'] ?? json['lastMessageStatus']) != null
              ? messageStatusFromString(
                json['LastMessageStatus'] ?? json['lastMessageStatus'],
              )
              : ChatMessageStatus.failed,
      isGroupChat: json['IsGroupChat'] ?? json['isGroupChat'] ?? false,
      lastMessageSenderId:
          json['LastMessageSenderId'] ?? json['lastMessageSenderId'] ?? '',
      chatType:
          (json['ChatType'] ?? json['chatType']) != null
              ? chatTypeFromString(json['ChatType'] ?? json['chatType'])
              : ChatType.support,
      referenceId: json['ReferenceId'] ?? json['referenceId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType.name,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'isGroupChat': isGroupChat,
      'lastMessageStatus': lastMessageStatus.name,
      'lastMessageSenderId': lastMessageSenderId,
      'chatType': chatType.name,
      'referenceId': referenceId,
    };
  }
}

ChatMessageStatus messageStatusFromString(String messageStatus) {
  switch (messageStatus.toLowerCase()) {
    case 'read':
      return ChatMessageStatus.read;
    case 'delivered':
      return ChatMessageStatus.delivered;
    case 'sent':
      return ChatMessageStatus.sent;
    case 'failed':
      return ChatMessageStatus.failed;
    default:
      return ChatMessageStatus.failed;
  }
}

ChatType chatTypeFromString(String chatType) {
  switch (chatType.toLowerCase()) {
    case 'support':
      return ChatType.support;
    default:
      return ChatType.support;
  }
}
