import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_file_transfer/providers/app_state_provider.dart';
import 'package:wifi_file_transfer/widgets/progress_bar.dart';
import 'package:wifi_file_transfer/models/transfer_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.sync),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Completed',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'Statistics',
            ),
          ],
        ),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              if (provider.completedTransfers.isNotEmpty) {
                return IconButton(
                  onPressed: _showClearHistoryDialog,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear History',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTransfersTab(provider),
              _buildCompletedTransfersTab(provider),
              _buildStatisticsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveTransfersTab(AppStateProvider provider) {
    final activeTransfers = provider.activeTransfers;

    if (activeTransfers.isEmpty) {
      return _buildEmptyState(
        'No Active Transfers',
        'Currently active file transfers will appear here',
        Icons.sync,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: activeTransfers.length,
      itemBuilder: (context, index) {
        final transfer = activeTransfers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: TransferProgressBar(
            transfer: transfer,
            onPause: transfer.status == TransferStatus.inProgress
                ? () => _pauseTransfer(transfer.id, provider)
                : null,
            onResume: transfer.status == TransferStatus.paused
                ? () => _resumeTransfer(transfer.id, provider)
                : null,
            onCancel: () => _showCancelTransferDialog(transfer, provider),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTransfersTab(AppStateProvider provider) {
    final completedTransfers = provider.completedTransfers;

    if (completedTransfers.isEmpty) {
      return _buildEmptyState(
        'No Transfer History',
        'Completed file transfers will appear here',
        Icons.history,
      );
    }

    return Column(
      children: [
        // Filter options
        _buildFilterOptions(),

        // Transfer list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: completedTransfers.length,
            itemBuilder: (context, index) {
              final transfer = completedTransfers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                child: _buildCompletedTransferCard(transfer),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('All'),
              selected: true,
              onSelected: (selected) {},
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: FilterChip(
              label: const Text('Sent'),
              selected: false,
              onSelected: (selected) {},
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: FilterChip(
              label: const Text('Received'),
              selected: false,
              onSelected: (selected) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTransferCard(TransferSession transfer) {
    final theme = Theme.of(context);
    final wasSuccessful = transfer.status == TransferStatus.completed;

    return Card(
      child: InkWell(
        onTap: () => _showTransferDetails(transfer),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: wasSuccessful
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                    ),
                    child: Icon(
                      transfer.type == TransferType.send
                          ? Icons.upload
                          : Icons.download,
                      color: wasSuccessful ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfer.type == TransferType.send ? 'Sent Files' : 'Received Files',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'From/To: ${transfer.targetDevice.deviceName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        wasSuccessful ? Icons.check_circle : Icons.error,
                        color: wasSuccessful ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wasSuccessful ? 'Success' : 'Failed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: wasSuccessful ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Files',
                      '${transfer.files.length}',
                      Icons.description,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Size',
                      transfer.formattedTotalSize,
                      Icons.storage,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Speed',
                      transfer.transferSpeed,
                      Icons.speed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(transfer.completedAt ?? transfer.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(AppStateProvider provider) {
    final stats = provider.getStatistics();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Text(
            'Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Transfers',
                  '${stats['totalTransfers']}',
                  Icons.swap_horiz,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildStatCard(
                  'Successful',
                  '${stats['successfulTransfers']}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  '${stats['failedTransfers']}',
                  Icons.error,
                  Colors.red,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  stats['totalTransfers'] > 0
                      ? '${((stats['successfulTransfers'] / stats['totalTransfers']) * 100).toInt()}%'
                      : '0%',
                  Icons.percent,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Connection Stats
          Text(
            'Connection',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Devices Found',
                  '${stats['devicesDiscovered']}',
                  Icons.devices,
                  theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildStatCard(
                  'Connected To',
                  stats['connectedDevice'] ?? 'None',
                  stats['connectedDevice'] != null ? Icons.link : Icons.link_off,
                  stats['connectedDevice'] != null ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Recent Activity
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          _buildRecentActivityList(provider),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(AppStateProvider provider) {
    final recentTransfers = [
      ...provider.activeTransfers,
      ...provider.completedTransfers.take(5),
    ];

    if (recentTransfers.isEmpty) {
      return _buildEmptyState(
        'No Recent Activity',
        'Your transfer activity will appear here',
        Icons.history,
      );
    }

    return Column(
      children: recentTransfers.map((transfer) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: TransferProgressBar(
            transfer: transfer,
            showActions: false,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _pauseTransfer(String transferId, AppStateProvider provider) {
    // Implementation for pausing transfer
    // This would need to be added to the AppStateProvider
  }

  void _resumeTransfer(String transferId, AppStateProvider provider) {
    // Implementation for resuming transfer
    // This would need to be added to the AppStateProvider
  }

  void _showCancelTransferDialog(TransferSession transfer, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transfer'),
        content: const Text('Are you sure you want to cancel this transfer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              provider.cancelTransfer(transfer.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showTransferDetails(TransferSession transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransferDetailsSheet(transfer: transfer),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all transfer history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().clearCompletedTransfers();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transfer history cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _TransferDetailsSheet extends StatelessWidget {
  final TransferSession transfer;

  const _TransferDetailsSheet({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: transfer.status == TransferStatus.completed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                  ),
                  child: Icon(
                    transfer.type == TransferType.send
                        ? Icons.upload
                        : Icons.download,
                    color: transfer.status == TransferStatus.completed
                        ? Colors.green
                        : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.type == TransferType.send ? 'Sent Files' : 'Received Files',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'With ${transfer.targetDevice.deviceName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  transfer.status == TransferStatus.completed
                      ? Icons.check_circle
                      : Icons.error,
                  color: transfer.status == TransferStatus.completed
                      ? Colors.green
                      : Colors.red,
                  size: 24,
                ),
              ],
            ),
          ),

          const Divider(),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                _buildDetailRow(
                  'Status',
                  transfer.status.toString().split('.').last,
                  _getStatusIcon(transfer.status),
                  _getStatusColor(transfer.status),
                ),
                _buildDetailRow(
                  'Files Count',
                  '${transfer.files.length}',
                  Icons.description,
                  theme.colorScheme.primary,
                ),
                _buildDetailRow(
                  'Total Size',
                  transfer.formattedTotalSize,
                  Icons.storage,
                  theme.colorScheme.primary,
                ),
                _buildDetailRow(
                  'Transfer Speed',
                  transfer.transferSpeed,
                  Icons.speed,
                  theme.colorScheme.primary,
                ),
                _buildDetailRow(
                  'Started',
                  _formatDateTime(transfer.createdAt),
                  Icons.access_time,
                  theme.colorScheme.primary,
                ),
                if (transfer.completedAt != null)
                  _buildDetailRow(
                    'Completed',
                    _formatDateTime(transfer.completedAt!),
                    Icons.access_time,
                    Colors.green,
                  ),
              ],
            ),
          ),

          // File list
          if (transfer.files.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Files',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: transfer.files.length,
                      itemBuilder: (context, index) {
                        final file = transfer.files[index];
                        return _buildFileItem(file, theme);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileModel file, ThemeData theme) {
    final fileIcon = _getFileIcon(file.type, file.extension);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Text(
            fileIcon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Icons.check_circle;
      case TransferStatus.failed:
        return Icons.error;
      case TransferStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getFileIcon(FileType type, String? extension) {
    if (extension != null && AppConstants.fileTypeIcons.containsKey(extension)) {
      return AppConstants.fileTypeIcons[extension]!;
    }

    switch (type) {
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎬';
      case FileType.audio:
        return '🎵';
      case FileType.document:
        return '📄';
      default:
        return '📎';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}