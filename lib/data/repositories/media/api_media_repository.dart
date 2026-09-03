/// Görsel/dosya yükleme uçları (`media/...`).
library;

import 'dart:typed_data';
import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../features/personalization/models/image_model.dart';
import '../../../utils/constants/enums.dart';
import '../media/media_repository.dart';

class ApiMediaRepository extends TApiRepositoryController<ImageModel>
    implements MediaRepository {
  static ApiMediaRepository get instance =>
      Get.isRegistered<ApiMediaRepository>()
          ? Get.find<ApiMediaRepository>()
          : Get.put(ApiMediaRepository());

  ApiMediaRepository()
      : super(
          fromJson: (json) => ImageModel.fromJson(json),
          toJson: (item) => {
            'ProductId': item.id,
            'ImageUrl': item.url,
            'folder': item.folder,
            'sizeBytes': item.sizeBytes,
            'filename': item.filename,
            'fullPath': item.fullPath,
            'createdAt': item.createdAt?.toUtc().toIso8601String(),
            'contentType': item.contentType,
            'mediaCategory': item.mediaCategory,
          },
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'media';

  String _productEndpoint(String productId) =>
      '${getEndpoint()}/product/$productId/images';

  T _unwrap<T>(Response response, T Function(dynamic data) mapper) {
    final body = response.data as Map<String, dynamic>;
    if (body['Success'] == true) {
      return mapper(body['Data']);
    }
    throw body['Message'] ?? 'API returned success=false';
  }

  @override
  Future<ImageModel> uploadImageFile({
    required Uint8List fileData,
    required String mimeType,
    required String path,
    required String imageName,
    bool setAsMain = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileData,
          filename: imageName,
          contentType: DioMediaType.parse(mimeType),
        ),
        'setAsMain': setAsMain,
      });

      final response = await dio.post(
        _productEndpoint(path),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _unwrap(response, (data) => ImageModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      // print(e);
      throw handleException(e);
    }
  }

  @override
  Future<ImageModel> uploadImageFileInStorage({
    required Uint8List fileData,
    required String mimeType,
    required String path,
    required String imageName,
  }) =>
      uploadImageFile(
        fileData: fileData,
        mimeType: mimeType,
        path: path,
        imageName: imageName,
      );

  @override
  Future<void> deleteImage(ImageModel image) async {
    try {
      final productId = getId(image);

      final response = await dio.delete(
        _productEndpoint(productId),
        data: {'ImageUrl': image.url},
      );

      _unwrap(response, (data) => data);
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> deleteFileFromStorage(ImageModel image) => deleteImage(image);

  @override
  Future<List<String>> reorderImages({
    required String productId,
    required List<String> orderedImageUrls,
  }) async {
    try {
      final response = await dio.put(
        '${_productEndpoint(productId)}/reorder',
        data: orderedImageUrls,
      );

      return _unwrap(
        response,
        (data) => (data as List).cast<String>(),
      );
    } catch (e) {
      // print(e);
      throw handleException(e);
    }
  }

  Future<void> setMainImage({
    required String productId,
    required String imageUrl,
  }) async {
    try {
      final response = await dio.put(
        '${_productEndpoint(productId)}/set-main',
        data: {'ImageUrl': imageUrl},
      );

      _unwrap(response, (data) => data);
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<List<ImageModel>> fetchImages(
      MediaCategory mediaCategory, int loadCount) async {
    throw UnsupportedError(
      'fetchImages by MediaCategory is not supported by this API. '
      'Use a product-scoped endpoint instead.',
    );
  }

  @override
  Future<List<ImageModel>> loadMoreImages(
    MediaCategory mediaCategory,
    int loadCount,
    DateTime lastFetchedDate,
  ) async {
    throw UnsupportedError(
      'loadMoreImages by MediaCategory is not supported by this API.',
    );
  }

  @override
  Future<List<ImageModel>> fetchAllImages() async {
    throw UnsupportedError(
      'fetchAllImages is not supported by this API. '
      'Fetch images per product instead.',
    );
  }

  @override
  Future<List<ImageModel>> fetchImagesFromDatabase(
          MediaCategory mediaCategory, int loadCount) =>
      fetchImages(mediaCategory, loadCount);

  @override
  Future<List<ImageModel>> loadMoreImagesFromDatabase(
    MediaCategory mediaCategory,
    int loadCount,
    DateTime lastFetchedDate,
  ) =>
      loadMoreImages(mediaCategory, loadCount, lastFetchedDate);
}
