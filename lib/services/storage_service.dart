import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:wifi_file_transfer/models/file_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class StorageService {
  static late Directory _appDocumentsDirectory;
  static late Directory _appTempDirectory;
  static late Directory _downloadDirectory;

  // Initialize storage directories
  static Future<void> initialize() async {
    try {
      _appDocumentsDirectory = await getApplicationDocumentsDirectory();
      _appTempDirectory = await getTemporaryDirectory();

      // Create download directory
      _downloadDirectory = Directory('${_appDocumentsDirectory.path}/${AppConstants.defaultDownloadFolder}');
      if (!await _downloadDirectory.exists()) {
        await _downloadDirectory.create(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to initialize storage: $e');
    }
  }

  // Get the download directory
  static Directory get downloadDirectory => _downloadDirectory;

  // Get app documents directory
  static Directory get documentsDirectory => _appDocumentsDirectory;

  // Get temp directory
  static Directory get tempDirectory => _appTempDirectory;

  // Save file to download directory
  static Future<FileModel> saveFile(String sourcePath, String fileName) async {
    try {
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // Generate unique filename if it already exists
      final uniqueFileName = await _generateUniqueFileName(fileName);
      final destinationPath = '${_downloadDirectory.path}/$uniqueFileName';

      // Copy file to download directory
      final destinationFile = await sourceFile.copy(destinationPath);

      // Create file model
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      return FileModel.fromPath(destinationPath, fileId);
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  // Create temp file for transfer
  static Future<File> createTempFile(String fileName) async {
    try {
      final tempPath = '${_tempDirectory.path}/$fileName';
      final tempFile = File(tempPath);
      return tempFile;
    } catch (e) {
      throw Exception('Failed to create temp file: $e');
    }
  }

  // Delete file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Clean up temp files
  static Future<void> cleanupTempFiles() async {
    try {
      if (await _tempDirectory.exists()) {
        await for (final entity in _tempDirectory.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // Get available storage space
  static Future<int> getAvailableStorageSpace() async {
    try {
      final directory = _downloadDirectory.parent;
      final stat = await directory.stat();
      // This is a simplified check - actual implementation would be platform-specific
      return 1024 * 1024 * 1024; // Return 1GB as placeholder
    } catch (e) {
      return 0;
    }
  }

  // Check if file with given name exists
  static Future<bool> fileExists(String fileName) async {
    try {
      final filePath = '${_downloadDirectory.path}/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Generate unique filename to avoid conflicts
  static Future<String> _generateUniqueFileName(String fileName) async {
    if (!await fileExists(fileName)) {
      return fileName;
    }

    final dotIndex = fileName.lastIndexOf('.');
    String name = fileName;
    String? extension;

    if (dotIndex != -1) {
      name = fileName.substring(0, dotIndex);
      extension = fileName.substring(dotIndex);
    }

    int counter = 1;
    String newFileName;

    do {
      newFileName = '${name}_$counter${extension ?? ''}';
      counter++;
    } while (await fileExists(newFileName));

    return newFileName;
  }

  // Get all files in download directory
  static Future<List<FileModel>> getAllDownloadedFiles() async {
    try {
      if (!await _downloadDirectory.exists()) {
        return [];
      }

      final files = <FileModel>[];
      await for (final entity in _downloadDirectory.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          final fileId = entity.statSync().modified.millisecondsSinceEpoch.toString();
          final fileModel = FileModel.fromPath(entity.path, fileId);
          files.add(fileModel);
        }
      }

      // Sort by creation date (newest first)
      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return files;
    } catch (e) {
      return [];
    }
  }

  // Get directory size
  static Future<int> getDirectorySize(Directory directory) async {
    try {
      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Validate file path
  static bool isValidFilePath(String filePath) {
    if (filePath.isEmpty) return false;

    try {
      final file = File(filePath);
      return file.path.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get file extension
  static String getFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex != -1 ? fileName.substring(dotIndex + 1).toLowerCase() : '';
  }
}