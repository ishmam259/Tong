import 'package:flutter/material.dart';
import 'dart:io';

class UnsupportedPlatformScreen extends StatelessWidget {
  const UnsupportedPlatformScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentPlatform = 'Unknown';
    if (Platform.isLinux) currentPlatform = 'Linux';
    if (Platform.isMacOS) currentPlatform = 'macOS';
    if (Platform.isFuchsia) currentPlatform = 'Fuchsia';

    return MaterialApp(
      title: 'Tong - Unsupported Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange[600],
                ),
                const SizedBox(height: 24),
                Text(
                  'Platform Not Supported',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tong Messenger is currently running on $currentPlatform',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Supported Platforms',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _buildPlatformItem(context, Icons.android, 'Android'),
                        _buildPlatformItem(context, Icons.apple, 'iOS'),
                        _buildPlatformItem(
                          context,
                          Icons.laptop_windows,
                          'Windows',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Please use Tong Messenger on one of the supported platforms for the best experience.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => exit(0),
                  icon: const Icon(Icons.close),
                  label: const Text('Close App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformItem(BuildContext context, IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
