import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// `GetStorage` üzerine kullanıcı başına ayrılmış yerel depo servisi.
///
/// Anahtar adları **değişmez** (KURALLAR §2): cihazda duran eski kayıtlar bu
/// adlarla yazıldı, ad değişirse kullanıcı sepetini/favorisini kaybeder.
class LocalStorageService extends GetxService {
  // Singleton pattern to ensure only one instance is used
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  // Method to get file path from the URL
  Future<File> getFile(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = url.split('/').last;
    return File('${dir.path}/$filename');
  }


  // Generate a unique file name based on the URL or some other unique parameter
  String _generateUniqueFileName(String fileUrl, {String prefix = 'audio'}) {
    const uuid = Uuid();
    return '${prefix}_${uuid.v5(Namespace.url.value, fileUrl)}.m4a'; // Change extension as needed
  }

  /// Download a file from a URL and store it locally
  Future<File> downloadFileWithProgress({
    required String fileUrl,
    bool useTemporaryStorage = false,
    String? customFileName,
    String prefix = 'audio',
    required Function(double) onProgress,
  }) async {
    // Get the correct directory (temporary or persistent)
    final dir = useTemporaryStorage
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();

    // Generate a file name if not provided
    final fileName = customFileName ?? _generateUniqueFileName(fileUrl, prefix: prefix);
    final filePath = '${dir.path}/$fileName';

    // Check if the file already exists
    final file = File(filePath);
    if (file.existsSync()) {
      // If it exists, return the file
      return file;
    }

    try {
      // Download the file using Dio
      Dio dio = Dio();
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (receivedBytes, totalBytes) {
          if (totalBytes != -1) {
            // Update the progress
            final progress = receivedBytes / totalBytes;
            onProgress(progress);
          }
        },
      );

      // Return the file once the download is complete
      return file;
    } catch (e) {
      throw Exception("Failed to download file: $e");
    }
  }

  /// Check if a file already exists locally
  Future<bool> fileExists(String fileUrl, {bool useTemporaryStorage = false, String prefix = 'audio'}) async {
    final dir = useTemporaryStorage ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();

    final fileName = _generateUniqueFileName(fileUrl, prefix: prefix);
    final filePath = '${dir.path}/$fileName';

    return File(filePath).existsSync();
  }

  /// Get a file path for an existing file without downloading it
  Future<String> getFilePath(String fileUrl, {bool useTemporaryStorage = false, String prefix = 'audio'}) async {
    final dir = useTemporaryStorage ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();

    final fileName = _generateUniqueFileName(fileUrl, prefix: prefix);
    final filePath = '${dir.path}/$fileName';

    if (File(filePath).existsSync()) {
      return filePath;
    }

    // If file does not exist locally
    return '';
  }

  /// Clean up (delete) a specific file by URL
  Future<void> deleteFile(String fileUrl, {bool useTemporaryStorage = false, String prefix = 'audio'}) async {
    final dir = useTemporaryStorage ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();

    final fileName = _generateUniqueFileName(fileUrl, prefix: prefix);
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Clean up all files in a directory (temporary or persistent)
  Future<void> cleanUpStorage({bool useTemporaryStorage = false}) async {
    final dir = useTemporaryStorage ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();

    final directory = Directory(dir.path);
    if (directory.existsSync()) {
      directory.listSync().forEach((fileEntity) {
        if (fileEntity is File) {
          fileEntity.deleteSync();
        }
      });
    }
  }

  /// Save waveform data locally
  Future<void> saveWaveformDataLocally(List<double> waveformData, String filePath, {String prefix = 'waveform'}) async {
    try {
      // Get the directory for saving the waveform data
      final dir = await getApplicationDocumentsDirectory();

      // Generate a unique file name for the waveform data, appending `.json`
      final fileName = _generateUniqueFileName(filePath, prefix: prefix);
      final file = File('${dir.path}/$fileName.json');

      // Convert waveform data to a string and save it to the file
      await file.writeAsString(waveformData.toString());

      // print('Waveform data saved successfully to ${file.path}');
    } catch (e) {
      throw Exception('Failed to save waveform data: $e');
    }
  }

  /// Load waveform data from a local file
  Future<List<double>?> loadWaveformData(String filePath, {String prefix = 'waveform'}) async {
    try {
      // Get the directory
      final dir = await getApplicationDocumentsDirectory();

      // Generate the file path for the waveform data
      final fileName = _generateUniqueFileName(filePath, prefix: prefix);
      final file = File('${dir.path}/$fileName.json');

      if (file.existsSync()) {
        // Read the file and convert the saved string back to List<double>
        final dataString = await file.readAsString();
        final List<double> waveformData = dataString.substring(1, dataString.length - 1).split(', ').map(double.parse).toList();

        return waveformData;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load waveform data: $e');
    }
  }

  /// Delete waveform data file
  Future<void> deleteWaveformData(String filePath, {String prefix = 'waveform'}) async {
    try {
      // Get the directory
      final dir = await getApplicationDocumentsDirectory();

      // Generate the file path
      final fileName = _generateUniqueFileName(filePath, prefix: prefix);
      final file = File('${dir.path}/$fileName.json');

      if (file.existsSync()) {
        await file.delete();
        // print('Waveform data file deleted successfully.');
      }
    } catch (e) {
      throw Exception('Failed to delete waveform data: $e');
    }
  }
}
