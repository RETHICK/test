import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_file_transfer/providers/app_state_provider.dart';
import 'package:wifi_file_transfer/screens/devices_screen.dart';
import 'package:wifi_file_transfer/screens/transfer_screen.dart';
import 'package:wifi_file_transfer/screens/history_screen.dart';
import 'package:wifi_file_transfer/widgets/progress_bar.dart';
import 'package:wifi_file_transfer/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          // Show loading screen during initialization
          if (provider.isInitializing) {
            return const _LoadingScreen();
          }

          // Show error screen if initialization failed
          if (provider.error != null && provider.connectedDevice == null) {
            return _ErrorScreen(
              error: provider.error!,
              onRetry: () => provider.initialize(),
            );
          }

          return Column(
            children: [
              // Custom App Bar
              _buildAppBar(provider),

              // Connection Status Bar
              _buildConnectionStatus(provider),

              // Active Transfers (if any)
              if (provider.activeTransfers.isNotEmpty) ...[
                _buildActiveTransfers(provider),
                const Divider(height: 1),
              ],

              // Main Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: const [
                    _HomeTab(),
                    DevicesScreen(),
                    TransferScreen(),
                    HistoryScreen(),
                  ],
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigationBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AppStateProvider provider) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding + 20, // Account for status bar
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.background,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // App Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),

              // App Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTagline(_currentIndex),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Button
              IconButton(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
              ),
            ],
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Quick Stats
          Row(
            children: [
              _buildStatItem(
                'Devices',
                '${provider.discoveredDevices.length}',
                Icons.devices,
                theme.colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              _buildStatItem(
                'Active',
                '${provider.activeTransfers.length}',
                Icons.sync,
                theme.colorScheme.secondary,
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              _buildStatItem(
                'Connected',
                provider.isConnected ? 'Yes' : 'No',
                Icons.wifi,
                provider.isConnected ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(AppStateProvider provider) {
    final theme = Theme.of(context);

    if (!provider.isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to ${provider.connectedDevice?.deviceName ?? 'Unknown Device'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Ready to transfer files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: provider.disconnect,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Disconnect'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTransfers(AppStateProvider provider) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Transfers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.activeTransfers.length,
              itemBuilder: (context, index) {
                final transfer = provider.activeTransfers[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: AppConstants.defaultPadding),
                  child: TransferProgressBar(
                    transfer: transfer,
                    showActions: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: AppConstants.mediumAnimation,
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  String _getTagline(int index) {
    switch (index) {
      case 0:
        return 'Fast file sharing over WiFi Direct';
      case 1:
        return 'Discover nearby devices';
      case 2:
        return 'Send and receive files';
      case 3:
        return 'View transfer history';
      default:
        return 'WiFi File Transfer';
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SettingsSheet(),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      title: 'Share Files',
                      icon: Icons.upload_file,
                      color: theme.colorScheme.primary,
                      onTap: () {
                        if (!provider.isConnected) {
                          _showNotConnectedMessage(context);
                        } else {
                          // Navigate to transfer screen
                          _navigateToTab(2);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      title: 'Find Devices',
                      icon: Icons.search,
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        _navigateToTab(1);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Status Section
              Text(
                'Connection Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              _buildStatusCard(
                context,
                title: 'WiFi Direct',
                subtitle: provider.isConnected ? 'Connected' : 'Not Connected',
                icon: provider.isConnected ? Icons.wifi : Icons.wifi_off,
                color: provider.isConnected ? Colors.green : Colors.grey,
                details: provider.isConnected
                    ? 'Connected to ${provider.connectedDevice?.deviceName}'
                    : 'No active connections',
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              _buildStatusCard(
                context,
                title: 'Discovery',
                subtitle: provider.isDiscovering ? 'Searching' : 'Idle',
                icon: provider.isDiscovering ? Icons.search : Icons.search_off,
                color: provider.isDiscovering ? Colors.orange : Colors.grey,
                details: provider.isDiscovering
                    ? 'Finding nearby devices...'
                    : 'Not searching for devices',
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

              if (provider.activeTransfers.isEmpty && provider.completedTransfers.isEmpty)
                _buildEmptyState(context, 'No recent activity')
              else
                _buildRecentActivityList(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String details,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.largePadding * 2),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, AppStateProvider provider) {
    final recentTransfers = [
      ...provider.activeTransfers,
      ...provider.completedTransfers.take(3),
    ];

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

  void _showNotConnectedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please connect to a device first'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            const CircularProgressIndicator(),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Initializing WiFi Direct...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'Initialization Failed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('WiFi File Transfer v1.0.0'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  onTap: () {},
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
}