import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/identity_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Tong',
      description:
          'Advanced multi-network messaging with anonymous identity support',
      icon: Icons.chat_bubble_outline,
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'Anonymous Identity',
      description:
          'Choose your own nickname or use system-generated anonymous identities',
      icon: Icons.person_outline,
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      title: 'Multi-Network',
      description:
          'Connect via Internet, Bluetooth Classic, and BLE with automatic retry',
      icon: Icons.network_wifi,
      color: AppTheme.warningColor,
    ),
    OnboardingPage(
      title: 'Chat Spaces',
      description:
          'Create temporary groups, permanent forums, or notice boards',
      icon: Icons.group_work_outlined,
      color: AppTheme.errorColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.largeSpacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.xlRadius),
            ),
            child: Icon(page.icon, size: 60, color: page.color),
          ),
          const SizedBox(height: AppTheme.xlSpacing),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Text(
            page.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.largeSpacing),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _currentPage == index
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.largeSpacing),

          // Action buttons
          if (_currentPage < _pages.length - 1) ...[
            Row(
              children: [
                TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text('Skip'),
                ),
                const Spacer(),
                ElevatedButton(onPressed: _nextPage, child: const Text('Next')),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                child: const Text('Get Started'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppTheme.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: AppTheme.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const IdentitySetupScreen()),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isAnonymous = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Identity')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.largeSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Identity',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'You can stay anonymous or create a registered identity.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppTheme.xlSpacing),

            // Identity type selection
            Card(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Anonymous'),
                    subtitle: const Text(
                      'Temporary identity with optional custom nickname',
                    ),
                    value: true,
                    groupValue: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? true;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Registered'),
                    subtitle: const Text(
                      'Permanent identity with custom nickname',
                    ),
                    value: false,
                    groupValue: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.largeSpacing),

            // Nickname input
            if (!_isAnonymous || _nicknameController.text.isNotEmpty) ...[
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText:
                      _isAnonymous ? 'Custom Nickname (Optional)' : 'Nickname',
                  hintText:
                      _isAnonymous
                          ? 'Leave empty for system-generated'
                          : 'Enter your nickname',
                ),
              ),
              const SizedBox(height: AppTheme.largeSpacing),
            ],

            const Spacer(),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createIdentity,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          _isAnonymous
                              ? 'Continue Anonymously'
                              : 'Create Identity',
                        ),
              ),
            ),

            if (_isAnonymous) ...[
              const SizedBox(height: AppTheme.mediumSpacing),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : _useSystemGenerated,
                  child: const Text('Use System-Generated Nickname'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createIdentity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final identityProvider = context.read<IdentityProvider>();

      if (_isAnonymous) {
        await identityProvider.createAnonymousIdentity(
          customNickname:
              _nicknameController.text.trim().isEmpty
                  ? null
                  : _nicknameController.text.trim(),
        );
      } else {
        if (_nicknameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a nickname')),
          );
          return;
        }

        await identityProvider.createRegisteredIdentity(
          nickname: _nicknameController.text.trim(),
        );
      }

      // Mark onboarding as complete
      await context.read<AppStateProvider>().setFirstTimeComplete();

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating identity: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _useSystemGenerated() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final identityProvider = context.read<IdentityProvider>();
      await identityProvider.createAnonymousIdentity();

      // Mark onboarding as complete
      await context.read<AppStateProvider>().setFirstTimeComplete();

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating identity: $e')));
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
    _nicknameController.dispose();
    super.dispose();
  }
}
