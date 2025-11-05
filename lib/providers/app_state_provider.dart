import 'package:flutter/foundation.dart';
import 'package:wifi_file_transfer/services/p2p_service.dart';
import 'package:wifi_file_transfer/services/file_transfer_service.dart';
import 'package:wifi_file_transfer/services/storage_service.dart';
import 'package:wifi_file_transfer/models/device_model.dart';
import 'package:wifi_file_transfer/models/transfer_model.dart';
import 'package:wifi_file_transfer/utils/permissions.dart';

class AppStateProvider extends ChangeNotifier {
  final P2PService _p2pService = P2PService();
  final FileTransferService _fileTransferService = FileTransferService();

  // Loading states
  bool _isInitializing = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isTransferring = false;

  // Error states
  String? _error;

  // P2P state
  List<Device> _discoveredDevices = [];
  Device? _connectedDevice;
  ConnectionState _connectionState = ConnectionState.disconnected;
  Device? _thisDevice;

  // Transfer state
  List<TransferSession> _activeTransfers = [];
  List<TransferSession> _completedTransfers = [];
  List<String> _incomingTransferRequests = [];

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isDiscovering => _isDiscovering;
  bool get isConnecting => _isConnecting;
  bool get isTransferring => _isTransferring;
  String? get error => _error;
  List<Device> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Device? get connectedDevice => _connectedDevice;
  ConnectionState get connectionState => _connectionState;
  Device? get thisDevice => _thisDevice;
  List<TransferSession> get activeTransfers => List.unmodifiable(_activeTransfers);
  List<TransferSession> get completedTransfers => List.unmodifiable(_completedTransfers);
  List<String> get incomingTransferRequests => List.unmodifiable(_incomingTransferRequests);

  // Check if connected to any device
  bool get isConnected => _connectionState == ConnectionState.connected;

  // Get active transfer count
  int get activeTransferCount => _activeTransfers.length;

  // Check if there are any incoming requests
  bool get hasIncomingRequests => _incomingTransferRequests.isNotEmpty;

  // Initialize the app
  Future<void> initialize() async {
    if (_isInitializing) return;

    _setLoading(true);
    _clearError();

    try {
      // Initialize storage service
      await StorageService.initialize();

      // Check permissions
      final hasPermissions = await PermissionUtils.areAllPermissionsGranted();
      if (!hasPermissions) {
        await PermissionUtils.requestAllPermissions();
      }

      // Initialize P2P service
      final p2pInitialized = await _p2pService.initialize();
      if (!p2pInitialized) {
        throw Exception('Failed to initialize P2P service');
      }

      // Get this device info
      _thisDevice = await _p2pService.getThisDevice();

      // Start file transfer server
      await _fileTransferService.startServer();

      // Set up listeners
      _setupListeners();

      debugPrint('App initialized successfully');
    } catch (e) {
      _setError('Initialization failed: $e');
      debugPrint('App initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Start device discovery
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    _setDiscovering(true);
    _clearError();

    try {
      final success = await _p2pService.startDiscovery();
      if (!success) {
        throw Exception('Failed to start device discovery');
      }
    } catch (e) {
      _setError('Discovery failed: $e');
      _setDiscovering(false);
    }
  }

  // Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      await _p2pService.stopDiscovery();
      _setDiscovering(false);
    } catch (e) {
      _setError('Failed to stop discovery: $e');
    }
  }

  // Connect to device
  Future<void> connectToDevice(Device device) async {
    if (_isConnecting) return;

    _setConnecting(true);
    _clearError();

    try {
      final success = await _p2pService.connectToDevice(device);
      if (!success) {
        throw Exception('Failed to connect to device');
      }
    } catch (e) {
      _setError('Connection failed: $e');
      _setConnecting(false);
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    try {
      await _p2pService.disconnect();
      _connectedDevice = null;
      _connectionState = ConnectionState.disconnected;
      notifyListeners();
    } catch (e) {
      _setError('Disconnection failed: $e');
    }
  }

  // Send files
  Future<String?> sendFiles(List<String> filePaths, Device targetDevice) async {
    if (!isConnected) {
      _setError('Not connected to any device');
      return null;
    }

    try {
      // Convert file paths to FileModel
      final files = filePaths.map((path) =>
        FileModel.fromPath(path, DateTime.now().millisecondsSinceEpoch.toString())
      ).toList();

      // Get target device IP
      final targetIP = await _p2pService.getLocalIPAddress();
      if (targetIP == null) {
        throw Exception('Unable to get local IP address');
      }

      _setTransferring(true);
      _clearError();

      final transferId = await _fileTransferService.sendFiles(files, targetDevice, targetIP);
      return transferId;
    } catch (e) {
      _setError('File transfer failed: $e');
      _setTransferring(false);
      return null;
    }
  }

  // Accept incoming transfer
  Future<void> acceptTransfer(String transferId) async {
    try {
      await _fileTransferService.acceptTransfer(transferId);
      _incomingTransferRequests.remove(transferId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to accept transfer: $e');
    }
  }

  // Reject incoming transfer
  Future<void> rejectTransfer(String transferId) async {
    try {
      await _fileTransferService.rejectTransfer(transferId);
      _incomingTransferRequests.remove(transferId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to reject transfer: $e');
    }
  }

  // Cancel transfer
  Future<void> cancelTransfer(String transferId) async {
    try {
      await _fileTransferService.cancelTransfer(transferId);
      _removeTransfer(transferId);
    } catch (e) {
      _setError('Failed to cancel transfer: $e');
    }
  }

  // Get transfer session
  TransferSession? getTransferSession(String transferId) {
    return _fileTransferService.getTransferSession(transferId);
  }

  // Refresh device list
  Future<void> refreshDevices() async {
    if (_isDiscovering) {
      await stopDiscovery();
      await Future.delayed(const Duration(seconds: 1));
    }
    await startDiscovery();
  }

  // Setup event listeners
  void _setupListeners() {
    // Listen to discovered devices
    _p2pService.discoveredDevicesStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });

    // Listen to connection state changes
    _p2pService.connectionStateStream.listen((state) {
      _connectionState = state;
      _setConnecting(false);

      if (state == ConnectionState.connected) {
        _connectedDevice = _p2pService.connectedDevice;
      } else if (state == ConnectionState.disconnected) {
        _connectedDevice = null;
      }

      notifyListeners();
    });

    // Listen to transfer progress
    _fileTransferService.transferProgressStream.listen((session) {
      _updateTransfer(session);
    });

    // Listen to completed transfers
    _fileTransferService.transferCompletedStream.listen((session) {
      _updateTransfer(session);

      if (session.status == TransferStatus.completed ||
          session.status == TransferStatus.failed ||
          session.status == TransferStatus.cancelled) {
        _completeTransfer(session);
      }
    });

    // Listen to incoming transfers
    _fileTransferService.incomingTransferStream.listen((transferId) {
      _incomingTransferRequests.add(transferId);
      notifyListeners();
    });
  }

  // Update transfer in active list
  void _updateTransfer(TransferSession session) {
    final index = _activeTransfers.indexWhere((t) => t.id == session.id);
    if (index != -1) {
      _activeTransfers[index] = session;
      notifyListeners();
    } else {
      _activeTransfers.add(session);
      notifyListeners();
    }

    // Update transferring state
    _setTransferring(_activeTransfers.any((t) =>
      t.status == TransferStatus.inProgress || t.status == TransferStatus.preparing
    ));
  }

  // Complete transfer and move to completed list
  void _completeTransfer(TransferSession session) {
    _activeTransfers.removeWhere((t) => t.id == session.id);
    _completedTransfers.insert(0, session);

    // Keep only last 50 completed transfers
    if (_completedTransfers.length > 50) {
      _completedTransfers = _completedTransfers.take(50).toList();
    }

    _setTransferring(_activeTransfers.any((t) =>
      t.status == TransferStatus.inProgress || t.status == TransferStatus.preparing
    ));

    notifyListeners();
  }

  // Remove transfer from active list
  void _removeTransfer(String transferId) {
    _activeTransfers.removeWhere((t) => t.id == transferId);
    _setTransferring(_activeTransfers.any((t) =>
      t.status == TransferStatus.inProgress || t.status == TransferStatus.preparing
    ));
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
    debugPrint('Error: $error');
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isInitializing != loading) {
      _isInitializing = loading;
      notifyListeners();
    }
  }

  // Set discovering state
  void _setDiscovering(bool discovering) {
    if (_isDiscovering != discovering) {
      _isDiscovering = discovering;
      notifyListeners();
    }
  }

  // Set connecting state
  void _setConnecting(bool connecting) {
    if (_isConnecting != connecting) {
      _isConnecting = connecting;
      notifyListeners();
    }
  }

  // Set transferring state
  void _setTransferring(bool transferring) {
    if (_isTransferring != transferring) {
      _isTransferring = transferring;
      notifyListeners();
    }
  }

  // Clear completed transfers
  void clearCompletedTransfers() {
    _completedTransfers.clear();
    notifyListeners();
  }

  // Get device statistics
  Map<String, dynamic> getStatistics() {
    final totalTransfers = _activeTransfers.length + _completedTransfers.length;
    final successfulTransfers = _completedTransfers
        .where((t) => t.status == TransferStatus.completed)
        .length;
    final failedTransfers = _completedTransfers
        .where((t) => t.status == TransferStatus.failed)
        .length;

    return {
      'totalTransfers': totalTransfers,
      'successfulTransfers': successfulTransfers,
      'failedTransfers': failedTransfers,
      'devicesDiscovered': _discoveredDevices.length,
      'connectedDevice': _connectedDevice?.deviceName,
      'isDiscovering': _isDiscovering,
      'isTransferring': _isTransferring,
    };
  }

  @override
  void dispose() {
    _p2pService.dispose();
    _fileTransferService.dispose();
    super.dispose();
  }
}