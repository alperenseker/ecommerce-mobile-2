/// Destek sohbeti ekranı.
///
/// Ekran açılışta sohbeti **bulur ya da açar** (`ChatController
/// .openSupportChat`) ve mesajları yükler; yavaş/başarısız bir ağ çağrısı
/// kullanıcıyı kilitli bir diyalogda tutmasın diye bu iş ekranın kendi
/// (kapatılabilir) yükleniyor durumunun arkasında dönüyor.
///
/// Girişsiz kullanıcı duvara çarptırılmaz: ekran açılır, içinde giriş
/// bağlantısı gösterilir (web `support-widget.js` ile aynı davranış).
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import '../../../../common/widgets/loaders/delayed_loader.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.showBackArrow = true});

  /// Ekran gömülü olarak (bir sekmenin gövdesi gibi) çizilirse geri oku
  /// kapatılabilir: sekme geri gidilecek bir yer değil, ok basılınca kabuğun
  /// rotasını atıyor. Bugün destek her yerden İTİLEREK açılıyor (yan menü,
  /// profil ekranı), o yüzden varsayılan `true`.
  final bool showBackArrow;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController chatController;

  @override
  void initState() {
    super.initState();

    chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Liste ekranından belirli bir sohbetle gelinebilir; gelinmediyse
      // destek sohbeti bulunur ya da açılır.
      final passedChat = Get.arguments is ChatModel
          ? Get.arguments as ChatModel
          : null;
      final passedId = Get.parameters['id'] ?? '';
      if (passedChat != null && passedChat.id.isNotEmpty) {
        chatController.currentChat.value = passedChat;
        chatController.currentChatId.value = passedChat.id;
      } else if (passedId.isNotEmpty) {
        chatController.currentChatId.value = passedId;
      }
      chatController.openSupportChat();
    });
  }

  @override
  void dispose() {
    // 🔴 Ekran kapanınca yoklama DURUR; yoksa sayaç arka planda 8 saniyede bir
    // boşa dönüp pil ve veri harcıyor.
    chatController.closeSupportChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final authRepo = AuthenticationRepository.instance;
    final isGuest = authRepo.isGuestUser || authRepo.getUserID.isEmpty;

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        showBackArrow: widget.showBackArrow,
        showActions: false,
        showSkipButton: false,
        title: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TTexts.supportChat.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                chatController.isOtherTyping.value
                    ? TTexts.typing.tr
                    : TTexts.supportOnline.tr,
                style: Theme.of(context).textTheme.labelLarge!.apply(
                      color: TColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
      body: isGuest
          ? TEmptyState.signInRequired(message: TTexts.chatSignInPrompt.tr)
          : Obx(() {
              if (chatController.isLoading.value) {
                return const Center(
                  child: TDelayedLoader(),
                );
              }

              // Sohbet hiç açılamadıysa (uç hatası) kullanıcıya tekrar deneme
              // yolu bırakılır; boş bir yazı çubuğuyla baş başa kalmasın.
              if (chatController.hasError.value &&
                  chatController.messages.isEmpty) {
                return TEmptyState(
                  icon: Iconsax.message_remove,
                  title: TTexts.chatLoadFailed.tr,
                  message: TTexts.unableFetchMessage.tr,
                  actionText: TTexts.tryAgain.tr,
                  onAction: () => chatController.openSupportChat(),
                );
              }

              final sender = UserController.instance.user.value;
              final messages = chatController.messages
                  .map(_toUiMessage)
                  .toList();

              return Chat(
                messages: messages,
                onSendPressed: (_) {},
                user: types.User(
                  id: sender.id,
                  imageUrl: sender.profilePicture,
                  role: types.Role.user,
                  firstName: sender.firstName,
                  lastName: sender.lastName,
                ),
                theme: DefaultChatTheme(
                  backgroundColor: dark ? TColors.dark : TColors.light,
                  primaryColor: TColors.primary,
                  secondaryColor: dark ? TColors.darkerGrey : TColors.white,
                  receivedMessageBodyTextStyle: TextStyle(
                    color: dark ? TColors.white : TColors.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                  sentMessageBodyTextStyle: const TextStyle(
                    color: TColors.textWhite,
                    fontSize: 14,
                    height: 1.35,
                  ),
                  messageBorderRadius: TSizes.cardRadiusLg,
                  messageInsetsHorizontal: TSizes.md - 2,
                  messageInsetsVertical: 10,
                  inputBackgroundColor: Colors.transparent,
                ),
                emptyState: TEmptyState(
                  icon: Iconsax.messages_2,
                  title: TTexts.supportChat.tr,
                  message: TTexts.chatWelcomeMessage.tr,
                ),
                // Balon kabuğu TASARIM.md'ye göre çiziliyor (paketin
                // turuncu/gri varsayılanı bu dile uymuyor).
                bubbleBuilder: (child, {required message, required nextMessageInGroup}) =>
                    TChatBubble(
                      message: message,
                      nextMessageInGroup: nextMessageInGroup,
                      currentUserId: sender.id,
                      child: child,
                    ),
                customBottomWidget: TChatInputBar(controller: chatController),
                showUserNames: false,
                showUserAvatars: false,
                usePreviewData: true,
                textMessageOptions: const TextMessageOptions(
                  isTextSelectable: true,
                ),
              );
            }),
    );
  }

  /// Kendi mesaj modelimizi paketin beklediği türe çevirir.
  ///
  /// 🔴 Referans, bilinmeyen mesaj türlerinde `UnimplementedError` fırlatıyordu
  /// ve sunucu yeni bir tür gönderince **ekran komple düşüyordu**. Burada
  /// bilinmeyen her tür metne düşürülüyor.
  types.Message _toUiMessage(MessageModel message) {
    final id = message.id.isEmpty ? UniqueKey().toString() : message.id;
    final author = types.User(id: message.senderId);
    final createdAt = message.timestamp.millisecondsSinceEpoch;
    final status = _mapMessageStatus(message.status);

    if (message.type == types.MessageType.image) {
      return types.ImageMessage(
        id: id,
        showStatus: true,
        // Ek yüklenmişse adres `mediaUrl`de, adresle gönderildiyse metinde.
        uri: (message.mediaUrl ?? '').isNotEmpty
            ? message.mediaUrl!
            : message.content,
        name: TTexts.imageMessage.tr,
        size: message.size ?? 0,
        type: types.MessageType.image,
        author: author,
        createdAt: createdAt,
        status: status,
      );
    }

    // Sesli mesaj artık gönderilmiyor; geçmişte kalanlar düz metin olarak
    // gösterilir (referansta da böyle).
    final text = message.type == types.MessageType.audio
        ? TTexts.audioMessage.tr
        : message.content;

    return types.TextMessage(
      id: id,
      showStatus: true,
      text: text,
      type: types.MessageType.text,
      author: author,
      createdAt: createdAt,
      status: status,
    );
  }

  types.Status _mapMessageStatus(ChatMessageStatus messageStatus) {
    switch (messageStatus) {
      case ChatMessageStatus.failed:
        return types.Status.error;
      case ChatMessageStatus.read:
        return types.Status.seen;
      case ChatMessageStatus.delivered:
        return types.Status.delivered;
      case ChatMessageStatus.sent:
        return types.Status.sent;
      case ChatMessageStatus.sending:
        return types.Status.sending;
    }
  }
}
