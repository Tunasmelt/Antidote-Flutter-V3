import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/taste_profile_provider.dart';
import '../providers/enhanced_taste_profile_provider.dart';
import '../widgets/spotify_playlist_item.dart';
import '../services/auth_service.dart';

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
  List<Map<String, dynamic>> _spotifyPlaylists = [];
  bool _isLoadingPlaylists = false;
  bool _spotifyConnected = false;

  List<MenuItem> get _menuItems => [
        MenuItem(
          icon: Icons.history,
          title: 'History',
          subtitle: _stats != null
              ? '${_analysesCount + _battlesCount} Recent'
              : null,
          route: '/history',
          color: Colors.blue,
        ),
        MenuItem(
          icon: Icons.favorite,
          title: 'Liked Tracks',
          subtitle: null,
          route: '/liked-tracks',
          color: Colors.pink,
        ),
        MenuItem(
          icon: Icons.library_music,
          title: 'Saved Playlists',
          subtitle: null,
          route: '/saved-playlists',
          color: Colors.yellow,
        ),
        MenuItem(
          icon: Icons.mood,
          title: 'Mood Discovery',
          subtitle: 'Discover your current mood',
          route: '/mood-discovery',
          color: Colors.purple,
        ),
        MenuItem(
          icon: Icons.playlist_add,
          title: 'Playlist Generator',
          subtitle: 'AI-powered playlist creation',
          route: '/playlist-generator',
          color: Colors.orange,
        ),
        MenuItem(
          icon: Icons.timeline,
          title: 'Discovery Timeline',
          subtitle: 'Your music journey',
          route: '/discovery-timeline',
          color: Colors.teal,
        ),
        MenuItem(
          icon: Icons.music_note,
          title: 'Top Tracks',
          subtitle: 'Your most played tracks',
          route: '/top-tracks',
          color: Colors.blue,
        ),
        MenuItem(
          icon: Icons.person,
          title: 'Top Artists',
          subtitle: 'Your favorite artists',
          route: '/top-artists',
          color: Colors.purple,
        ),
        MenuItem(
          icon: Icons.history,
          title: 'Recently Played',
          subtitle: 'Your listening history',
          route: '/recently-played',
          color: Colors.orange,
        ),
        MenuItem(
          icon: Icons.favorite,
          title: 'Saved Tracks',
          subtitle: 'Your Spotify saved tracks',
          route: '/saved-tracks',
          color: Colors.red,
        ),
        MenuItem(
          icon: Icons.album,
          title: 'Saved Albums',
          subtitle: 'Your Spotify saved albums',
          route: '/saved-albums',
          color: Colors.green,
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
  int get _savedPlaylistsCount => _stats?['savedPlaylistsCount'] ?? 0;
  double get _averageRating =>
      ((_stats?['averageRating'] ?? 0) as num).toDouble();
  double get _averageHealthScore =>
      ((_stats?['averageHealthScore'] ?? 0) as num).toDouble();
  String? get _lastAnalysisAt => _stats?['lastAnalysisAt']?.toString();

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

    // Start staggered menu animations with mounted check
    for (int i = 0; i < _menuControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted && i < _menuControllers.length) {
          _menuControllers[i].forward();
        }
      });
    }

    // Fetch stats
    _fetchStats();

    // Check Spotify connection and fetch playlists
    _checkSpotifyAndFetchPlaylists();
  }

  Future<void> _checkSpotifyAndFetchPlaylists() async {
    try {
      final authService = AuthService();
      final isConnected = await authService.isSpotifyConnected();

      if (mounted) {
        setState(() {
          _spotifyConnected = isConnected;
        });
      }

      if (isConnected) {
        await _fetchSpotifyPlaylists();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _fetchSpotifyPlaylists() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final playlists = await apiClient.getUserSpotifyPlaylists();

      if (mounted) {
        setState(() {
          _spotifyPlaylists = playlists;
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      // Handle errors gracefully - token expired, not connected, etc.
      if (mounted) {
        setState(() {
          _isLoadingPlaylists = false;
          // Keep existing playlists if error occurs (don't clear them)
          // Only clear if it's a token error that requires reconnection
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('token') &&
              (errorString.contains('expired') ||
                  errorString.contains('required'))) {
            // Token issue - mark as not connected
            _spotifyConnected = false;
          }
        });
      }
    }
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom +
            80, // Bottom nav + safe area
      ),
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
            child: Column(
              children: [
                Row(
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
                        value:
                            _isLoadingStats ? '...' : '$_savedPlaylistsCount',
                        label: 'Saved',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        value: _isLoadingStats
                            ? '...'
                            : _averageRating > 0
                                ? _averageRating.toStringAsFixed(1)
                                : '0',
                        label: 'Avg Rating',
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        value: _isLoadingStats
                            ? '...'
                            : _averageHealthScore > 0
                                ? _averageHealthScore.toStringAsFixed(0)
                                : '0',
                        label: 'Health',
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        value: _isLoadingStats
                            ? '...'
                            : _lastAnalysisAt != null
                                ? _formatDate(_lastAnalysisAt!)
                                : 'Never',
                        label: 'Last Analysis',
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Enhanced Taste Profile Section
          Consumer(
            builder: (context, ref, child) {
              final enhancedProfileState =
                  ref.watch(enhancedTasteProfileProvider);
              final oldProfileState = ref.watch(tasteProfileProvider);

              return enhancedProfileState.when(
                loading: () => oldProfileState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    if (profile.totalPlaylistsAnalyzed == 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildTasteProfileSection(context, profile),
                    );
                  },
                ),
                error: (_, __) => oldProfileState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    if (profile.totalPlaylistsAnalyzed == 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildTasteProfileSection(context, profile),
                    );
                  },
                ),
                data: (enhancedProfile) {
                  if (enhancedProfile == null) {
                    // Fallback to old profile
                    return oldProfileState.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (profile) {
                        if (profile.totalPlaylistsAnalyzed == 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTasteProfileSection(context, profile),
                        );
                      },
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildEnhancedTasteProfileSection(
                        context, enhancedProfile),
                  );
                },
              );
            },
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

          // Spotify Playlists Section
          if (_spotifyConnected) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.library_music,
                          color: Color(0xFF1DB954),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'My Spotify Playlists',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (_isLoadingPlaylists)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: _fetchSpotifyPlaylists,
                          tooltip: 'Refresh playlists',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingPlaylists && _spotifyPlaylists.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    )
                  else if (_spotifyPlaylists.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.music_off,
                            color: AppTheme.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No playlists found',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create playlists in Spotify to see them here',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_spotifyPlaylists
                        .take(10)
                        .map((playlist) => SpotifyPlaylistItem(
                              playlist: playlist,
                            ))),
                  if (_spotifyPlaylists.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Showing 10 of ${_spotifyPlaylists.length} playlists',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Color(0xFF1DB954),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect Spotify',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View and analyze your Spotify playlists',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text(
                        'Connect',
                        style: TextStyle(color: Color(0xFF1DB954)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

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
                    final currentContext = context;
                    navigator.pop();
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (!mounted) return;
                      if (currentContext.mounted) {
                        currentContext.go('/');
                      }
                    } catch (e) {
                      if (!mounted) return;
                      if (currentContext.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Logout failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  Widget _buildEvolutionCard(
      BuildContext context, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontFamily: 'Space Mono',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBreakdown(
      BuildContext context, Map<String, dynamic> sources) {
    final topTracks = sources['topTracks'] as Map<String, dynamic>?;
    final topArtists = sources['topArtists'] as Map<String, dynamic>?;
    final recentlyPlayed = sources['recentlyPlayed'] as num?;
    final savedTracks = sources['savedTracks'] as num?;
    final analyzedPlaylists = sources['analyzedPlaylists'] as num?;

    return Column(
      children: [
        if (topTracks != null)
          _buildSourceItem(context, 'Top Tracks',
              'Short: ${topTracks['short']}, Medium: ${topTracks['medium']}, Long: ${topTracks['long']}'),
        if (topArtists != null)
          _buildSourceItem(context, 'Top Artists',
              'Short: ${topArtists['short']}, Medium: ${topArtists['medium']}, Long: ${topArtists['long']}'),
        if (recentlyPlayed != null)
          _buildSourceItem(
              context, 'Recently Played', '$recentlyPlayed tracks'),
        if (savedTracks != null)
          _buildSourceItem(context, 'Saved Tracks', '$savedTracks tracks'),
        if (analyzedPlaylists != null)
          _buildSourceItem(
              context, 'Analyzed Playlists', '$analyzedPlaylists playlists'),
      ],
    );
  }

  Widget _buildEnhancedTasteProfileSection(
      BuildContext context, Map<String, dynamic> enhancedProfile) {
    final topGenres =
        (enhancedProfile['topGenres'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final topArtists = (enhancedProfile['topArtists'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final listeningEvolution =
        enhancedProfile['listeningEvolution'] as Map<String, dynamic>?;
    final sources = enhancedProfile['sources'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Taste Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (sources != null)
                      Text(
                        'Multi-source analysis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontFamily: 'Space Mono',
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Genres
          if (topGenres.isNotEmpty) ...[
            Text(
              'Top Genres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topGenres.take(8).map((genre) {
                final name = genre['name']?.toString() ?? 'Unknown';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Top Artists
          if (topArtists.isNotEmpty) ...[
            Text(
              'Top Artists',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topArtists.take(8).map((artist) {
                final name = artist['name']?.toString() ?? 'Unknown';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Listening Evolution
          if (listeningEvolution != null) ...[
            Text(
              'Listening Evolution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEvolutionCard(
                    context,
                    'New Genres',
                    (listeningEvolution['newGenres'] as List?)?.length ?? 0,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEvolutionCard(
                    context,
                    'Evolving',
                    (listeningEvolution['evolvingGenres'] as List?)?.length ??
                        0,
                    AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEvolutionCard(
                    context,
                    'Short-term',
                    (listeningEvolution['shortTermCount'] as num?)?.toInt() ??
                        0,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEvolutionCard(
                    context,
                    'Long-term',
                    (listeningEvolution['longTermCount'] as num?)?.toInt() ?? 0,
                    AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Sources Breakdown
          if (sources != null) ...[
            Text(
              'Data Sources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSourceBreakdown(context, sources),
          ],

          // Listening Personality Button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showListeningPersonality(context),
              icon: const Icon(Icons.psychology, size: 18),
              label: const Text('View Listening Personality'),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showListeningPersonality(BuildContext context) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final personality = await apiClient.getListeningPersonality();

      if (!mounted) return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Listening Personality',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          content: SingleChildScrollView(
            child: _buildPersonalityContent(context, personality),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load personality: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildPersonalityContent(
      BuildContext context, Map<String, dynamic> personality) {
    final type = personality['personality']?['type'] as String?;
    final description = personality['personality']?['description'] as String?;
    final comparison = personality['comparison'] as Map<String, dynamic>?;
    final genreOverlap =
        (comparison?['genreOverlap'] as num?)?.toDouble() ?? 0.0;
    final divergence = (comparison?['divergence'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (type != null) ...[
          Text(
            type,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (description != null) ...[
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 16),
        ],
        if (comparison != null) ...[
          Text(
            'Comparison',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildComparisonBar(context, 'Genre Overlap', genreOverlap),
          const SizedBox(height: 8),
          _buildComparisonBar(context, 'Divergence', divergence),
        ],
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildComparisonBar(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Space Mono',
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTasteProfileSection(BuildContext context, dynamic profile) {
    final topGenres = profile.topGenresSorted.take(5).toList();
    final topArtists = profile.topArtistsSorted.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taste Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${profile.totalPlaylistsAnalyzed} ${profile.totalPlaylistsAnalyzed == 1 ? 'playlist' : 'playlists'} analyzed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontFamily: 'Space Mono',
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (topGenres.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Top Genres',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
            ...topGenres.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondary,
                            fontFamily: 'Space Mono',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (topArtists.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Top Artists',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
            ...topArtists.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontFamily: 'Space Mono',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
