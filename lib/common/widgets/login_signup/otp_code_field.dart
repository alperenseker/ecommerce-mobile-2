/// Tek kullanımlık kod alanı (OTP / PIN).
///
/// Dört davranış birlikte gerekiyor ve paketten gelen hazır alan bunların
/// **yapıştırmayı** karşılamıyordu (her kutu tek karakterle sınırlı olduğu
/// için panodaki 6 hane ilk kutuda kesiliyordu). Bu yüzden alan burada
/// yazıldı:
///
///   • otomatik ilerleme  • geri silmede önceki kutuya dönme
///   • **yapıştırma** (panodaki kod kutulara dağıtılır)  • hata durumu
///
/// Kutu odaklandığında içerik seçili hâle getiriliyor: böylece "yazma"
/// (uzunluk 1) ile "yapıştırma" (uzunluk > 1) birbirinden kesin ayrılıyor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

class TOtpCodeField extends StatefulWidget {
  const TOtpCodeField({
    super.key,
    this.length = 6,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  final int length;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<TOtpCodeField> createState() => _TOtpCodeFieldState();
}

class _TOtpCodeFieldState extends State<TOtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    for (var i = 0; i < widget.length; i++) {
      _nodes[i].addListener(() => _selectAllOnFocus(i));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// Odaklanınca içeriği seç — yeni karakter mevcut haneyi değiştirsin.
  void _selectAllOnFocus(int index) {
    if (!_nodes[index].hasFocus) return;
    final text = _controllers[index].text;
    _controllers[index].selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Yapıştırma: panodaki haneler bu kutudan başlayarak dağıtılır.
    if (digits.length > 1) {
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final last = (index + digits.length - 1).clamp(0, widget.length - 1);
      _nodes[last].requestFocus();
      _notify();
      return;
    }

    _controllers[index].text = digits;
    if (digits.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    _notify();
  }

  /// Boş kutuda geri silme → önceki kutuya dön ve onu temizle.
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return KeyEventResult.ignored;
    if (_controllers[index].text.isNotEmpty || index == 0) return KeyEventResult.ignored;

    _controllers[index - 1].clear();
    _nodes[index - 1].requestFocus();
    _notify();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Flexible(
          child: Padding(
            padding: EdgeInsets.only(right: index == widget.length - 1 ? 0 : TSizes.sm),
            child: Focus(
              onKeyEvent: (_, event) => _onKey(index, event),
              child: SizedBox(
                height: TSizes.inputFieldHeight,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _nodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  showCursor: false,
                  // maxLength verilmiyor: yapıştırılan kodun tamamı buraya
                  // düşsün ve dağıtılabilsin.
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    errorText: null,
                    enabledBorder: _border(widget.hasError ? TColors.error : TColors.borderPrimary, 1),
                    focusedBorder: _border(widget.hasError ? TColors.error : TColors.primary, 1.5),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  onChanged: (value) => _onChanged(index, value),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}
