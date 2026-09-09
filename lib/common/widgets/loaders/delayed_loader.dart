/// Gecikmeli yükleniyor göstergesi.
///
/// 🔴 Ekranların ortasındaki dönen halka, sayfa açılırken **bir anlığına
/// çakıp kayboluyordu**: veri çoğu zaman 100-200 ms içinde geliyor ve
/// kullanıcı yeni sayfa yerine önce mavi bir daire görüyor. Bu widget ilk
/// [delay] boyunca HİÇBİR ŞEY çizmez; iş o süre içinde biterse gösterge hiç
/// görünmez, gerçekten uzun süren yüklemelerde ise normal şekilde belirir.
///
/// Yalnız tam ekran/blok yüklemeleri için; düğme içindeki küçük halkalar
/// zaten kullanıcının kendi dokunuşunun karşılığı, onlar anında görünmeli.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class TDelayedLoader extends StatefulWidget {
  const TDelayedLoader({
    super.key,
    this.delay = const Duration(milliseconds: 350),
    this.strokeWidth = 4.0,
  });

  /// Bu süre dolmadan gösterge çizilmez.
  final Duration delay;
  final double strokeWidth;

  @override
  State<TDelayedLoader> createState() => _TDelayedLoaderState();
}

class _TDelayedLoaderState extends State<TDelayedLoader> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Center(
      child: CircularProgressIndicator(color: TColors.primary, strokeWidth: widget.strokeWidth),
    );
  }
}
