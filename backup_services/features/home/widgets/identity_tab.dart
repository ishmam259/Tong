import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/identity_provider.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/models/user_identity.dart';
import '../../../core/theme/app_theme.dart';

class IdentityTab extends StatelessWidget {
  const IdentityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IdentityProvider>(
      builder: (context, identityProvider, child) {
        if (!identityProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Identity Section
              _buildCurrentIdentitySection(context, identityProvider),
              const SizedBox(height: AppTheme.largeSpacing),

              // Saved Identities Section
              _buildSavedIdentitiesSection(context, identityProvider),
              const SizedBox(height: AppTheme.largeSpacing),

              // Settings Section
              _buildSettingsSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentIdentitySection(
    BuildContext context,
    IdentityProvider identityProvider,
  ) {
    final currentIdentity = identityProvider.currentIdentity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Current Identity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            if (currentIdentity != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        currentIdentity.isAnonymous
                            ? Colors.grey
                            : AppTheme.primaryColor,
                    child: Icon(
                      currentIdentity.isAnonymous
                          ? Icons.person_outline
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentIdentity.nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentIdentity.isAnonymous
                              ? 'Anonymous'
                              : 'Registered',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (currentIdentity.isSystemGenerated) ...[
                          const Text(
                            'System Generated',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Session info
              Container(
                padding: const EdgeInsets.all(AppTheme.smallSpacing),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ID: ${currentIdentity.sessionId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Type: ${currentIdentity.isPermanentSession ? "Permanent" : "Temporary"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Created: ${_formatDate(currentIdentity.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => _showEditNicknameDialog(
                            context,
                            identityProvider,
                          ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Nickname'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => identityProvider.regenerateSession(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('New Session'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey),
                    SizedBox(height: AppTheme.smallSpacing),
                    Text('No active identity'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavedIdentitiesSection(
    BuildContext context,
    IdentityProvider identityProvider,
  ) {
    final savedIdentities = identityProvider.savedIdentities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Saved Identities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showCreateIdentityDialog(context),
                  child: const Text('Create New'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            if (savedIdentities.isEmpty) ...[
              const Center(
                child: Text(
                  'No saved identities',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else ...[
              ...savedIdentities.map(
                (identity) => SavedIdentityTile(
                  identity: identity,
                  isCurrentIdentity:
                      identityProvider.currentIdentity?.id == identity.id,
                  onSwitch: () => identityProvider.switchToIdentity(identity),
                  onDelete: () => identityProvider.deleteIdentity(identity.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Theme'),
                      subtitle: Text(_getThemeModeText(appState.themeMode)),
                      trailing: DropdownButton<ThemeMode>(
                        value: appState.themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            appState.setThemeMode(value);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  void _showEditNicknameDialog(
    BuildContext context,
    IdentityProvider identityProvider,
  ) {
    final controller = TextEditingController(
      text: identityProvider.currentIdentity?.nickname ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Nickname'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'Enter new nickname',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    identityProvider.updateNickname(controller.text.trim());
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showCreateIdentityDialog(BuildContext context) {
    // TODO: Implement create identity dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create identity dialog not implemented yet'),
      ),
    );
  }
}

class SavedIdentityTile extends StatelessWidget {
  final UserIdentity identity;
  final bool isCurrentIdentity;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  const SavedIdentityTile({
    super.key,
    required this.identity,
    required this.isCurrentIdentity,
    required this.onSwitch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentIdentity ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isCurrentIdentity ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              identity.isAnonymous ? Colors.grey : AppTheme.primaryColor,
          child: Icon(
            identity.isAnonymous ? Icons.person_outline : Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          identity.nickname,
          style: TextStyle(
            fontWeight: isCurrentIdentity ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${identity.isAnonymous ? "Anonymous" : "Registered"} • Created ${_formatDate(identity.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing:
            isCurrentIdentity
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onSwitch,
                      icon: const Icon(Icons.login, size: 20),
                      tooltip: 'Switch to this identity',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      tooltip: 'Delete identity',
                    ),
                  ],
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
