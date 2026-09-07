// FAZ 10 — destek sohbeti.
//
// Bu dosya fazın üç kritik kuralını kalıcı olarak sabitler:
//   1. YOKLAMA yalnız panel açıkken, uygulama ön plandayken ve girişli
//      kullanıcıda döner — arka planda sayaç boşa dönmemeli.
//   2. Sunucudan gelen liste, henüz sunucuya ulaşmamış (ya da gönderilemeyip
//      `failed` kalmış) yerel mesajları ekrandan SİLMEZ.
//   3. Sohbet ve mesaj modelleri, sunucunun İKİ YAZIMINI da (`Id`/`id`)
//      okur — .NET zarfı büyük harfle geliyor.
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tstore_ecommerce_app/features/chat/controllers/chat_controller.dart';
import 'package:tstore_ecommerce_app/features/chat/models/chat_model.dart';
import 'package:tstore_ecommerce_app/features/chat/models/message_model.dart';
import 'package:tstore_ecommerce_app/utils/constants/enums.dart';

MessageModel _msg({
  required String id,
  required String sender,
  required String content,
  required DateTime at,
  MessageType type = MessageType.text,
  ChatMessageStatus status = ChatMessageStatus.sent,
}) =>
    MessageModel(
      id: id,
      senderId: sender,
      content: content,
      timestamp: at,
      status: status,
      type: type,
    );

void main() {
  final t0 = DateTime(2026, 9, 7, 10, 0);

  group('Yoklama kapısı', () {
    test('panel açık + ön plan + girişli + sohbet var → yoklar', () {
      expect(
        ChatController.shouldPoll(
          panelOpen: true,
          appResumed: true,
          isGuest: false,
          hasChat: true,
        ),
        isTrue,
      );
    });

    test('uygulama ARKA PLANDAYKEN yoklama DURUR', () {
      expect(
        ChatController.shouldPoll(
          panelOpen: true,
          appResumed: false,
          isGuest: false,
          hasChat: true,
        ),
        isFalse,
      );
    });

    test('panel kapalıyken yoklama durur', () {
      expect(
        ChatController.shouldPoll(
          panelOpen: false,
          appResumed: true,
          isGuest: false,
          hasChat: true,
        ),
        isFalse,
      );
    });

    test('misafir kullanıcıda hiç yoklanmaz', () {
      expect(
        ChatController.shouldPoll(
          panelOpen: true,
          appResumed: true,
          isGuest: true,
          hasChat: true,
        ),
        isFalse,
      );
    });

    test('sohbet henüz açılmamışken yoklanmaz', () {
      expect(
        ChatController.shouldPoll(
          panelOpen: true,
          appResumed: true,
          isGuest: false,
          hasChat: false,
        ),
        isFalse,
      );
    });
  });

  group('Mesaj birleştirme', () {
    test('sunucu listesi YENİDEN ESKİYE dizilir (index 0 en yeni)', () {
      final merged = ChatController.mergeMessages([
        _msg(id: '1', sender: 'u', content: 'eski', at: t0),
        _msg(id: '2', sender: 'u', content: 'yeni', at: t0.add(const Duration(minutes: 5))),
      ], const []);

      expect(merged.map((m) => m.id).toList(), ['2', '1']);
    });

    test('sunucuya ULAŞMAMIŞ yerel mesaj listede KALIR', () {
      final local = [
        _msg(
          id: '${ChatController.tempIdPrefix}1',
          sender: 'u',
          content: 'gitmedi',
          at: t0.add(const Duration(minutes: 9)),
          status: ChatMessageStatus.failed,
        ),
      ];

      final merged = ChatController.mergeMessages(
        [_msg(id: '1', sender: 'u', content: 'gitti', at: t0)],
        local,
      );

      expect(merged.length, 2);
      expect(merged.first.id, '${ChatController.tempIdPrefix}1');
      expect(merged.first.status, ChatMessageStatus.failed);
    });

    test('sunucuda karşılığı BULUNAN yerel mesaj KOPYA bırakmaz', () {
      final local = [
        _msg(
          id: '${ChatController.tempIdPrefix}1',
          sender: 'u',
          content: 'merhaba',
          at: t0.add(const Duration(seconds: 1)),
          status: ChatMessageStatus.sending,
        ),
      ];

      final merged = ChatController.mergeMessages(
        [_msg(id: 'srv-1', sender: 'u', content: 'merhaba', at: t0)],
        local,
      );

      expect(merged.length, 1);
      expect(merged.single.id, 'srv-1');
    });

    test('aynı metin iki kez yazıldıysa ikinci mesaj KAYBOLMAZ', () {
      // Her yerel mesaj TEK bir sunucu mesajını sahiplenir; yoksa iki kez
      // "tamam" yazan kullanıcının ikincisi ekrandan siliniyordu.
      final local = [
        _msg(
          id: '${ChatController.tempIdPrefix}2',
          sender: 'u',
          content: 'tamam',
          at: t0.add(const Duration(seconds: 2)),
        ),
        _msg(
          id: '${ChatController.tempIdPrefix}1',
          sender: 'u',
          content: 'tamam',
          at: t0.add(const Duration(seconds: 1)),
        ),
      ];

      final merged = ChatController.mergeMessages(
        [_msg(id: 'srv-1', sender: 'u', content: 'tamam', at: t0)],
        local,
      );

      // Biri sunucudaki mesajla eşleşti, diğeri hâlâ yolda → toplam 2 satır.
      expect(merged.length, 2);
      expect(merged.where((m) => m.id.startsWith(ChatController.tempIdPrefix)).length, 1);
    });

    test('sunucu kimlikli yerel mesajlar taşınmaz (sunucu listesi esas)', () {
      final local = [_msg(id: 'srv-9', sender: 'u', content: 'silinen', at: t0)];
      final merged = ChatController.mergeMessages(
        [_msg(id: 'srv-1', sender: 'u', content: 'kalan', at: t0)],
        local,
      );

      expect(merged.map((m) => m.id).toList(), ['srv-1']);
    });
  });

  group('Sunucu zarfı — iki yazım da okunur', () {
    test('MessageModel büyük harfli alanları okur', () {
      final m = MessageModel.fromJson({
        'Id': 'abc',
        'SenderId': 'u1',
        'Content': 'merhaba',
        'Timestamp': '2026-09-07T10:00:00Z',
        'Status': 'read',
        'Type': 'text',
      });

      expect(m.id, 'abc');
      expect(m.senderId, 'u1');
      expect(m.status, ChatMessageStatus.read);
      expect(m.type, MessageType.text);
    });

    test('MessageModel küçük harfli alanları da okur', () {
      final m = MessageModel.fromJson({
        'id': 'abc',
        'senderId': 'u1',
        'content': 'merhaba',
        'type': 'image',
        'mediaUrl': 'https://ecom.aycom.kz:5006/images/x.png',
      });

      expect(m.id, 'abc');
      expect(m.type, MessageType.image);
      expect(m.mediaUrl, 'https://ecom.aycom.kz:5006/images/x.png');
    });

    test('ChatModel destek sohbetini çözer', () {
      final chat = ChatModel.fromJson({
        'Id': 'c1',
        'ChatType': 'support',
        'ParticipantIds': ['u1'],
        'Participants': [
          {'UserId': 'u1', 'Name': 'Ali', 'ProfileImageUrl': ''},
        ],
        'LastMessage': 'merhaba',
        'LastMessageType': 'text',
      });

      expect(chat.id, 'c1');
      expect(chat.chatType, ChatType.support);
      expect(chat.participants.single.name, 'Ali');
      expect(chat.lastMessage, 'merhaba');
    });

    test('bilinmeyen mesaj türü metne düşer, patlamaz', () {
      expect(MessageModel.messageTypeFromString('video'), MessageType.text);
    });
  });
}
