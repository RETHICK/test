import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_file_transfer/providers/app_state_provider.dart';
import 'package:wifi_file_transfer/widgets/device_card.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _refreshController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    // Start discovery when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDiscovery();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: _isRefreshing ? null : _refreshDevices,
                icon: AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isRefreshing ? _refreshController.value * 6.28 : 0,
                      child: Icon(
                        Icons.refresh,
                        color: _isRefreshing ? Colors.grey : null,
                      ),
                    );
                  },
                ),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Discovery Status Card
              _buildDiscoveryStatus(provider),

              // Device List
              Expanded(
                child: _buildDeviceList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleDiscovery,
        icon: Icon(
          provider.isDiscovering ? Icons.stop : Icons.search,
        ),
        label: Text(provider.isDiscovering ? 'Stop Discovery' : 'Start Discovery'),
      ),
    );
  }

  Widget _buildDiscoveryStatus(AppStateProvider provider) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  // Status Icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: provider.isDiscovering
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              provider.isDiscovering ? Icons.radar : Icons.wifi_find,
                              color: provider.isDiscovering ? Colors.orange : Colors.grey,
                              size: 24,
                            ),
                            if (provider.isDiscovering)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),

                  // Status Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isDiscovering ? 'Discovering Devices' : 'Discovery Idle',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: provider.isDiscovering ? Colors.orange : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.isDiscovering
                              ? 'Searching for nearby devices...'
                              : 'Tap search to find devices',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Device Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.discoveredDevices.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (provider.isDiscovering) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                LinearProgressIndicator(
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(AppStateProvider provider) {
    if (provider.discoveredDevices.isEmpty) {
      return _buildEmptyState(provider.isDiscovering);
    }

    return RefreshIndicator(
      onRefresh: _refreshDevices,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100), // Account for FAB
        itemCount: provider.discoveredDevices.length,
        itemBuilder: (context, index) {
          final device = provider.discoveredDevices[index];
          return DeviceCard(
            device: device,
            onTap: () => _showDeviceDetails(device),
            onConnect: () => _connectToDevice(device),
            onDisconnect: () => provider.disconnect(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDiscovering) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isDiscovering ? Icons.radar : Icons.devices_other,
                    size: 60,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Title
          Text(
            isDiscovering ? 'Searching for Devices' : 'No Devices Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Description
          Text(
            isDiscovering
                ? 'Make sure WiFi Direct is enabled on nearby devices'
                : 'Start device discovery to find nearby devices',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Action Button
          if (!isDiscovering)
            ElevatedButton.icon(
              onPressed: _startDiscovery,
              icon: const Icon(Icons.search),
              label: const Text('Start Discovery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startDiscovery() async {
    final provider = context.read<AppStateProvider>();
    await provider.startDiscovery();
  }

  void _stopDiscovery() async {
    final provider = context.read<AppStateProvider>();
    await provider.stopDiscovery();
  }

  void _toggleDiscovery() {
    final provider = context.read<AppStateProvider>();
    if (provider.isDiscovering) {
      _stopDiscovery();
    } else {
      _startDiscovery();
    }
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isRefreshing = true;
      _refreshController.forward();
    });

    try {
      final provider = context.read<AppStateProvider>();
      await provider.refreshDevices();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
      await _refreshController.reverse();
    }
  }

  void _connectToDevice(Device device) async {
    final provider = context.read<AppStateProvider>();

    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConnectingDialog(device: device),
    );

    try {
      await provider.connectToDevice(device);

      // Close connecting dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.deviceName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close connecting dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeviceDetails(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DeviceDetailsSheet(device: device),
    );
  }
}

class _ConnectingDialog extends StatefulWidget {
  final Device device;

  const _ConnectingDialog({required this.device});

  @override
  State<_ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<_ConnectingDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.1),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Connecting...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Establishing connection with ${widget.device.deviceName}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceDetailsSheet extends StatelessWidget {
  final Device device;

  const _DeviceDetailsSheet({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppStateProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Device Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    Icons.devices,
                    size: 32,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device ID: ${device.deviceId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(context, device.status),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Device Information
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                _buildInfoRow(
                  context,
                  'Signal Strength',
                  '${device.signalStrength}%',
                  Icons.signal_cellular_alt,
                ),
                _buildInfoRow(
                  context,
                  'Last Seen',
                  _formatLastSeen(device.lastSeen),
                  Icons.access_time,
                ),
                _buildInfoRow(
                  context,
                  'Device Address',
                  device.deviceId,
                  Icons.memory,
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (device.status == ConnectionStatus.connected) {
                        provider.disconnect();
                      } else {
                        // Connect to device
                        provider.connectToDevice(device).then((_) {
                          if (provider.isConnected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Connected to ${device.deviceName}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                      }
                    },
                    icon: Icon(
                      device.status == ConnectionStatus.connected
                          ? Icons.link_off
                          : Icons.link,
                    ),
                    label: Text(
                      device.status == ConnectionStatus.connected
                          ? 'Disconnect'
                          : 'Connect',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: device.status == ConnectionStatus.connected
                          ? Colors.red
                          : theme.colorScheme.primary,
                      foregroundColor: device.status == ConnectionStatus.connected
                          ? Colors.white
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ConnectionStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        chipColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        chipColor = Colors.orange;
        statusText = 'Connecting';
        break;
      case ConnectionStatus.connectingFailed:
        chipColor = Colors.red;
        statusText = 'Connection Failed';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Available';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}