import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';

class MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
  final Color? color;
  
  MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.route,
    this.color,
  });
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> 
    with TickerProviderStateMixin {
      
  late AnimationController _avatarController;
  late List<AnimationController> _menuControllers;
  
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  
  List<MenuItem> get _menuItems => [
    MenuItem(
      icon: Icons.history,
      title: 'History',
      subtitle: _stats != null ? '${_analysesCount + _battlesCount} Recent' : null,
      route: '/history',
      color: Colors.blue,
    ),
    MenuItem(
      icon: Icons.library_music,
      title: 'Saved Playlists',
      subtitle: null,
      route: '/saved-playlists',
      color: Colors.yellow,
    ),
    MenuItem(
      icon: Icons.settings,
      title: 'Settings',
      route: '/settings',
      color: Colors.grey,
    ),
    MenuItem(
      icon: Icons.logout,
      title: 'Log Out',
      color: Colors.redAccent,
    ),
  ];
  
  int get _analysesCount => _stats?['analysesCount'] ?? 0;
  int get _battlesCount => _stats?['battlesCount'] ?? 0;
  int get _averageScore => ((_stats?['averageRating'] ?? _stats?['averageScore'] ?? 0) as num).toInt();
  
  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _menuControllers = List.generate(
      _menuItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    
    // Start staggered menu animations
    for (int i = 0; i < _menuControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted) _menuControllers[i].forward();
      });
    }
    
    // Fetch stats
    _fetchStats();
  }
  
  Future<void> _fetchStats() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final stats = await apiClient.getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _avatarController.dispose();
    for (final controller in _menuControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = (_analysesCount / 5).floor() + 1;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Avatar
                AnimatedBuilder(
                  animation: _avatarController,
                  builder: (context, child) {
                    final bounce = sin(_avatarController.value * 2 * pi) * 10;
                    return Transform.translate(
                      offset: Offset(0, bounce),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: AppTheme.cardBackground,
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Name and Badge
                Text(
                  'Music Explorer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Audio Explorer Lvl. $level',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontFamily: 'Space Mono',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    value: _isLoadingStats ? '...' : '$_analysesCount',
                    label: 'Analyses',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    value: _isLoadingStats ? '...' : '$_battlesCount',
                    label: 'Battles',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    value: _isLoadingStats ? '...' : '$_averageScore',
                    label: 'Avg Score',
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(_menuItems.length, (index) {
                return AnimatedBuilder(
                  animation: _menuControllers[index],
                  builder: (context, child) {
                    final slide = 20 * (1 - _menuControllers[index].value);
                    final opacity = _menuControllers[index].value;
                    
                    return Transform.translate(
                      offset: Offset(slide, 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMenuItem(
                            context,
                            _menuItems[index],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Space Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return InkWell(
      onTap: () {
        if (item.route != null) {
          context.go(item.route!);
        } else if (item.title == 'Log Out') {
          // Handle logout
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text(
                'Log Out',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: const Text(
                'Are you sure you want to log out?',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (!mounted) return;
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    navigator.pop();
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (!mounted) return;
                      context.go('/');
                    } catch (e) {
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (item.color ?? AppTheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.color ?? AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
