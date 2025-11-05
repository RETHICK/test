enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  connectingFailed,
}

class Device {
  final String deviceId;
  final String deviceName;
  final String? ipAddress;
  final ConnectionStatus status;
  final DateTime lastSeen;
  final int signalStrength;

  Device({
    required this.deviceId,
    required this.deviceName,
    this.ipAddress,
    this.status = ConnectionStatus.disconnected,
    required this.lastSeen,
    this.signalStrength = 0,
  });

  Device copyWith({
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    ConnectionStatus? status,
    DateTime? lastSeen,
    int? signalStrength,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'Device(id: $deviceId, name: $deviceName, status: $status)';
  }
}