# WiFi File Transfer

A Flutter application that enables fast file sharing between devices using WiFi Direct technology.

## Features

- **Device Discovery**: Automatically discover nearby devices using WiFi Direct
- **Direct Connection**: Establish secure P2P connections without internet
- **File Transfer**: Send and receive various file types (documents, images, videos, etc.)
- **Progress Tracking**: Real-time transfer progress with speed indicators
- **Transfer History**: View complete transfer history with statistics
- **Android Optimized**: Full WiFi Direct support for Android devices

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── device_model.dart        # Device representation
│   ├── transfer_model.dart      # Transfer session data
│   └── file_model.dart          # File information
├── services/                    # Core services
│   ├── p2p_service.dart         # WiFi Direct management
│   ├── file_transfer_service.dart # File transfer logic
│   └── storage_service.dart     # File storage management
├── screens/                     # UI screens
│   ├── home_screen.dart         # Main interface
│   ├── devices_screen.dart      # Device discovery
│   ├── transfer_screen.dart     # File transfer
│   └── history_screen.dart      # Transfer history
├── widgets/                     # Reusable components
│   ├── device_card.dart         # Device display
│   ├── progress_bar.dart        # Transfer progress
│   └── file_picker_widget.dart  # File selection
└── utils/                       # Utilities
    ├── permissions.dart         # Permission handling
    └── constants.dart           # App constants
```

## Key Dependencies

- `flutter_p2p_connection: ^2.4.0` - WiFi Direct functionality
- `file_picker: ^6.1.1` - File selection
- `path_provider: ^2.1.1` - Storage paths
- `permission_handler: ^11.0.1` - Permissions
- `provider: ^6.1.1` - State management

## Android Requirements

- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Required Permissions**:
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_WIFI_STATE`
  - `CHANGE_WIFI_STATE`
  - `INTERNET`
  - `ACCESS_NETWORK_STATE`
  - `WRITE_EXTERNAL_STORAGE`
  - `READ_EXTERNAL_STORAGE`

## Getting Started

1. Ensure you have Flutter installed
2. Set up Android development environment
3. Run the app:
   ```bash
   flutter run
   ```

## How to Use

1. **Connect to WiFi Direct**:
   - Go to Devices tab
   - Tap "Start Discovery"
   - Select a device from the list
   - Confirm connection

2. **Send Files**:
   - Go to Transfer tab
   - Select "Send Files"
   - Choose files using the file picker
   - Tap "Send Files"

3. **Receive Files**:
   - Go to Transfer tab > "Receive Files"
   - Wait for incoming transfer requests
   - Accept or reject incoming files

4. **View History**:
   - Go to History tab
   - View active, completed, and failed transfers
   - Check transfer statistics

## Architecture

The app follows a clean architecture with separation of concerns:

- **Models**: Define data structures
- **Services**: Handle business logic
- **Providers**: Manage state
- **Screens**: UI implementation
- **Widgets**: Reusable components

## File Transfer Protocol

- Uses TCP sockets for reliable data transfer
- JSON metadata headers with file information
- Chunked file streaming (1MB chunks)
- Progress tracking with real-time updates
- Checksum verification for file integrity

## Performance Targets

- Device discovery: <10 seconds
- Connection establishment: <5 seconds
- Transfer speed: >10MB/s for large files
- Memory usage: <200MB during transfers

## Troubleshooting

**Common Issues**:

1. **Permission Denied**: Ensure all required permissions are granted
2. **WiFi Direct Not Available**: Check device compatibility
3. **Connection Fails**: Restart WiFi Direct on both devices
4. **Transfer Slow**: Check signal strength and interference

**Debug Steps**:

1. Check Android logcat for error messages
2. Verify WiFi Direct is enabled in device settings
3. Ensure both devices are on the same WiFi network
4. Restart the app if connection issues persist

## Contributing

This is a demonstration project showcasing WiFi Direct file transfer capabilities in Flutter.

## License

This project is for educational purposes.