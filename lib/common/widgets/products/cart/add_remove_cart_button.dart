/// Miktar seçici: − · yazılabilir sayı · +
///
/// Sayı alanı **elle yazılabilir**; 500 adet isteyen bayi artı düğmesine
/// 500 kez basmasın diye. Klavye açıkken dışarıdan gelen güncellemeler
/// kullanıcının yazdığını EZMEZ (bkz. [didUpdateWidget]).
///
/// TASARIM.md §6: yuvarlak ikon düğmeler, 8px köşeli sayı kutusu.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../icons/t_circular_icon.dart';

class TProductQuantityWithAddRemoveButton extends StatefulWidget {
  const TProductQuantityWithAddRemoveButton({
    super.key,
    required this.add,
    this.width = 32,
    this.height = 32,
    this.iconSize = 14,
    this.dense = false,
    required this.remove,
    required this.quantity,
    this.onQuantitySet,
    this.addBackgroundColor = TColors.primary,
    this.removeBackgroundColor = TColors.primary,
    this.addForegroundColor = TColors.white,
    this.removeForegroundColor = TColors.white,
  });

  final VoidCallback? add, remove;
  final int quantity;
  final double width, height;
  final double? iconSize;

  /// Ürün kartı gibi dar yerler için: sayı kutusu biraz daha dar ve dolgusu
  /// kısa olur, böylece adımlayıcı düğme yüksekliğine sığar.
  final bool dense;

  final Color addBackgroundColor, removeBackgroundColor;
  final Color addForegroundColor, removeForegroundColor;

  /// Kullanıcı sayıyı elle yazdığında çağrılır.
  final void Function(int newQuantity)? onQuantitySet;

  @override
  State<TProductQuantityWithAddRemoveButton> createState() =>
      _TProductQuantityWithAddRemoveButtonState();
}

class _TProductQuantityWithAddRemoveButtonState extends State<TProductQuantityWithAddRemoveButton> {
  late final TextEditingController _controller = TextEditingController(text: widget.quantity.toString());
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);

  @override
  void didUpdateWidget(covariant TProductQuantityWithAddRemoveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan gelen +/- değişimini yansıt, ama kullanıcı yazarken karışma.
    if (!_focusNode.hasFocus && oldWidget.quantity != widget.quantity) {
      _controller.text = widget.quantity.toString();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Odakta tüm değeri seç: "0" üstüne "1" yazınca "01" değil "1" olsun.
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    } else {
      // Odak çıkınca normalleştir: boş/geçersiz giriş temiz bir sayıya oturur.
      final parsed = int.tryParse(_controller.text);
      final value = (parsed != null && parsed >= 0) ? parsed : 0;
      widget.onQuantitySet?.call(value);
      _controller.text = value.toString();
    }
  }

  /// Yazarken canlı güncelle: sayısal klavyede "bitti" tuşu yok, düğmenin
  /// hemen açılması gerekiyor. Boş alan 0 sayılır.
  void _onChanged(String value) {
    if (value.isEmpty) {
      widget.onQuantitySet?.call(0);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) widget.onQuantitySet?.call(parsed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TCircularIcon(
          icon: Iconsax.minus,
          onPressed: widget.remove,
          width: widget.width,
          height: widget.height,
          size: widget.iconSize,
          color: widget.removeForegroundColor,
          backgroundColor: widget.removeBackgroundColor,
        ),
        const SizedBox(width: TSizes.xs),
        Container(
          width: widget.dense ? 46 : 52,
          decoration: BoxDecoration(
            color: dark ? TColors.darkSurface : TColors.lightContainer,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.onQuantitySet != null,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: widget.dense
                ? Theme.of(context).textTheme.bodyLarge
                : Theme.of(context).textTheme.titleMedium,
            onChanged: _onChanged,
            onSubmitted: (_) => _focusNode.unfocus(),
            // Alan dışına dokunmak (boşluk, +/-, "sepete ekle") önce klavyeyi
            // kapatsın; yoksa +/- düğmeleri sayıyı güncelleyemiyor.
            onTapOutside: (_) {
              if (_focusNode.hasFocus) _focusNode.unfocus();
            },
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: widget.dense ? TSizes.xs + 2 : TSizes.sm + 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: TSizes.xs),
        TCircularIcon(
          icon: Iconsax.add,
          onPressed: widget.add,
          width: widget.width,
          height: widget.height,
          size: widget.iconSize,
          color: widget.addForegroundColor,
          backgroundColor: widget.addBackgroundColor,
        ),
      ],
    );
  }
}
