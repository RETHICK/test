import 'package:wifi_file_transfer/models/device_model.dart';
import 'package:wifi_file_transfer/models/file_model.dart';

enum TransferStatus {
  pending,
  preparing,
  inProgress,
  paused,
  completed,
  failed,
  cancelled,
}

enum TransferType {
  send,
  receive,
}

class TransferSession {
  final String id;
  final List<FileModel> files;
  final Device targetDevice;
  final TransferType type;
  final TransferStatus status;
  final DateTime createdAt;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final String? errorMessage;
  final DateTime? completedAt;

  TransferSession({
    required this.id,
    required this.files,
    required this.targetDevice,
    required this.type,
    this.status = TransferStatus.pending,
    required this.createdAt,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    required this.totalBytes,
    this.errorMessage,
    this.completedAt,
  });

  TransferSession copyWith({
    String? id,
    List<FileModel>? files,
    Device? targetDevice,
    TransferType? type,
    TransferStatus? status,
    DateTime? createdAt,
    double? progress,
    int? bytesTransferred,
    int? totalBytes,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return TransferSession(
      id: id ?? this.id,
      files: files ?? this.files,
      targetDevice: targetDevice ?? this.targetDevice,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get progressPercentage => '${(progress * 100).toInt()}%';

  String get transferSpeed {
    if (bytesTransferred == 0 || completedAt == null) return '0 MB/s';

    final duration = completedAt!.difference(createdAt).inMilliseconds;
    if (duration == 0) return '0 MB/s';

    final speedBytesPerMs = bytesTransferred / duration;
    final speedMBPerSec = (speedBytesPerMs * 1000) / (1024 * 1024);
    return '${speedMBPerSec.toStringAsFixed(1)} MB/s';
  }

  String get formattedTotalSize {
    if (totalBytes < 1024) return '${totalBytes}B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get formattedTransferredSize {
    if (bytesTransferred < 1024) return '${bytesTransferred}B';
    if (bytesTransferred < 1024 * 1024) return '${(bytesTransferred / 1024).toStringAsFixed(1)}KB';
    if (bytesTransferred < 1024 * 1024 * 1024) return '${(bytesTransferred / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytesTransferred / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'TransferSession(id: $id, type: $type, status: $status, progress: $progressPercentage)';
  }
}