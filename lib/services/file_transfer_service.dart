import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:wifi_file_transfer/models/transfer_model.dart';
import 'package:wifi_file_transfer/models/device_model.dart';
import 'package:wifi_file_transfer/models/file_model.dart';
import 'package:wifi_file_transfer/services/storage_service.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  factory FileTransferService() => _instance;
  FileTransferService._internal();

  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  bool _isServerRunning = false;
  bool _isTransferInProgress = false;

  final StreamController<TransferSession> _transferProgressController = StreamController.broadcast();
  final StreamController<TransferSession> _transferCompletedController = StreamController.broadcast();
  final StreamController<String> _incomingTransferController = StreamController.broadcast();

  Map<String, TransferSession> _activeTransfers = {};

  // Getters
  Stream<TransferSession> get transferProgressStream => _transferProgressController.stream;
  Stream<TransferSession> get transferCompletedStream => _transferCompletedController.stream;
  Stream<String> get incomingTransferStream => _incomingTransferController.stream;

  bool get isServerRunning => _isServerRunning;
  bool get isTransferInProgress => _isTransferInProgress;

  // Start server to receive files
  Future<bool> startServer() async {
    try {
      if (_isServerRunning) {
        return true;
      }

      _serverSocket = await ServerSocket.bind('0.0.0.0', AppConstants.defaultPort);
      _isServerRunning = true;

      // Listen for incoming connections
      _serverSocket!.listen((Socket socket) {
        _handleIncomingConnection(socket);
      });

      debugPrint('File transfer server started on port ${AppConstants.defaultPort}');
      return true;
    } catch (e) {
      debugPrint('Failed to start file transfer server: $e');
      return false;
    }
  }

  // Stop server
  Future<void> stopServer() async {
    try {
      if (_serverSocket != null) {
        await _serverSocket!.close();
        _serverSocket = null;
      }
      _isServerRunning = false;
      debugPrint('File transfer server stopped');
    } catch (e) {
      debugPrint('Error stopping server: $e');
    }
  }

  // Send files to a device
  Future<String> sendFiles(List<FileModel> files, Device targetDevice, String targetIP) async {
    try {
      final transferId = _generateTransferId();
      final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);

      final session = TransferSession(
        id: transferId,
        files: files,
        targetDevice: targetDevice,
        type: TransferType.send,
        status: TransferStatus.preparing,
        createdAt: DateTime.now(),
        totalBytes: totalBytes,
      );

      _activeTransfers[transferId] = session;
      _transferProgressController.add(session);

      // Connect to target device
      _clientSocket = await Socket.connect(targetIP, AppConstants.defaultPort)
          .timeout(AppConstants.connectionTimeout);

      if (_clientSocket == null) {
        throw Exception('Failed to connect to target device');
      }

      // Send file metadata
      await _sendFileMetadata(_clientSocket!, session);

      // Update status to in progress
      session = session.copyWith(status: TransferStatus.inProgress);
      _activeTransfers[transferId] = session;
      _transferProgressController.add(session);

      // Send files
      await _sendFiles(_clientSocket!, session);

      // Update status to completed
      final completedSession = session.copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
        bytesTransferred: totalBytes,
        completedAt: DateTime.now(),
      );

      _activeTransfers[transferId] = completedSession;
      _transferCompletedController.add(completedSession);

      await _clientSocket!.close();
      _clientSocket = null;

      return transferId;
    } catch (e) {
      debugPrint('Error sending files: $e');
      throw Exception('Failed to send files: $e');
    }
  }

  // Handle incoming connection
  void _handleIncomingConnection(Socket socket) {
    debugPrint('Incoming connection from ${socket.remoteAddress}');

    socket.listen(
      (Uint8List data) {
        _handleIncomingData(socket, data);
      },
      onDone: () {
        debugPrint('Connection closed: ${socket.remoteAddress}');
      },
      onError: (error) {
        debugPrint('Connection error: $error');
      },
    );
  }

  // Handle incoming data
  void _handleIncomingData(Socket socket, Uint8List data) {
    try {
      final message = String.fromCharCodes(data);
      final jsonData = json.decode(message);

      if (jsonData['type'] == 'metadata') {
        _handleFileMetadata(socket, jsonData);
      } else if (jsonData['type'] == 'fileData') {
        _handleFileData(socket, jsonData);
      }
    } catch (e) {
      debugPrint('Error handling incoming data: $e');
    }
  }

  // Handle file metadata
  void _handleFileMetadata(Socket socket, Map<String, dynamic> metadata) async {
    try {
      final transferId = metadata['transferId'];
      final filesData = metadata['files'] as List;
      final totalBytes = metadata['totalBytes'];

      final files = filesData.map((fileData) => FileModel(
        id: fileData['id'],
        name: fileData['name'],
        path: '', // Will be set when file is received
        size: fileData['size'],
        type: _parseFileType(fileData['type']),
        createdAt: DateTime.parse(fileData['createdAt']),
        extension: fileData['extension'],
      )).toList();

      final session = TransferSession(
        id: transferId,
        files: files,
        targetDevice: Device(
          deviceId: socket.remoteAddress.address,
          deviceName: 'Incoming Device',
          status: ConnectionStatus.connected,
          lastSeen: DateTime.now(),
        ),
        type: TransferType.receive,
        status: TransferStatus.pending,
        createdAt: DateTime.now(),
        totalBytes: totalBytes,
      );

      _activeTransfers[transferId] = session;
      _incomingTransferController.add(transferId);
      debugPrint('Received metadata for $filesData.length files');
    } catch (e) {
      debugPrint('Error handling file metadata: $e');
    }
  }

  // Handle file data
  void _handleFileData(Socket socket, Map<String, dynamic> fileData) async {
    try {
      final transferId = fileData['transferId'];
      final fileId = fileData['fileId'];
      final chunkData = base64.decode(fileData['data']);
      final isLastChunk = fileData['isLastChunk'] ?? false;

      final session = _activeTransfers[transferId];
      if (session == null) return;

      // Save chunk to file
      final file = session.files.firstWhere((f) => f.id == fileId);
      final savedFile = await StorageService.saveFileFromChunk(file, chunkData);

      // Update progress
      final newBytesTransferred = session.bytesTransferred + chunkData.length;
      final progress = newBytesTransferred / session.totalBytes;

      final updatedSession = session.copyWith(
        bytesTransferred: newBytesTransferred,
        progress: progress,
        status: isLastChunk ? TransferStatus.completed : TransferStatus.inProgress,
        completedAt: isLastChunk ? DateTime.now() : null,
      );

      _activeTransfers[transferId] = updatedSession;
      _transferProgressController.add(updatedSession);

      if (isLastChunk) {
        _transferCompletedController.add(updatedSession);
        debugPrint('File transfer completed: $transferId');
      }
    } catch (e) {
      debugPrint('Error handling file data: $e');
    }
  }

  // Send file metadata
  Future<void> _sendFileMetadata(Socket socket, TransferSession session) async {
    final metadata = {
      'type': 'metadata',
      'transferId': session.id,
      'files': session.files.map((file) => {
        'id': file.id,
        'name': file.name,
        'size': file.size,
        'type': file.type.toString(),
        'createdAt': file.createdAt.toIso8601String(),
        'extension': file.extension,
      }).toList(),
      'totalBytes': session.totalBytes,
    };

    final message = json.encode(metadata);
    socket.write(message);
    await socket.flush();
  }

  // Send files
  Future<void> _sendFiles(Socket socket, TransferSession session) async {
    int bytesTransferred = 0;

    for (final file in session.files) {
      final fileBytes = await File(file.path).readAsBytes();

      // Send file in chunks
      for (int i = 0; i < fileBytes.length; i += AppConstants.chunkSize) {
        final end = (i + AppConstants.chunkSize < fileBytes.length)
            ? i + AppConstants.chunkSize
            : fileBytes.length;

        final chunk = fileBytes.sublist(i, end);
        final isLastChunk = end >= fileBytes.length;

        final chunkData = {
          'type': 'fileData',
          'transferId': session.id,
          'fileId': file.id,
          'data': base64.encode(chunk),
          'isLastChunk': isLastChunk,
        };

        final message = json.encode(chunkData);
        socket.write(message);
        await socket.flush();

        bytesTransferred += chunk.length;

        // Update progress
        final progress = bytesTransferred / session.totalBytes;
        final updatedSession = session.copyWith(
          bytesTransferred: bytesTransferred,
          progress: progress,
        );

        _activeTransfers[session.id] = updatedSession;
        _transferProgressController.add(updatedSession);

        // Small delay to prevent overwhelming the receiver
        await Future.delayed(Duration(milliseconds: 10));
      }
    }
  }

  // Accept incoming transfer
  Future<void> acceptTransfer(String transferId) async {
    try {
      final session = _activeTransfers[transferId];
      if (session == null) return;

      final updatedSession = session.copyWith(
        status: TransferStatus.inProgress,
      );

      _activeTransfers[transferId] = updatedSession;
      _transferProgressController.add(updatedSession);

      // Send acceptance message
      _clientSocket?.write(json.encode({
        'type': 'accept',
        'transferId': transferId,
      }));
    } catch (e) {
      debugPrint('Error accepting transfer: $e');
    }
  }

  // Reject incoming transfer
  Future<void> rejectTransfer(String transferId) async {
    try {
      _activeTransfers.remove(transferId);

      // Send rejection message
      _clientSocket?.write(json.encode({
        'type': 'reject',
        'transferId': transferId,
      }));
    } catch (e) {
      debugPrint('Error rejecting transfer: $e');
    }
  }

  // Get transfer session
  TransferSession? getTransferSession(String transferId) {
    return _activeTransfers[transferId];
  }

  // Get all active transfers
  List<TransferSession> getActiveTransfers() {
    return _activeTransfers.values.toList();
  }

  // Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    try {
      final session = _activeTransfers[transferId];
      if (session == null) return;

      final cancelledSession = session.copyWith(
        status: TransferStatus.cancelled,
        completedAt: DateTime.now(),
      );

      _activeTransfers[transferId] = cancelledSession;
      _transferCompletedController.add(cancelledSession);

      // Close connection if sending
      if (session.type == TransferType.send && _clientSocket != null) {
        await _clientSocket!.close();
        _clientSocket = null;
      }
    } catch (e) {
      debugPrint('Error cancelling transfer: $e');
    }
  }

  // Generate unique transfer ID
  String _generateTransferId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_activeTransfers.length}';
  }

  // Parse file type from string
  FileType _parseFileType(String typeString) {
    for (final type in FileType.values) {
      if (type.toString() == typeString) {
        return type;
      }
    }
    return FileType.other;
  }

  // Dispose resources
  void dispose() {
    stopServer();

    if (_clientSocket != null) {
      _clientSocket!.close();
      _clientSocket = null;
    }

    _transferProgressController.close();
    _transferCompletedController.close();
    _incomingTransferController.close();

    _activeTransfers.clear();
    debugPrint('File transfer service disposed');
  }
}

extension StorageServiceExtension on StorageService {
  static Future<FileModel> saveFileFromChunk(FileModel file, List<int> chunk) async {
    // This is a simplified version - in a real implementation, you'd need to
    // handle chunk assembly and temporary file management
    final tempPath = '${tempDirectory.path}/${file.name}';
    final tempFile = File(tempPath);

    // Append chunk to file
    await tempFile.writeAsBytes(chunk, mode: FileMode.append);

    // If this is the last chunk, move to final location
    final finalFile = await saveFile(tempPath, file.name);
    await tempFile.delete();

    return finalFile;
  }
}