/// Sohbetin yazı çubuğu: metin alanı ve gönder düğmesi.
///
/// `flutter_chat_ui` paketinin kendi girişi kullanılmıyor; TASARIM.md'deki
/// form alanı dili (48px yükseklik, 8px köşe, `borderPrimary` çerçeve, odakta
/// indigo) paketin varsayılanıyla tutmuyordu.
///
/// 🔴 **Resim/dosya gönderme YOK** (kullanıcının 2026-09-09 kararı). Sunucuda
/// `chat/{chatId}/upload` ucu zaten yok (geçerli jetonla bile 404), yani
/// ataç düğmesi hiçbir zaman çalışan bir yola çıkmıyordu. Geçmişte kalmış
/// resim mesajlarının **çizimi** duruyor (bkz. `chat_screen.dart`), yalnız
/// gönderme yolu kaldırıldı.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/chat_controller.dart';

class TChatInputBar extends StatefulWidget {
  const TChatInputBar({super.key, required this.controller});

  final ChatController controller;

  @override
  State<TChatInputBar> createState() => _TChatInputBarState();
}

class _TChatInputBarState extends State<TChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.controller.sendTextMessage(text);
    widget.controller.stopTyping();
    _textController.clear();
    widget.controller.isEditing.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.white,
          // TASARIM.md §5: sayfa akışında gölge yok, ayrım 1px çizgi.
          border: Border(
            top: BorderSide(
              color: dark ? TColors.darkerGrey : TColors.borderSecondary,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          TSizes.sm,
          TSizes.sm,
          TSizes.sm,
          TSizes.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: TTexts.chatInputHint.tr,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  widget.controller.isEditing.value = value.trim().isNotEmpty;
                  value.trim().isEmpty
                      ? widget.controller.stopTyping()
                      : widget.controller.onUserTyping();
                },
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Obx(() {
              final active = widget.controller.isEditing.value &&
                  !widget.controller.isSending.value;
              return SizedBox(
                width: TSizes.buttonHeight,
                height: TSizes.buttonHeight,
                child: Material(
                  color: active ? TColors.primary : TColors.buttonDisabled,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                    onTap: active ? _send : null,
                    child: const Icon(Iconsax.send_1, color: TColors.white),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
