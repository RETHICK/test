import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_file_transfer/providers/app_state_provider.dart';
import 'package:wifi_file_transfer/widgets/file_picker_widget.dart';
import 'package:wifi_file_transfer/widgets/progress_bar.dart';
import 'package:wifi_file_transfer/models/file_model.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with TickerProviderStateMixin {
  List<FileModel> _selectedFiles = [];
  late TabController _tabController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.upload_file),
              text: 'Send Files',
            ),
            Tab(
              icon: Icon(Icons.download),
              text: 'Receive Files',
            ),
          ],
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          // Show connection warning if not connected
          if (!provider.isConnected) {
            return _buildNotConnectedWarning();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSendFilesTab(provider),
              _buildReceiveFilesTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (_tabController.index == 0 && _selectedFiles.isNotEmpty) {
            return AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabController.value,
                  child: FloatingActionButton.extended(
                    onPressed: provider.isTransferring ? null : _sendFiles,
                    icon: provider.isTransferring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(provider.isTransferring ? 'Sending...' : 'Send Files'),
                    backgroundColor: provider.isTransferring
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotConnectedWarning() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            Text(
              'No Device Connected',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Connect to a device first to start transferring files',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to devices tab
                _navigateToMainTab(1);
              },
              icon: const Icon(Icons.devices),
              label: const Text('Find Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendFilesTab(AppStateProvider provider) {
    return Column(
      children: [
        // Connected device info
        _buildConnectedDeviceInfo(provider),

        // File picker
        Expanded(
          child: FilePickerWidget(
            selectedFiles: _selectedFiles,
            onFilesSelected: (files) {
              setState(() {
                _selectedFiles = files;
              });

              // Animate FAB
              if (files.isNotEmpty) {
                _fabController.forward();
              } else {
                _fabController.reverse();
              }
            },
            multiSelect: true,
            maxFileSize: 1024 * 1024 * 1024, // 1GB max
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDeviceInfo(AppStateProvider provider) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected to',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      provider.connectedDevice?.deviceName ?? 'Unknown Device',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiveFilesTab(AppStateProvider provider) {
    return Column(
      children: [
        // Server status
        _buildServerStatus(provider),

        // Incoming requests
        Expanded(
          child: _buildIncomingRequests(provider),
        ),
      ],
    );
  }

  Widget _buildServerStatus(AppStateProvider provider) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                ),
                child: const Icon(
                  Icons.cloud_download,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receiving Files',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ready to receive files from connected devices',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lan,
                color: Colors.blue,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingRequests(AppStateProvider provider) {
    if (!provider.hasIncomingRequests) {
      return _buildNoIncomingRequests();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: provider.incomingTransferRequests.length,
      itemBuilder: (context, index) {
        final transferId = provider.incomingTransferRequests[index];
        final session = provider.getTransferSession(transferId);

        if (session == null) {
          return const SizedBox.shrink();
        }

        return _buildIncomingTransferCard(session, provider);
      },
    );
  }

  Widget _buildNoIncomingRequests() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.dividerColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.inbox,
              size: 50,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'Waiting for Files',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Files sent from connected devices will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTransferCard(TransferSession session, AppStateProvider provider) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incoming Files',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'From ${session.targetDevice.deviceName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // File list
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: session.files.length,
                itemBuilder: (context, index) {
                  final file = session.files[index];
                  return _buildIncomingFileItem(file);
                },
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Total size
            Text(
              'Total: ${session.formattedTotalSize}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectTransfer(session.id, provider),
                    child: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptTransfer(session.id, provider),
                    child: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingFileItem(FileModel file) {
    final theme = Theme.of(context);
    final fileIcon = _getFileIcon(file.type, file.extension);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            fileIcon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            file.formattedSize,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _sendFiles() async {
    if (_selectedFiles.isEmpty) return;

    final provider = context.read<AppStateProvider>();
    final filePaths = _selectedFiles.map((file) => file.path).toList();

    try {
      final transferId = await provider.sendFiles(filePaths, provider.connectedDevice!);

      if (transferId != null) {
        // Clear selected files after successful send
        setState(() {
          _selectedFiles.clear();
        });
        _fabController.reverse();

        // Switch to history tab
        _tabController.animateTo(1);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File transfer started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptTransfer(String transferId, AppStateProvider provider) async {
    try {
      await provider.acceptTransfer(transferId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept transfer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectTransfer(String transferId, AppStateProvider provider) async {
    try {
      await provider.rejectTransfer(transferId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject transfer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}