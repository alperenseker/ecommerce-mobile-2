/// Çocuğunu kavisli kenarla kırpan sarmalayıcı.
///
/// Bkz. [TCustomCurvedEdges]; TASARIM.md §7 uyarınca ana sayfa başlığında
/// artık kullanılmıyor, referansla eşitlik için korunuyor.
library;

import 'package:flutter/material.dart';

import 'curved_edges.dart';

/// Widget that adds curved edges to its child using a custom clipper.
class TCurvedEdgesWidget extends StatelessWidget {
  /// Create a widget with curved edges.
  const TCurvedEdgesWidget({
    super.key,
    required this.child,
  });

  /// The child widget to be wrapped with curved edges.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TCustomCurvedEdges(),
      child: child,
    );
  }
}
