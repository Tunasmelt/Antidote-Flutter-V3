import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AnimationController> _itemControllers = [];
  
  bool _notifications = true;
  bool _darkMode = true;
  bool _haptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSettings();
    _controller.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('settings_notifications') ?? true;
      _darkMode = prefs.getBool('settings_darkMode') ?? true;
      _haptic = prefs.getBool('settings_haptic') ?? false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_$key', value);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var itemController in _itemControllers) {
      itemController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: () => context.go('/profile'),
                    icon: Icon(Icons.arrow_back, size: 16, color: AppTheme.mutedColor),
                    label: Text(
                      'Back to Profile',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  FadeTransition(
                    opacity: _controller,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOut,
                      )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: AppTheme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your preferences',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedColor,
                              fontFamily: 'SpaceMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Account Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'ACCOUNT',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: ref.read(authServiceProvider).isSpotifyConnected(),
                    builder: (context, snapshot) {
                      final isConnected = snapshot.data ?? false;
                      return _buildSettingItem(
                        icon: Icons.music_note,
                        label: 'Spotify Connection',
                        value: isConnected ? 'Connected' : 'Not Connected',
                        type: 'link',
                        onTap: () => _handleSpotifyConnection(context, isConnected),
                        index: 0,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Preferences Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'PREFERENCES',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    value: _notifications,
                    type: 'switch',
                    onChanged: (value) {
                      setState(() => _notifications = value);
                      _updateSetting('notifications', value);
                    },
                    index: 1,
                  ),
                  const SizedBox(height: 8),
                  _buildSettingItem(
                    icon: Icons.palette,
                    label: 'Dark Mode',
                    value: _darkMode,
                    type: 'switch',
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      _updateSetting('darkMode', value);
                    },
                    index: 2,
                  ),
                  const SizedBox(height: 8),
                  _buildSettingItem(
                    icon: Icons.phone_android,
                    label: 'Haptic Feedback',
                    value: _haptic,
                    type: 'switch',
                    onChanged: (value) {
                      setState(() => _haptic = value);
                      _updateSetting('haptic', value);
                    },
                    index: 3,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Log Out Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildLogOutButton(),
                  const SizedBox(height: 16),
                  Text(
                    'Antidote v3.0.0 (Build 2025)',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedColor,
                      fontSize: 10,
                      fontFamily: 'SpaceMono',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSpotifyConnection(BuildContext context, bool isConnected) async {
    try {
      final authService = ref.read(authServiceProvider);
      
      if (isConnected) {
        // Show disconnect confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Disconnect Spotify',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to disconnect Spotify? You will need to reconnect to use Spotify features.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Disconnect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await authService.disconnectSpotify();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Spotify disconnected'),
                backgroundColor: AppTheme.cardBackground,
              ),
            );
            setState(() {}); // Refresh UI
          }
        }
      } else {
        // Connect Spotify
        await authService.connectSpotify();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spotify connected successfully'),
              backgroundColor: AppTheme.cardBackground,
            ),
          );
          setState(() {}); // Refresh UI
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isConnected ? 'disconnect' : 'connect'} Spotify: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required dynamic value,
    required String type,
    required int index,
    Function(bool)? onChanged,
    VoidCallback? onTap,
  }) {
    // Create animation controller for this item
    if (index >= _itemControllers.length) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _itemControllers.add(controller);
      Future.delayed(
        Duration(milliseconds: 100 + (index * 100)),
        () => controller.forward(),
      );
    }
    
    final itemController = _itemControllers[index];
    
    return FadeTransition(
      opacity: itemController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: itemController,
          curve: Curves.easeOut,
        )),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: type == 'link' ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.mutedColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (type == 'switch')
                    Switch(
                      value: value as bool,
                      onChanged: onChanged,
                      activeThumbColor: AppTheme.primaryColor,
                    )
                  else
                    Row(
                      children: [
                        if (value != null)
                          Text(
                            value.toString(),
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: value.toString() == 'Connected' 
                                ? const Color(0xFF1DB954)
                                : AppTheme.mutedColor,
                              fontSize: 12,
                              fontWeight: value.toString() == 'Connected' 
                                ? FontWeight.bold
                                : FontWeight.normal,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.mutedColor,
                          size: 16,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton() {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (mounted) {
                  context.go('/auth');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red.shade400,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

