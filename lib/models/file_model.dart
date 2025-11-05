import 'dart:io';

enum FileType {
  document,
  image,
  video,
  audio,
  other,
}

class FileModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final FileType type;
  final DateTime createdAt;
  final String? extension;

  FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.createdAt,
    this.extension,
  });

  factory FileModel.fromPath(String filePath, String fileId) {
    final pathSegments = filePath.split('/');
    final fileName = pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex != -1 ? fileName.substring(dotIndex + 1) : null;

    FileType fileType = FileType.other;
    if (extension != null) {
      final ext = extension.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
        fileType = FileType.image;
      } else if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv'].contains(ext)) {
        fileType = FileType.video;
      } else if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) {
        fileType = FileType.audio;
      } else if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
        fileType = FileType.document;
      }
    }

    final file = File(filePath);

    return FileModel(
      id: fileId,
      name: fileName,
      path: filePath,
      size: file.lengthSync(),
      type: fileType,
      createdAt: file.statSync().modified,
      extension: extension,
    );
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'FileModel(id: $id, name: $name, size: $formattedSize, type: $type)';
  }
}