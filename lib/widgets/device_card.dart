import 'package:flutter/material.dart';
import 'package:wifi_file_transfer/models/device_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final bool showActions;

  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
    this.onConnect,
    this.onDisconnect,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildConnectionStatus(),
                        const SizedBox(width: 8),
                        _buildSignalStrength(),
                      ],
                    ),
                    if (device.lastSeen != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last seen: ${_formatLastSeen(device.lastSeen)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: AppConstants.defaultPadding),
                _buildActionButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    IconData iconData;
    Color iconColor;

    switch (device.status) {
      case ConnectionStatus.connected:
        iconData = Icons.wifi;
        iconColor = Colors.green;
        break;
      case ConnectionStatus.connecting:
        iconData = Icons.wifi_find;
        iconColor = Colors.orange;
        break;
      case ConnectionStatus.connectingFailed:
        iconData = Icons.wifi_off;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.devices;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    String statusText;

    switch (device.status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting';
        break;
      case ConnectionStatus.connectingFailed:
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Available';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSignalStrength() {
    IconData signalIcon;
    Color signalColor;

    if (device.signalStrength >= 75) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (device.signalStrength >= 50) {
      signalIcon = Icons.signal_cellular_3_bar;
      signalColor = Colors.lightGreen;
    } else if (device.signalStrength >= 25) {
      signalIcon = Icons.signal_cellular_2_bar;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_1_bar;
      signalColor = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          signalIcon,
          color: signalColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${device.signalStrength}%',
          style: TextStyle(
            color: signalColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    switch (device.status) {
      case ConnectionStatus.connected:
        return OutlinedButton(
          onPressed: onDisconnect,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Disconnect'),
        );
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ConnectionStatus.connectingFailed:
        return OutlinedButton(
          onPressed: onConnect,
          child: const Text('Retry'),
        );
      default:
        return ElevatedButton(
          onPressed: onConnect,
          child: const Text('Connect'),
        );
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}