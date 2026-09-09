import 'dart:typed_data';

import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../utils/formatters/formatter.dart';

/// Yüklenen görselin modeli (url, ad, boyut, yükleyen).
class ImageModel {
  String id;
  final String url;
  final String folder;
  final int? sizeBytes;
  String mediaCategory;
  final String filename;
  final String? fullPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contentType;

  // Not Mapped
  RxBool isSelected = false.obs;
  final Uint8List? localImageToDisplay;

  /// Constructor for ImageModel.
  ImageModel({
    this.id = '',
    required this.url,
    required this.folder,
    required this.filename,
    this.sizeBytes,
    this.fullPath,
    this.createdAt,
    this.updatedAt,
    this.contentType,
    this.localImageToDisplay,
    this.mediaCategory = '',
  });

  /// Static function to create an empty user model.
  static ImageModel empty() => ImageModel(url: '', folder: '', filename: '');

  String get createdAtFormatted => TFormatter.formatDate(createdAt);

  String get updatedAtFormatted => TFormatter.formatDate(updatedAt);

  /// Convert to Json to Store in DB
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'folder': folder,
      'sizeBytes': sizeBytes,
      'filename': filename,
      'fullPath': fullPath,
      'createdAt': createdAt?.toUtc(),
      'contentType': contentType,
      'mediaCategory': mediaCategory,
    };
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      url: json['url'] ?? json['imageUrl'] ?? json['ImageUrl'] ?? '',
      folder: json['folder'] ?? '',
      filename: json['filename'] ?? '',
      sizeBytes: json['sizeBytes'] as int?,
      fullPath: json['fullPath'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      contentType: json['contentType'],
      mediaCategory: json['mediaCategory'] ?? '',
    );
  }
}
