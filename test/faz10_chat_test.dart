// FAZ 10 — destek sohbetinin iş kuralları (ağa çıkmaz).
//
// Canlı uç doğrulaması `live_chat_test.dart` içinde; burada yalnız istem
// dosyasındaki maddelerin saf karşılıkları sınanıyor:
//   · yoklama YALNIZ panel açık + uygulama önde + girişli + sohbet varken döner
//   · sunucu her yoklamada TÜM geçmişi döndürüyor; birleştirme henüz gitmemiş
//     yerel mesajı ekrandan silmemeli
//   · aynı metni iki kez yazan kullanıcıda ikinci mesaj kaybolmamalı
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/common/widgets/loaders/t_empty_state.dart';
import 'package:tstore_ecommerce_app/data/repositories/chat/api_chat_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/settings/api_settings_repository.dart';
import 'package:tstore_ecommerce_app/data/repositories/user/api_user_repository.dart';
import 'package:tstore_ecommerce_app/features/chat/controllers/chat_controller.dart';
import 'package:tstore_ecommerce_app/features/chat/screens/chat/chat_screen.dart';
import 'package:tstore_ecommerce_app/features/chat/screens/chat_list_screen/chat_list_screen.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/settings_controller.dart';
import 'package:tstore_ecommerce_app/features/personalization/controllers/user_controller.dart';
import 'package:tstore_ecommerce_app/utils/constants/text_strings.dart';
import 'package:tstore_ecommerce_app/utils/local_storage/storage_utility.dart';
import 'package:tstore_ecommerce_app/utils/theme/theme.dart';
import 'package:tstore_ecommerce_app/features/chat/models/message_model.dart';
import 'package:tstore_ecommerce_app/utils/constants/enums.dart';

MessageModel msg(
  String id,
  String content, {
  String sender = 'me',
  MessageType type = MessageType.text,
  ChatMessageStatus status = ChatMessageStatus.sent,
  int minute = 0,
}) =>
    MessageModel(
      id: id,
      senderId: sender,
      content: content,
      timestamp: DateTime(2026, 9, 9, 10, minute),
      status: status,
      type: type,
    );


/// `onReady()` yönlendirme yapıyor; widget testinde gezinme istemiyoruz.
class _OfflineAuthRepository extends AuthenticationRepository {
  _OfflineAuthRepository({required this.guest});

  final bool guest;

  @override
  bool get isGuestUser => guest;

  @override
  String get getUserID => guest ? '' : 'test-user';

  @override
  void onReady() {}
}

class _OfflineSettingsController extends SettingsController {
  @override
  Future<void> onInit() async {}
}

/// Başlıktaki avatar `UserController`i okuyor; testte sunucuya gitmesin.
class _OfflineUserController extends UserController {
  @override
  void onInit() {}
}

Widget _wrap(Widget child) =>
    GetMaterialApp(theme: TAppTheme.lightTheme, home: child);

void _bootChat({required bool guest}) {
  Get.reset();
  Get.put<AuthenticationRepository>(_OfflineAuthRepository(guest: guest));
  Get.put(ApiChatRepository());
  Get.put(ApiUserRepository());
  Get.put(ApiSettingsRepository());
  Get.put<SettingsController>(_OfflineSettingsController());
  Get.put<UserController>(_OfflineUserController());
}

void main() {
  group('shouldPoll — sayaç boşa dönmemeli', () {
    test('hepsi uygunsa döner', () {
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

    test('panel kapalıysa dönmez', () {
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

    test('uygulama arka plandaysa dönmez', () {
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

    test('misafir kullanıcıda dönmez (hiçbir uca gidilmiyor)', () {
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

    test('sohbet henüz açılmadıysa dönmez', () {
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

  group('mergeMessages — yerel mesaj kaybolmamalı', () {
    test('sunucu geçmişi olduğu gibi alınır', () {
      final server = [msg('s2', 'iki', minute: 2), msg('s1', 'bir', minute: 1)];
      final merged = ChatController.mergeMessages(const [], server);

      expect(merged.map((m) => m.id).toList(), ['s2', 's1']);
    });

    test('sunucuda karşılığı OLMAYAN geçici mesaj korunur', () {
      final local = [
        msg('${ChatController.tempIdPrefix}1', 'yeni', minute: 3),
        msg('s1', 'bir', minute: 1),
      ];
      final server = [msg('s1', 'bir', minute: 1)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.length, 2);
      expect(merged.first.id, '${ChatController.tempIdPrefix}1');
      expect(merged.first.content, 'yeni');
    });

    test('sunucuda karşılığı BULUNAN geçici mesaj düşer (kopya çizilmez)', () {
      final local = [
        msg('${ChatController.tempIdPrefix}1', 'merhaba', minute: 3),
      ];
      final server = [msg('s9', 'merhaba', minute: 3)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.length, 1);
      expect(merged.single.id, 's9');
    });

    test('aynı metni iki kez yazan kullanıcıda ikinci mesaj kaybolmaz', () {
      // İki geçici mesaj, sunucuda henüz TEK karşılık var: her geçici mesaj
      // yalnız BİR sunucu mesajını sahiplenebilir, ikincisi korunmalı.
      final local = [
        msg('${ChatController.tempIdPrefix}2', 'tamam', minute: 4),
        msg('${ChatController.tempIdPrefix}1', 'tamam', minute: 3),
      ];
      final server = [msg('s9', 'tamam', minute: 3)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.length, 2);
      expect(
        merged.where((m) => m.id.startsWith(ChatController.tempIdPrefix)).length,
        1,
      );
      expect(merged.last.id, 's9');
    });

    test('başkasının aynı metinli mesajı bizim geçicimizi sahiplenmez', () {
      final local = [
        msg('${ChatController.tempIdPrefix}1', 'selam', minute: 3),
      ];
      final server = [msg('s9', 'selam', sender: 'support', minute: 3)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.length, 2);
      expect(merged.first.senderId, 'me');
    });

    test('farklı türdeki aynı metin sahiplenilmez', () {
      final local = [
        msg('${ChatController.tempIdPrefix}1', 'foto.png',
            type: MessageType.image, minute: 3),
      ];
      final server = [msg('s9', 'foto.png', minute: 3)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.length, 2);
    });

    test('gitmemiş (failed) yerel mesaj yoklamada silinmez', () {
      final local = [
        msg('${ChatController.tempIdPrefix}1', 'gitmedi',
            status: ChatMessageStatus.failed, minute: 5),
        msg('s1', 'bir', minute: 1),
      ];
      final server = [msg('s1', 'bir', minute: 1)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.first.status, ChatMessageStatus.failed);
      expect(merged.first.content, 'gitmedi');
    });

    test('sunucu sürümü yereldekinin üzerine yazılır (okundu bilgisi güncellenir)', () {
      final local = [msg('s1', 'bir', status: ChatMessageStatus.sent, minute: 1)];
      final server = [msg('s1', 'bir', status: ChatMessageStatus.read, minute: 1)];

      final merged = ChatController.mergeMessages(local, server);

      expect(merged.single.status, ChatMessageStatus.read);
    });

    test('boş sunucu yanıtı yerel geçici mesajı silmez', () {
      final local = [msg('${ChatController.tempIdPrefix}1', 'yeni', minute: 3)];

      final merged = ChatController.mergeMessages(local, const []);

      expect(merged.length, 1);
      expect(merged.single.content, 'yeni');
    });
  });

  group('yoklama aralığı', () {
    test('web ile aynı: 8 saniye', () {
      expect(ChatController.pollInterval, const Duration(seconds: 8));
    });
  });

  group('yoklama sayacı — kapanınca ve arka planda DURUR', () {
    late ChatController controller;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.createTempSync('gs').path,
      );
      await GetStorage.init();
      Get.testMode = true;
      Get.put<AuthenticationRepository>(_OfflineAuthRepository(guest: false));
      Get.put(ApiChatRepository());
    });

    setUp(() {
      controller = Get.put(ChatController());
    });

    tearDown(() {
      controller.stopPolling();
      Get.delete<ChatController>(force: true);
    });

    test('startPolling sayacı başlatır, stopPolling durdurur', () {
      expect(controller.isPolling, isFalse);
      controller.startPolling();
      expect(controller.isPolling, isTrue);
      controller.stopPolling();
      expect(controller.isPolling, isFalse);
    });

    test('ekran kapanınca (closeSupportChat) sayaç durur', () {
      controller.startPolling();
      controller.closeSupportChat();
      expect(controller.isPolling, isFalse);
    });

    test('uygulama arka plana düşünce sayaç durur', () {
      controller.startPolling();
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(controller.isPolling, isFalse);
    });

    test('arka plandan dönüş, panel KAPALIYKEN sayacı yeniden başlatmaz', () {
      // Ekran kapatılmışsa öne dönüş yoklamayı diriltmemeli; yoksa sayaç
      // kullanıcı sohbette değilken boşa döner.
      controller.closeSupportChat();
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.isPolling, isFalse);
    });
  });

  group('girişsiz kullanıcı — duvara çarptırılmaz', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.createTempSync('gs').path,
      );
      await GetStorage.init();
      await TLocalStorage.init('faz10-test');
    });

    tearDown(Get.reset);

    testWidgets('sohbet ekranı misafire GİRİŞ BAĞLANTISI gösterir', (tester) async {
      _bootChat(guest: true);
      await tester.pumpWidget(_wrap(const ChatScreen()));
      await tester.pump();

      expect(find.byType(TEmptyState), findsOneWidget);
      expect(find.text(TTexts.signInRequired), findsOneWidget);
      expect(find.text(TTexts.chatSignInPrompt), findsOneWidget);
      // Yazı çubuğu çizilmemeli: misafir mesaj yazamaz.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('sohbet listesi de misafire giriş kapısı gösterir', (tester) async {
      _bootChat(guest: true);
      await tester.pumpWidget(_wrap(const ChatListScreen()));
      await tester.pump();

      expect(find.byType(TEmptyState), findsOneWidget);
      expect(find.text(TTexts.signInRequired), findsOneWidget);
    });

    testWidgets('misafirde yoklama BAŞLAMAZ (hiçbir uca gidilmiyor)', (tester) async {
      _bootChat(guest: true);
      await tester.pumpWidget(_wrap(const ChatScreen()));
      await tester.pump();

      final controller = Get.find<ChatController>();
      expect(controller.isPolling, isFalse);
      expect(controller.currentChat.value.id, isEmpty);
    });
  });
}
