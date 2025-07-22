import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/identity_provider.dart';
import '../../../core/providers/networking_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/chat_spaces_tab.dart';
import '../widgets/networks_tab.dart';
import '../widgets/identity_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tong Messenger'),
        actions: [
          Consumer<IdentityProvider>(
            builder: (context, identityProvider, child) {
              final identity = identityProvider.currentIdentity;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor:
                        identity?.isAnonymous == true
                            ? Colors.grey
                            : AppTheme.primaryColor,
                    child: Icon(
                      identity?.isAnonymous == true
                          ? Icons.person_outline
                          : Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  label: Text(
                    identity?.nickname ?? 'No Identity',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chat Spaces'),
            Tab(icon: Icon(Icons.network_wifi), text: 'Networks'),
            Tab(icon: Icon(Icons.person), text: 'Identity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [ChatSpacesTab(), NetworksTab(), IdentityTab()],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Chat Spaces
        return FloatingActionButton(
          onPressed: _showCreateChatSpaceDialog,
          child: const Icon(Icons.add),
        );
      case 1: // Networks
        return Consumer<NetworkingProvider>(
          builder: (context, networkingProvider, child) {
            return FloatingActionButton(
              onPressed:
                  networkingProvider.isScanning
                      ? () => networkingProvider.stopScanning()
                      : () => networkingProvider.startScanning(),
              child: Icon(
                networkingProvider.isScanning ? Icons.stop : Icons.search,
              ),
            );
          },
        );
      default:
        return null;
    }
  }

  void _showCreateChatSpaceDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateChatSpaceDialog(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class CreateChatSpaceDialog extends StatefulWidget {
  const CreateChatSpaceDialog({super.key});

  @override
  State<CreateChatSpaceDialog> createState() => _CreateChatSpaceDialogState();
}

class _CreateChatSpaceDialogState extends State<CreateChatSpaceDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedType = 'temporary';
  bool _isPublic = false;
  bool _isEncrypted = false;
  Duration _autoDeleteDuration = const Duration(hours: 24);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Chat Space'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter chat space name',
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            // Type selection
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'temporary',
                  child: Text('Temporary Group'),
                ),
                DropdownMenuItem(
                  value: 'permanent',
                  child: Text('Permanent Forum'),
                ),
                DropdownMenuItem(value: 'notice', child: Text('Notice Board')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value ?? 'temporary';
                });
              },
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            // Options
            if (_selectedType != 'notice') ...[
              SwitchListTile(
                title: const Text('Public'),
                subtitle: const Text('Allow anyone to join'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
            ],

            SwitchListTile(
              title: const Text('Encrypted'),
              subtitle: const Text('Encrypt messages'),
              value: _isEncrypted,
              onChanged: (value) {
                setState(() {
                  _isEncrypted = value;
                });
              },
            ),

            if (_isEncrypted && !_isPublic) ...[
              const SizedBox(height: AppTheme.mediumSpacing),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (Optional)',
                  hintText: 'Enter password for encrypted chat',
                ),
                obscureText: true,
              ),
            ],

            if (_selectedType == 'temporary') ...[
              const SizedBox(height: AppTheme.mediumSpacing),
              DropdownButtonFormField<Duration>(
                value: _autoDeleteDuration,
                decoration: const InputDecoration(
                  labelText: 'Auto-delete after',
                ),
                items: const [
                  DropdownMenuItem(
                    value: Duration(hours: 1),
                    child: Text('1 hour'),
                  ),
                  DropdownMenuItem(
                    value: Duration(hours: 6),
                    child: Text('6 hours'),
                  ),
                  DropdownMenuItem(
                    value: Duration(hours: 24),
                    child: Text('24 hours'),
                  ),
                  DropdownMenuItem(
                    value: Duration(days: 7),
                    child: Text('7 days'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _autoDeleteDuration = value ?? const Duration(hours: 24);
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createChatSpace,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createChatSpace() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      final name = _nameController.text.trim();
      final description =
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim();
      final password =
          _passwordController.text.trim().isEmpty
              ? null
              : _passwordController.text.trim();

      switch (_selectedType) {
        case 'temporary':
          await chatProvider.createTemporaryGroup(
            name: name,
            description: description,
            timeout: _autoDeleteDuration,
            isEncrypted: _isEncrypted,
          );
          break;
        case 'permanent':
          await chatProvider.createPermanentForum(
            name: name,
            description: description,
            isPublic: _isPublic,
            isEncrypted: _isEncrypted,
            password: password,
          );
          break;
        case 'notice':
          await chatProvider.createNoticeBoard(
            name: name,
            description: description,
            isPublic: _isPublic,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name created successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat space: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
