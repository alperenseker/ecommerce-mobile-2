/// Sohbetin alt yazı çubuğu: ek düğmesi + metin alanı + gönder düğmesi.
///
/// TASARIM.md §6: form alanı 8px köşeli, `borderPrimary` çerçeveli, odakta
/// indigo; gönder düğmesi dolu indigo.
///
/// ⚠️ **Dosya seçici yok.** Projede `image_picker`/`file_picker` bağımlılığı
/// yok ve KURALLAR §6 yeni paket eklemeyi yasaklıyor (FAZ 08'in iade
/// görselleriyle aynı durum). Ek, görsel **adresi** olarak gönderiliyor;
/// yükleme ucunu kullanan `ChatController.sendAttachment` hazır — paket izni
/// verilirse yalnız bu dosyadaki [_pickAttachment] değişir.
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
  const TChatInputBar({super.key});

  @override
  State<TChatInputBar> createState() => _TChatInputBarState();
}

class _TChatInputBarState extends State<TChatInputBar> {
  final _textController = TextEditingController();
  final _controller = ChatController.instance;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _controller.isEditing.value = false;
    _controller.sendTextMessage(text);
    _controller.stopTyping();
  }

  /// Görsel adresi soran küçük diyalog. Dosya seçici gelene kadarki yol.
  Future<void> _pickAttachment() async {
    final urlController = TextEditingController();
    final url = await Get.dialog<String>(
      AlertDialog(
        title: Text(TTexts.attachImage.tr),
        content: TextField(
          controller: urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: TTexts.attachImageHint.tr),
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(TTexts.cancel.tr)),
          TextButton(
            onPressed: () => Get.back(result: urlController.text),
            child: Text(TTexts.send.tr),
          ),
        ],
      ),
    );
    urlController.dispose();

    final address = (url ?? '').trim();
    if (address.isEmpty) return;
    await _controller.sendImageMessage(url: address);
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final barColor = dark ? TColors.darkSurface : TColors.white;
    final fieldColor = dark ? TColors.darkBackground : TColors.white;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: barColor,
          // Ayrım çizgiyle (TASARIM.md §5) — yazı çubuğu listeden ayrılsın.
          border: Border(
            top: BorderSide(
              color: dark ? TColors.darkBorder : TColors.borderSecondary,
              width: TSizes.dividerHeight,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(TSizes.sm, TSizes.sm, TSizes.sm, TSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Obx(
              () => IconButton(
                onPressed: _controller.isUploading.value ? null : _pickAttachment,
                tooltip: TTexts.attachImage.tr,
                icon: _controller.isUploading.value
                    ? const SizedBox(
                        width: TSizes.iconSm,
                        height: TSizes.iconSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.paperclip, color: TColors.darkGrey),
              ),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: TSizes.buttonHeight),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                  border: Border.all(
                    color: dark ? TColors.darkBorder : TColors.borderPrimary,
                    width: TSizes.dividerHeight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    // Genel form temasının dolgulu kutusu burada iki çerçeve
                    // gibi görünüyordu; kapatıldı.
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    hintText: TTexts.chatInputHint.tr,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _controller.isEditing.value = value.trim().isNotEmpty;
                    value.trim().isEmpty
                        ? _controller.stopTyping()
                        : _controller.onUserTyping();
                  },
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Obx(
              () => GestureDetector(
                onTap: _controller.isEditing.value ? _send : null,
                child: Container(
                  width: TSizes.buttonHeight,
                  height: TSizes.buttonHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Boş alanda düğme sönük: dokunmanın bir işe yaramadığı
                    // belli olsun.
                    color: _controller.isEditing.value
                        ? TColors.primary
                        : TColors.buttonDisabled,
                    borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                  ),
                  child: Icon(
                    Iconsax.send_1,
                    size: TSizes.iconMd - 4,
                    color: _controller.isEditing.value
                        ? TColors.white
                        : TColors.darkGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
