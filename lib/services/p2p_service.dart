import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:wifi_file_transfer/models/device_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';
import 'package:wifi_file_transfer/utils/permissions.dart';

class P2PService {
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  late FlutterP2pConnection _p2p;
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isGroupOwner = false;

  final StreamController<List<Device>> _discoveredDevicesController = StreamController.broadcast();
  final StreamController<ConnectionState> _connectionStateController = StreamController.broadcast();
  final StreamController<Device?> _currentDeviceController = StreamController.broadcast();

  List<Device> _discoveredDevices = [];
  Device? _connectedDevice;
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Getters
  Stream<List<Device>> get discoveredDevicesStream => _discoveredDevicesController.stream;
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<Device?> get currentDeviceStream => _currentDeviceController.stream;

  List<Device> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Device? get connectedDevice => _connectedDevice;
  ConnectionState get connectionState => _connectionState;
  bool get isDiscovering => _isDiscovering;
  bool get isGroupOwner => _isGroupOwner;
  bool get isInitialized => _isInitialized;

  // Initialize P2P service
  Future<bool> initialize() async {
    try {
      // Check permissions first
      final hasPermissions = await PermissionUtils.checkLocationPermission();
      if (!hasPermissions) {
        throw Exception('Location permission is required for WiFi Direct');
      }

      _p2p = FlutterP2pConnection();

      // Register event listeners
      _p2p.registerPeerListCallback().listen((peerList) {
        _handlePeerListUpdated(peerList);
      });

      _p2p.registerConnectionInfoCallback().listen((connectionInfo) {
        _handleConnectionInfoChanged(connectionInfo);
      });

      _p2p.registerThisDeviceCallback().listen((thisDevice) {
        _handleThisDeviceChanged(thisDevice);
      });

      _isInitialized = true;
      debugPrint('P2P Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize P2P Service: $e');
      return false;
    }
  }

  // Start device discovery
  Future<bool> startDiscovery() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (_isDiscovering) {
        debugPrint('Discovery already in progress');
        return true;
      }

      final success = await _p2p.startDiscovery();
      if (success) {
        _isDiscovering = true;
        debugPrint('Started device discovery');

        // Auto-stop discovery after timeout
        Timer(AppConstants.discoveryTimeout, () {
          if (_isDiscovering) {
            stopDiscovery();
          }
        });
      } else {
        debugPrint('Failed to start discovery');
      }

      return success;
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      return false;
    }
  }

  // Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      if (_isDiscovering) {
        await _p2p.stopDiscovery();
        _isDiscovering = false;
        debugPrint('Stopped device discovery');
      }
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice(Device device) async {
    try {
      if (_connectionState == ConnectionState.connected) {
        await disconnect();
      }

      debugPrint('Connecting to device: ${device.deviceName}');

      final success = await _p2p.connect(
        WifiP2pDevice(
          deviceAddress: device.deviceId,
          deviceName: device.deviceName,
        ),
      );

      if (success) {
        _updateConnectionState(ConnectionState.connecting);
        debugPrint('Connection request sent to: ${device.deviceName}');
      } else {
        debugPrint('Failed to connect to: ${device.deviceName}');
      }

      return success;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      return false;
    }
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _p2p.removeGroup();
      _connectedDevice = null;
      _updateConnectionState(ConnectionState.disconnected);
      _isGroupOwner = false;
      debugPrint('Disconnected from device');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  // Create group (become group owner)
  Future<bool> createGroup() async {
    try {
      final success = await _p2p.createGroup();
      if (success) {
        _isGroupOwner = true;
        debugPrint('Created P2P group - became group owner');
      } else {
        debugPrint('Failed to create P2P group');
      }
      return success;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return false;
    }
  }

  // Get local device information
  Future<Device?> getThisDevice() async {
    try {
      final thisDevice = await _p2p.getThisDevice();
      if (thisDevice != null) {
        return Device(
          deviceId: thisDevice.deviceAddress,
          deviceName: thisDevice.deviceName,
          status: ConnectionStatus.connected,
          lastSeen: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting this device: $e');
      return null;
    }
  }

  // Handle peer list updates
  void _handlePeerListUpdated(List<WifiP2pDevice> peerList) {
    final devices = peerList.map((peer) => Device(
      deviceId: peer.deviceAddress,
      deviceName: peer.deviceName,
      status: _mapDeviceStatus(peer.status),
      lastSeen: DateTime.now(),
    )).toList();

    _discoveredDevices = devices;
    _discoveredDevicesController.add(devices);
    debugPrint('Discovered ${devices.length} devices');
  }

  // Handle connection info changes
  void _handleConnectionInfoChanged(WifiP2pInfo? connectionInfo) {
    if (connectionInfo != null) {
      if (connectionInfo.groupFormed && connectionInfo.isGroupOwner) {
        _isGroupOwner = true;
        _updateConnectionState(ConnectionState.connected);
        debugPrint('Connected as group owner');
      } else if (connectionInfo.groupFormed) {
        _isGroupOwner = false;
        _updateConnectionState(ConnectionState.connected);
        debugPrint('Connected as client');
      } else {
        _updateConnectionState(ConnectionState.disconnected);
        debugPrint('Disconnected');
      }
    }
  }

  // Handle this device changes
  void _handleThisDeviceChanged(WifiP2pDevice? thisDevice) {
    if (thisDevice != null) {
      final device = Device(
        deviceId: thisDevice.deviceAddress,
        deviceName: thisDevice.deviceName,
        status: ConnectionStatus.connected,
        lastSeen: DateTime.now(),
      );
      _currentDeviceController.add(device);
    }
  }

  // Map WiFi P2P device status to our ConnectionStatus
  ConnectionStatus _mapDeviceStatus(int? status) {
    if (status == null) return ConnectionStatus.disconnected;

    switch (status) {
      case 0: // CONNECTED
        return ConnectionStatus.connected;
      case 1: // INVITED
        return ConnectionStatus.connecting;
      case 2: // FAILED
        return ConnectionStatus.connectingFailed;
      case 3: // AVAILABLE
        return ConnectionStatus.disconnected;
      case 4: // UNAVAILABLE
        return ConnectionStatus.disconnected;
      default:
        return ConnectionStatus.disconnected;
    }
  }

  // Update connection state
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      debugPrint('Connection state changed to: $newState');
    }
  }

  // Get network interface information
  Future<String?> getLocalIPAddress() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Check if it's a P2P interface (usually starts with 192.168.49.x)
            if (addr.address.startsWith('192.168.49')) {
              return addr.address;
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local IP address: $e');
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    stopDiscovery();
    disconnect();

    _discoveredDevicesController.close();
    _connectionStateController.close();
    _currentDeviceController.close();

    _isInitialized = false;
    debugPrint('P2P Service disposed');
  }
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}