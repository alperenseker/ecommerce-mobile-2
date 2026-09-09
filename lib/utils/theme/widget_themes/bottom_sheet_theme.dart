import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

/// Alttan açılan levha teması.
///
/// Levha sayfanın üstüne çıkan bir katman olduğu için TASARIM.md §5'e göre
/// gölge hakkı var; köşe yarıçapı `cardRadiusLg` (16) ile hizalandı.
class TBottomSheetTheme {
  TBottomSheetTheme._();

  static BottomSheetThemeData lightBottomSheetTheme = BottomSheetThemeData(
    showDragHandle: true,
    elevation: 0,
    backgroundColor: TColors.white,
    modalBackgroundColor: TColors.white,
    surfaceTintColor: Colors.transparent,
    dragHandleColor: TColors.borderPrimary,
    constraints: const BoxConstraints(minWidth: double.infinity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
    ),
  );

  static BottomSheetThemeData darkBottomSheetTheme = BottomSheetThemeData(
    showDragHandle: true,
    elevation: 0,
    backgroundColor: TColors.darkSurface,
    modalBackgroundColor: TColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    dragHandleColor: TColors.darkBorder,
    constraints: const BoxConstraints(minWidth: double.infinity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
    ),
  );
}
