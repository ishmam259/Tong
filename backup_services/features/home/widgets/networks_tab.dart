import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/networking_provider.dart';
import '../../../core/models/network_connection.dart';
import '../../../core/theme/app_theme.dart';

class NetworksTab extends StatelessWidget {
  const NetworksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkingProvider>(
      builder: (context, networkingProvider, child) {
        return Column(
          children: [
            // Connection status header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        networkingProvider.hasActiveConnection
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color:
                            networkingProvider.hasActiveConnection
                                ? AppTheme.successColor
                                : Colors.grey,
                      ),
                      const SizedBox(width: AppTheme.smallSpacing),
                      Text(
                        networkingProvider.hasActiveConnection
                            ? 'Connected'
                            : 'Not Connected',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (networkingProvider.primaryConnection != null) ...[
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Primary: ${networkingProvider.primaryConnection!.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            // Scanning indicator
            if (networkingProvider.isScanning) ...[
              const LinearProgressIndicator(),
              const Padding(
                padding: EdgeInsets.all(AppTheme.smallSpacing),
                child: Text(
                  'Scanning for devices...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],

            // Connections list
            Expanded(
              child:
                  networkingProvider.connections.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                            SizedBox(height: AppTheme.mediumSpacing),
                            Text(
                              'No networks found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: AppTheme.smallSpacing),
                            Text(
                              'Tap the scan button to search for devices',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: networkingProvider.connections.length,
                        itemBuilder: (context, index) {
                          final connection =
                              networkingProvider.connections[index];
                          return NetworkConnectionCard(connection: connection);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

class NetworkConnectionCard extends StatelessWidget {
  final NetworkConnection connection;

  const NetworkConnectionCard({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          connection.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(connection.address, style: const TextStyle(fontSize: 12)),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(context),
            const SizedBox(width: AppTheme.smallSpacing),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                    if (connection.status == ConnectionStatus.failed) ...[
                      const PopupMenuItem(
                        value: 'retry',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 16),
                            SizedBox(width: 8),
                            Text('Retry'),
                          ],
                        ),
                      ),
                    ],
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color color;

    switch (connection.type) {
      case NetworkType.internet:
        iconData = Icons.language;
        color = Colors.blue;
        break;
      case NetworkType.bluetooth:
        iconData = Icons.bluetooth;
        color = Colors.indigo;
        break;
      case NetworkType.ble:
        iconData = Icons.bluetooth_connected;
        color = Colors.purple;
        break;
      case NetworkType.local:
        iconData = Icons.wifi;
        color = Colors.green;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (connection.status) {
      case ConnectionStatus.disconnected:
      case ConnectionStatus.failed:
        return ElevatedButton(
          onPressed: () => _connect(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Connect'),
        );
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 80,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case ConnectionStatus.connected:
        return ElevatedButton(
          onPressed: () => _disconnect(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Disconnect'),
        );
      case ConnectionStatus.reconnecting:
        return const SizedBox(
          width: 80,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
    }
  }

  String _getStatusText() {
    switch (connection.status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.failed:
        return 'Failed (${connection.retryCount} retries)';
    }
  }

  Color _getStatusColor() {
    switch (connection.status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return AppTheme.successColor;
      case ConnectionStatus.failed:
        return AppTheme.errorColor;
    }
  }

  void _connect(BuildContext context) {
    context.read<NetworkingProvider>().connectTo(connection);
  }

  void _disconnect(BuildContext context) {
    context.read<NetworkingProvider>().disconnect(connection);
  }

  void _handleMenuAction(BuildContext context, String action) {
    final networkingProvider = context.read<NetworkingProvider>();

    switch (action) {
      case 'remove':
        networkingProvider.removeConnection(connection.id);
        break;
      case 'retry':
        networkingProvider.connectTo(connection);
        break;
    }
  }
}
