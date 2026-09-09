import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../../../utils/constants/enums.dart';

/// Sohbetteki tek mesaj (metin, ek, gönderen, okundu bilgisi).
class MessageModel {
  String id;
  String senderId;
  String content;
  DateTime timestamp;
  ChatMessageStatus status;
  MessageType type;
  String? mediaUrl; // URL for voice/image media
  String? replyToMessageId; // If this is a reply
  String? replyToMessageContent; // Content of the message being replied to
  MessageType? replyToMessageType; // Type of the message being replied to
  int? size; // Size of the audio file in bytes
  Duration? audioDuration; // Duration of the audio file
  List<double>? audioWaveData; // Audio wave data for visualization

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.status,
    required this.type,
    this.mediaUrl,
    this.replyToMessageId,
    this.replyToMessageContent,
    this.replyToMessageType,
    this.size,
    this.audioDuration,
    this.audioWaveData,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['Id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['SenderId'] ?? json['senderId'] ?? '',
      content: json['Content'] ?? json['content'] ?? '',
      timestamp:
          (json['Timestamp'] ?? json['timestamp']) != null
              ? DateTime.tryParse(
                    (json['Timestamp'] ?? json['timestamp']).toString(),
                  ) ??
                  DateTime.now()
              : DateTime.now(),
      status:
          (json['Status'] ?? json['status']) != null
              ? MessageModel.messageStatusFromString(
                json['Status'] ?? json['status'],
              )
              : ChatMessageStatus.sent,
      type:
          (json['Type'] ?? json['type']) != null
              ? MessageModel.messageTypeFromString(json['Type'] ?? json['type'])
              : MessageType.text,
      mediaUrl: json['MediaUrl'] ?? json['mediaUrl'],
      replyToMessageId: json['ReplyToMessageId'] ?? json['replyToMessageId'],
      replyToMessageContent:
          json['ReplyToMessageContent'] ?? json['replyToMessageContent'],
      replyToMessageType:
          (json['ReplyToMessageType'] ?? json['replyToMessageType']) != null
              ? MessageModel.messageTypeFromString(
                json['ReplyToMessageType'] ?? json['replyToMessageType'],
              )
              : null,
      size: json['Size'] ?? json['size'],
      audioDuration:
          (json['AudioDuration'] ?? json['audioDuration']) != null
              ? Duration(
                milliseconds: json['AudioDuration'] ?? json['audioDuration'],
              )
              : null,
      audioWaveData:
          (json['AudioWaveData'] ?? json['audioWaveData']) != null
              ? List<double>.from(
                json['AudioWaveData'] ?? json['audioWaveData'],
              )
              : null,
    );
  }

  // Convert MessageModel to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
      'replyToMessageType': replyToMessageType?.name,
      'size': size, // Add this line
      'audioDuration': audioDuration?.inMilliseconds, // Add this line
      'audioWaveData': audioWaveData, // Add this line
    };
  }

  // Helper function to convert string to MessageStatus
  static ChatMessageStatus messageStatusFromString(String status) {
    switch (status) {
      case 'read':
        return ChatMessageStatus.read;
      case 'delivered':
        return ChatMessageStatus.delivered;
      case 'sent':
        return ChatMessageStatus.sent;
      case 'failed':
        return ChatMessageStatus.failed;
      case 'sending':
        return ChatMessageStatus.sending;
      default:
        return ChatMessageStatus.failed;
    }
  }

  // Helper function to convert string to MessageType
  static MessageType messageTypeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'audio':
        return MessageType.audio;
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}
