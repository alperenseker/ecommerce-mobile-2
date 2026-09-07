/// Destek sohbeti ekranı.
///
/// 🔴 Sohbet **kullanıcı başına tektir**: ekran açılırken
/// [ChatController.openSupportChat] var olan `support` sohbetini arar, yalnız
/// hiç yoksa yeni açar.
///
/// 🔴 Yeni mesajlar **yoklama** ile gelir (SignalR yok) ve yoklama YALNIZ bu
/// ekran açıkken çalışır: [dispose] içinde `closeSupportChat()` çağrılıyor,
/// uygulama arka plana düşünce de controller sayacı durduruyor.
///
/// 🔴 Girişsiz kullanıcı **duvara çarpmaz**: ekran açılır ve içinde giriş
/// bağlantısı gösterilir (web `support-widget.js` ile aynı davranış).
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/images/t_circular_image.dart';
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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
      // Liste ekranından ya da derin bağlantıdan gelen sohbet.
      final passedChat = Get.arguments is ChatModel ? Get.arguments as ChatModel : null;
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
    // Ekran kapanınca yoklama durur — kabul kriteri.
    chatController.closeSupportChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isGuest = AuthenticationRepository.instance.isGuestUser;

    return Scaffold(
      backgroundColor: dark ? TColors.darkBackground : TColors.light,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const _SupportChatTitle(),
      ),
      body: isGuest ? const _GuestGate() : _buildBody(context, dark),
    );
  }

  Widget _buildBody(BuildContext context, bool dark) {
    return Obx(() {
      // İlk yükleme: liste henüz boşken çember, mesaj varken liste durur
      // (yoklama turu ekranı boşaltmasın).
      if (chatController.isLoading.value && chatController.messages.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: TColors.primary));
      }

      if (chatController.hasError.value && chatController.messages.isEmpty) {
        return TEmptyState(
          icon: Iconsax.message_remove,
          title: TTexts.chatLoadFailed.tr,
          message: TTexts.unableFetchMessage.tr,
          actionText: TTexts.tryAgain.tr,
          onAction: chatController.openSupportChat,
        );
      }

      final sender = UserController.instance.user.value;
      final messages = chatController.messages.map(_toUiMessage).toList();

      return Chat(
        messages: messages,
        user: types.User(
          id: sender.id,
          imageUrl: sender.profilePicture,
          role: types.Role.user,
          firstName: sender.firstName,
          lastName: sender.lastName,
        ),
        // Gönderme işi alt çubuğun kendisinde; paketin varsayılan girişi
        // kullanılmıyor.
        onSendPressed: (_) {},
        customBottomWidget: const TChatInputBar(),
        emptyState: const _WelcomeBubble(),
        bubbleBuilder: (child, {required message, required nextMessageInGroup}) =>
            TChatBubble(
          isMine: message.author.id == sender.id,
          nextMessageInGroup: nextMessageInGroup,
          child: child,
        ),
        theme: DefaultChatTheme(
          backgroundColor: dark ? TColors.darkBackground : TColors.light,
          primaryColor: TColors.primary,
          secondaryColor: dark ? TColors.darkSurface : TColors.white,
          receivedMessageBodyTextStyle: TextStyle(
            color: dark ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeSm,
            height: 1.35,
          ),
          sentMessageBodyTextStyle: const TextStyle(
            color: TColors.white,
            fontSize: TSizes.fontSizeSm,
            height: 1.35,
          ),
          messageBorderRadius: TSizes.cardRadiusLg,
          messageInsetsHorizontal: TSizes.md - 2,
          messageInsetsVertical: 10,
          inputBackgroundColor: Colors.transparent,
          dateDividerTextStyle: const TextStyle(
            color: TColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        showUserNames: false,
        showUserAvatars: true,
        usePreviewData: true,
        textMessageOptions: const TextMessageOptions(isTextSelectable: true),
      );
    });
  }

  /// Uygulama modelini paketin mesaj tipine çevirir.
  ///
  /// Sesli mesaj **artık üretilmiyor**; geçmişte kalmış bir kayıt gelirse
  /// düz bir yer tutucu metin olarak çizilir (referansta da böyle).
  types.Message _toUiMessage(MessageModel message) {
    final id = message.id.isEmpty
        ? 'msg_${message.timestamp.microsecondsSinceEpoch}'
        : message.id;
    final author = types.User(id: message.senderId);
    final createdAt = message.timestamp.millisecondsSinceEpoch;
    final status = _mapMessageStatus(message.status);

    switch (message.type) {
      case types.MessageType.image:
        return types.ImageMessage(
          id: id,
          showStatus: true,
          // Adres `mediaUrl`de; eski kayıtlarda içerik alanına yazılmıştı.
          uri: (message.mediaUrl ?? '').isNotEmpty ? message.mediaUrl! : message.content,
          name: message.content.isEmpty ? TTexts.imageMessage.tr : message.content,
          size: message.size ?? 0,
          author: author,
          createdAt: createdAt,
          status: status,
        );
      case types.MessageType.audio:
        return types.TextMessage(
          id: id,
          showStatus: true,
          text: TTexts.audioMessage.tr,
          author: author,
          createdAt: createdAt,
          status: status,
        );
      case types.MessageType.text:
      case types.MessageType.custom:
      case types.MessageType.file:
      case types.MessageType.system:
      case types.MessageType.unsupported:
      case types.MessageType.video:
        // Bilinmeyen tür de metin olarak çizilir: referanstaki
        // `UnimplementedError` sunucu yeni bir tür gönderdiğinde ekranı
        // komple düşürüyordu.
        return types.TextMessage(
          id: id,
          showStatus: true,
          text: message.content,
          author: author,
          createdAt: createdAt,
          status: status,
        );
    }
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

/// Başlıktaki destek kimliği: avatar + ad + "çevrimiçi" / "yazıyor".
class _SupportChatTitle extends StatelessWidget {
  const _SupportChatTitle();

  @override
  Widget build(BuildContext context) {
    final controller = ChatController.instance;

    return Obx(() {
      final admin = controller.admin.value;
      final name = admin.fullName.trim().isEmpty
          ? TTexts.supportTeam.tr
          : admin.fullName.trim();

      return Row(
        children: [
          TCircularImage(
            image: admin.profilePicture,
            isNetworkImage: admin.profilePicture.isNotEmpty,
            placeholderIcon: Iconsax.headphone,
            placeholderIconColor: TColors.white,
            width: 34,
            height: 34,
            padding: 0,
            backgroundColor:
                admin.profilePicture.isNotEmpty ? TColors.white : TColors.primary,
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    if (!controller.isOtherTyping.value) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: TColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: TSizes.xs),
                    ],
                    Text(
                      controller.isOtherTyping.value
                          ? '${TTexts.typing.tr}...'
                          : TTexts.supportOnline.tr,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: TColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Hiç mesaj yokken gösterilen karşılama balonu (web `paint()` ile aynı).
class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: TSizes.md - 4,
          ),
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: Border.all(
              color: dark ? TColors.darkBorder : TColors.borderSecondary,
              width: TSizes.dividerHeight,
            ),
          ),
          child: Text(
            TTexts.chatWelcomeMessage.tr,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Girişsiz kullanıcı kapısı: ekran açılır, içinde giriş bağlantısı vardır.
class _GuestGate extends StatelessWidget {
  const _GuestGate();

  @override
  Widget build(BuildContext context) =>
      TEmptyState.signInRequired(message: TTexts.chatSignInPrompt.tr);
}
