/// Sohbet listesi.
///
/// 🔴 Referanstaki "artı" düğmesi doğrudan `createChat` çağırıyordu; her
/// dokunuşta yeni bir destek sohbeti açılıyordu. Burada aynı düğme
/// `ChatController.ensureSupportChat()` kapısına gidiyor — var olan sohbet
/// bulunursa o açılır, yoksa **bir tane** açılır.
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
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
import '../../../../common/widgets/loaders/delayed_loader.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    final authRepo = AuthenticationRepository.instance;
    final isGuest = authRepo.isGuestUser || authRepo.getUserID.isEmpty;

    if (!isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatController.fetchSupportChat();
      });
    }

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(
          TTexts.chats.tr,
          style: Theme.of(context).textTheme.headlineSmall,
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

              if (chatController.chats.isEmpty) {
                return TEmptyState(
                  icon: Iconsax.messages_2,
                  title: TTexts.noChatsYet.tr,
                  message: TTexts.chatWelcomeMessage.tr,
                  actionText: TTexts.liveSupport.tr,
                  // Sohbeti burada AÇMIYORUZ: tek kapı sohbet ekranındaki
                  // ensureSupportChat çağrısıdır.
                  onAction: () => Get.toNamed(TRoutes.chat),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                itemCount: chatController.chats.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                itemBuilder: (context, index) {
                  final chat = chatController.chats[index];
                  return _ChatListTile(chat: chat);
                },
              );
            }),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({required this.chat});

  final ChatModel chat;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final myId = UserController.instance.user.value.id;

    // Sunucu destek tarafını katılımcı olarak yazmayabiliyor; boş katılımcıya
    // düşülürse `name[0]` okuması patlıyordu (referanstaki çökme yolu).
    final other = chat.participants
            .where((user) => user.userId != myId)
            .firstOrNull ??
        ParticipantModel(userId: '', name: '', profileImageURL: '');

    final title = other.name.isNotEmpty
        ? other.name
        : (chat.chatType == ChatType.support
            ? TTexts.supportTeam.tr
            : TTexts.chats.tr);

    final subtitle = switch (chat.lastMessageType) {
      MessageType.text => chat.lastMessage.isNotEmpty
          ? chat.lastMessage
          : TTexts.noRecentMessage.tr,
      MessageType.audio => TTexts.audioMessage.tr,
      MessageType.image => TTexts.imageMessage.tr,
      _ => TTexts.noRecentMessage.tr,
    };

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: dark ? TColors.darkerGrey : TColors.borderSecondary,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.sm / 2,
        ),
        leading: other.profileImageURL.isNotEmpty
            ? TCircularImage(
                image: other.profileImageURL,
                isNetworkImage: true,
                padding: 0,
                width: 40,
                height: 40,
              )
            : CircleAvatar(
                backgroundColor: TColors.primaryBackground,
                child: Text(
                  title.isNotEmpty ? title.characters.first : '?',
                  style: Theme.of(context).textTheme.titleMedium!.apply(
                        color: TColors.primary,
                      ),
                ),
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium!.apply(
                color: TColors.textSecondary,
              ),
        ),
        trailing: Text(
          TimeOfDay.fromDateTime(chat.lastMessageTime).format(context),
          style: Theme.of(context).textTheme.labelLarge!.apply(
                color: TColors.textSecondary,
              ),
        ),
        onTap: () => Get.toNamed(TRoutes.chat, parameters: {'id': chat.id}),
      ),
    );
  }
}
