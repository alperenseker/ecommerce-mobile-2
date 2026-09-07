/// Sohbet listesi.
///
/// Destek sohbeti kullanıcı başına tek olduğu için liste pratikte 0 ya da 1
/// satırdır; ekran yine de referanstaki gibi duruyor (KURALLAR §4) ve
/// ileride başka sohbet türü eklenirse hazır.
///
/// ⚠️ Referanstaki "artı" düğmesi **kaldırılmadı ama kapısı değişti**: sohbet
/// yoksa düğme yeni sohbet açmıyor, doğrudan sohbet ekranını açıyor —
/// bul-ya-da-aç kuralı tek yerde (`ChatController.ensureSupportChat`) durmalı,
/// yoksa iki ayrı yerden iki sohbet açılıyordu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../common/widgets/loaders/t_empty_state.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../../models/participant_model.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    final isGuest = AuthenticationRepository.instance.isGuestUser;

    if (!isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatController.fetchSupportChat();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(TTexts.chats.tr),
        actions: [
          IconButton(
            tooltip: TTexts.liveSupport.tr,
            icon: const Icon(Iconsax.messages_2),
            onPressed: () => Get.toNamed(TRoutes.chat),
          ),
        ],
      ),
      body: isGuest
          ? TEmptyState.signInRequired(message: TTexts.chatSignInPrompt.tr)
          : Obx(() {
              if (chatController.isLoading.value && chatController.chats.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: TColors.primary),
                );
              }

              if (chatController.chats.isEmpty) {
                return TEmptyState(
                  icon: Iconsax.message_text,
                  title: TTexts.noChatsYet.tr,
                  message: TTexts.chatSubTitle.tr,
                  actionText: TTexts.liveSupport.tr,
                  onAction: () => Get.toNamed(TRoutes.chat),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                itemCount: chatController.chats.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) =>
                    _ChatTile(chat: chatController.chats[index]),
              );
            }),
    );
  }
}

/// Listenin tek satırı: karşı tarafın avatarı, adı ve son mesaj özeti.
class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});

  final ChatModel chat;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final myId = UserController.instance.user.value.id;

    final other = chat.participants
            .where((user) => user.userId != myId)
            .firstOrNull ??
        ParticipantModel(userId: '', name: '', profileImageURL: '');

    // İsim boş gelebilir (sunucu destek tarafını katılımcı olarak yazmıyor);
    // `name[0]` referansta boş isimde patlıyordu.
    final title = other.name.trim().isNotEmpty
        ? other.name.trim()
        : (chat.chatType == ChatType.support
            ? TTexts.supportTeam.tr
            : TTexts.chat.tr);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TSizes.defaultSpace,
        vertical: TSizes.xs,
      ),
      leading: TCircularImage(
        image: other.profileImageURL,
        isNetworkImage: other.profileImageURL.isNotEmpty,
        placeholderIcon: Iconsax.headphone,
        placeholderIconColor: TColors.white,
        width: 44,
        height: 44,
        padding: 0,
        backgroundColor:
            other.profileImageURL.isNotEmpty ? TColors.white : TColors.primary,
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        _summary(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: dark ? TColors.darkGrey : TColors.textSecondary),
      ),
      trailing: Text(
        TimeOfDay.fromDateTime(chat.lastMessageTime).format(context),
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: TColors.textSecondary),
      ),
      onTap: () => Get.toNamed(TRoutes.chat, parameters: {'id': chat.id}),
    );
  }

  String _summary() {
    switch (chat.lastMessageType) {
      case MessageType.image:
        return TTexts.imageMessage.tr;
      case MessageType.audio:
        return TTexts.audioMessage.tr;
      default:
        return chat.lastMessage.isNotEmpty
            ? chat.lastMessage
            : TTexts.noRecentMessage.tr;
    }
  }
}
