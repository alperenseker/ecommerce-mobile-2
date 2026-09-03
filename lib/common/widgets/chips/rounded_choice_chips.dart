/// Radyo düğmesi gibi davranan seçim çipi.
///
/// Metin bir renk adıysa (`THelperFunctions.getColor`) çip yazı yerine renk
/// dairesi gösterir — öznitelik seçiminde kullanılıyor.
library;

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/circular_container.dart';

/// A customized choice chip that can act like a radio button.
class TChoiceChip extends StatelessWidget {
  /// Create a chip that acts like a radio button.
  ///
  /// Parameters:
  ///   - text: The label text for the chip.
  ///   - selected: Whether the chip is currently selected.
  ///   - onSelected: Callback function when the chip is selected.
  const TChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    this.onSelected,
  });

  final String text;
  final bool selected;
  final void Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    final color = THelperFunctions.getColor(text);
    return Theme(
      // Saydam tuval rengi: çipin kendi zemini görünsün.
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ChoiceChip(
        avatar: color != null ? TCircularContainer(width: 50, height: 50, backgroundColor: color) : null,
        selected: selected,
        onSelected: onSelected,
        backgroundColor: color,
        labelStyle: TextStyle(color: selected ? TColors.white : null),
        shape: color != null ? const CircleBorder() : null,
        label: color == null ? Text(text) : const SizedBox(),
        padding: color != null ? const EdgeInsets.all(0) : null,
        labelPadding: color != null ? const EdgeInsets.all(0) : null,
      ),
    );
  }
}
