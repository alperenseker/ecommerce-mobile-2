import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

/// 6/4 haneli kod alanı (kayıt OTP'si ve PIN ekranları).
///
/// 🔴 `otp_text_field` paketinin `OTPTextField`'ı yerine yazıldı: o bileşen her
/// kutuyu ayrı bir `TextField` yaptığı için **yapıştırmayı** desteklemiyor
/// (panodaki 6 hane tek kutuya düşüp kırpılıyor), istem ise yapıştırmayı şart
/// koşuyor. Burada tersi kurgu var: kutular yalnız **çizim**, girdiyi arkada
/// duran tek bir saydam `TextField` alıyor. Böylece otomatik ilerleme, geri
/// silme, yapıştırma ve klavye davranışı Flutter'ın kendi metin alanından
/// bedavaya geliyor.
///
/// Paket `pubspec.yaml`'da duruyor (KURALLAR §2: paket listesi değişmez) ama
/// artık hiçbir yerden import edilmiyor.
class TOtpCodeField extends StatefulWidget {
  const TOtpCodeField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.autofocus = true,
    this.obscure = false,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool autofocus;

  /// PIN ekranlarında hane gizlenebilsin diye; OTP'de kod açık gösteriliyor.
  final bool obscure;

  @override
  State<TOtpCodeField> createState() => _TOtpCodeFieldState();
}

class _TOtpCodeFieldState extends State<TOtpCodeField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
      // Kod tamamlandığında klavye kapanıyor: alan altındaki "doğrula"
      // düğmesi çoğu telefonda klavyenin arkasında kalıyordu.
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            final filled = index < code.length;
            // İmleç, girilmiş son hanenin bir sonrasında durur.
            final isCurrent = _focusNode.hasFocus && index == code.length;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == widget.length - 1 ? 0 : TSizes.sm),
                child: _Box(
                  character: filled ? (widget.obscure ? '•' : code[index]) : '',
                  focused: isCurrent,
                  hasError: widget.hasError,
                ),
              ),
            );
          }),
        ),

        /// Girdiyi alan saydam alan. Kutuların **üstünde** duruyor ki dokunma,
        /// uzun basıp "Yapıştır" ve seçim tutamakları buraya gelsin.
        Positioned.fill(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            showCursor: false,
            // Metin görünmez: haneleri arkadaki kutular çiziyor.
            style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 0.1),
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }
}

/// Tek hane kutusu — TASARIM.md §6'nın form alanı diliyle: 8px köşe,
/// `borderPrimary` çerçeve, odakta indigo.
class _Box extends StatelessWidget {
  const _Box({required this.character, required this.focused, required this.hasError});

  final String character;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final Color borderColor = hasError
        ? TColors.error
        : focused
            ? TColors.primary
            : (dark ? TColors.darkBorder : TColors.borderPrimary);

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? TColors.darkSurface : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
      ),
      child: Text(
        character,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
