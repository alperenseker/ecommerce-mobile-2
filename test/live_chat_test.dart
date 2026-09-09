// GEÇİCİ: FAZ 10 doğrulaması — destek sohbeti uçları GERÇEK HESAPLA denenir.
// Faz sonunda silinecek.
//
// ⚠️ Resim/dosya gönderme uygulamada YOK (kullanıcının 2026-09-09 kararı),
// bu yüzden yükleme ucu da sınanmıyor.
//
// 🔴 Bu test canlı sunucuya MESAJ YAZAR (destek ekibi görüyor). Bu yüzden
// yalnız TEK bir işaretli doğrulama mesajı gönderilir; sohbet AÇILMAZ —
// kullanıcının var olan destek sohbeti bulunup kullanılır. Var olan sohbet
// bulunamazsa test yeni sohbet açmak yerine BAŞARISIZ olur: "her açılışta yeni
// sohbet açma" kuralını sınayan testin kendisi o kuralı çiğnememeli.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/api_auth.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/chat/api_chat_repository.dart';
import 'package:tstore_ecommerce_app/features/chat/models/chat_model.dart';
import 'package:tstore_ecommerce_app/features/chat/models/message_model.dart';
import 'package:tstore_ecommerce_app/utils/constants/enums.dart';

// ignore_for_file: avoid_print

late String userId;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('gs').path,
    );
    await GetStorage.init();
    HttpOverrides.global = null;

    final res = await ApiAuth.loginWithEmailPassword(
      email: 'royalprof@gmail.com',
      password: '123456',
    );
    expect(res['success'], true, reason: 'gerçek hesapla giriş yapılamadı');
    userId = res['user']['userId'].toString();

    final repo = Get.put(AuthenticationRepository());
    repo.customAuthToken.value = res['token'];
    repo.customUserId.value = userId;
    repo.isCustomAuthUser.value = true;

    Get.put(ApiChatRepository());
    print('LOGIN userId=$userId');
  });

  test('var olan destek sohbeti BULUNUYOR (yeni açılmıyor)', () async {
    final chats = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);

    expect(chats, isNotEmpty,
        reason: 'destek sohbeti bulunamadı; tek-sohbet kuralı sınanamıyor');
    print('SOHBET id=${chats.first.id} · katılımcı=${chats.first.participants.length}');

    // İkinci çağrı da AYNI sohbeti döndürmeli; farklıysa bir yerde yeni sohbet
    // açılıyor demektir.
    final again = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);
    expect(again.first.id, chats.first.id);
    expect(chats.length, again.length);
  });

  test('sohbet zarfı ve katılımcılar okunuyor', () async {
    final chats = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);
    final ChatModel chat = chats.first;

    expect(chat.id, isNotEmpty);
    expect(chat.chatType, ChatType.support);
    expect(chat.participantIds, contains(userId));
    // Sunucu destek tarafını da katılımcı olarak yazıyor.
    print('KATILIMCILAR ${chat.participants.map((p) => p.name).toList()}');
  });

  test('geçmiş yükleniyor ve ESKİDEN YENİYE geliyor', () async {
    final chats = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);
    final messages =
        await ApiChatRepository.instance.fetchMessages(chats.first.id);

    expect(messages, isNotEmpty, reason: 'geçmiş boş döndü');
    print('GEÇMİŞ ${messages.length} mesaj · ilk=${messages.first.timestamp}'
        ' son=${messages.last.timestamp}');

    // 🔴 Sunucu sırası eskiden yeniye; ekran ters çeviriyor (bkz.
    // ChatController._normalize). Bu sıra değişirse ekran ters dizilir.
    expect(
      messages.first.timestamp.isAfter(messages.last.timestamp),
      isFalse,
      reason: 'sunucu sırası değişmiş — _normalize gözden geçirilmeli',
    );
  });

  test('mesaj gönderiliyor ve geçmişte görünüyor', () async {
    final chats = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);
    final chatId = chats.first.id;

    final before =
        await ApiChatRepository.instance.fetchMessages(chatId);

    final content =
        'FAZ 10 doğrulama · ${DateTime.now().toIso8601String()}';
    final sentId = await ApiChatRepository.instance.sendMessage(
      chatId,
      MessageModel(
        id: '',
        senderId: userId,
        content: content,
        timestamp: DateTime.now(),
        status: ChatMessageStatus.sending,
        type: MessageType.text,
      ),
    );

    expect(sentId, isNotEmpty);
    print('GÖNDERİLDİ id=$sentId');

    final after = await ApiChatRepository.instance.fetchMessages(chatId);
    expect(after.length, before.length + 1);
    expect(after.any((m) => m.content == content), isTrue);
  });

  test('okundu bilgisi sunucuda işleniyor', () async {
    final chats = await ApiChatRepository.instance
        .getChatsByType(userId, ChatType.support);

    // Fırlatmazsa geçti; uç `{"success":true}` dönüyor.
    await ApiChatRepository.instance
        .markMessagesAsSeen(chats.first.id, userId);
    print('OKUNDU işlendi');
  });

}
