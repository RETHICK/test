class AppConstants {
  // App Information
  static const String appName = 'WiFi File Transfer';
  static const String appVersion = '1.0.0';

  // Transfer Settings
  static const int chunkSize = 1024 * 1024; // 1MB chunks
  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const Duration transferTimeout = Duration(minutes: 10);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // File Type Icons
  static const Map<String, String> fileTypeIcons = {
    'pdf': '📄',
    'doc': '📄',
    'docx': '📄',
    'txt': '📝',
    'jpg': '🖼️',
    'jpeg': '🖼️',
    'png': '🖼️',
    'gif': '🖼️',
    'mp4': '🎬',
    'avi': '🎬',
    'mov': '🎬',
    'mp3': '🎵',
    'wav': '🎵',
    'zip': '📦',
    'rar': '📦',
  };

  // Error Messages
  static const String defaultErrorMessage = 'Something went wrong';
  static const String connectionFailedMessage = 'Failed to connect to device';
  static const String transferFailedMessage = 'File transfer failed';
  static const String insufficientStorageMessage = 'Insufficient storage space';
  static const String permissionDeniedMessage = 'Permission denied';
  static const String networkErrorMessage = 'Network error occurred';

  // Success Messages
  static const String transferCompletedMessage = 'Transfer completed successfully';
  static const String connectionEstablishedMessage = 'Connection established';
  static const String fileReceivedMessage = 'File received successfully';

  // Storage Paths
  static const String defaultDownloadFolder = 'WiFi File Transfer';
  static const String tempFolder = 'temp';

  // Port Configuration
  static const int defaultPort = 8888;
  static const int portRangeStart = 8000;
  static const int portRangeEnd = 8999;
}

class ConnectionConstants {
  // WiFi Direct States
  static const String wifiDirectEnabled = 'WIFI_DIRECT_STATE_ENABLED';
  static const String wifiDirectDisabled = 'WIFI_DIRECT_STATE_DISABLED';

  // Connection States
  static const String connected = 'CONNECTED';
  static const String invited = 'INVITED';
  static const String failed = 'FAILED';
  static const String available = 'AVAILABLE';
  static const String unavailable = 'UNAVAILABLE';
}

class UIConstants {
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Refresh Settings
  static const Duration refreshInterval = Duration(seconds: 3);
  static const Duration discoveryInterval = Duration(seconds: 5);

  // Progress Updates
  static const Duration progressUpdateInterval = Duration(milliseconds: 100);
}