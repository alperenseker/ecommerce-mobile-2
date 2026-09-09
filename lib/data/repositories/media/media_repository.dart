import 'dart:typed_data';

import '../../../features/personalization/models/image_model.dart';
import '../../../utils/constants/enums.dart';

/// Medya repository sözleşmesi.
abstract class MediaRepository {
  Future<ImageModel> uploadImageFile({
    required Uint8List fileData,
    required String mimeType,
    required String path,
    required String imageName,
    bool setAsMain,
  });

  Future<ImageModel> uploadImageFileInStorage({
    required Uint8List fileData,
    required String mimeType,
    required String path,
    required String imageName,
  });

  Future<void> deleteImage(ImageModel image);
  Future<void> deleteFileFromStorage(ImageModel image);

  Future<List<String>> reorderImages({
    required String productId,
    required List<String> orderedImageUrls,
  });

  Future<List<ImageModel>> fetchImages(MediaCategory mediaCategory, int loadCount);
  Future<List<ImageModel>> loadMoreImages(MediaCategory mediaCategory, int loadCount, DateTime lastFetchedDate);
  Future<List<ImageModel>> fetchAllImages();
  Future<List<ImageModel>> fetchImagesFromDatabase(MediaCategory mediaCategory, int loadCount);
  Future<List<ImageModel>> loadMoreImagesFromDatabase(MediaCategory mediaCategory, int loadCount, DateTime lastFetchedDate);
}
