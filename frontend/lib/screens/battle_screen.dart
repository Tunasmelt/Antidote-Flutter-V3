import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';
import '../models/battle.dart';
import '../providers/battle_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_radar_chart.dart';
import '../widgets/spotify_connect_prompt.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton_loader.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  final TextEditingController _url1Controller = TextEditingController();
  final TextEditingController _url2Controller = TextEditingController();

  late AnimationController _vsController;
  late AnimationController _resultController;
  late AnimationController _compatibilityController;

  int _displayCompatibility = 0;
  bool _resultsReady = false;
  Timer? _compatibilityTimer;
  final Set<int> _selectedTracks =
      {}; // Track indices for "Add from Other Playlist"

  // URL validation regex patterns
  static final _spotifyPlaylistRegex = RegExp(
    r'^(https?://)?open\.spotify\.com/(playlist|user/[^/]+/playlist)/[a-zA-Z0-9]+',
  );
  static final _spotifyUriRegex = RegExp(
    r'^spotify:(playlist|user:[^:]+:playlist):[a-zA-Z0-9]+$',
  );
  static final _appleMusicRegex = RegExp(
    r'^(https?://)?music\.apple\.com/[a-z]{2}/playlist/[^/]+/pl\.[a-z0-9]+',
  );

  bool _isValidPlaylistUrl(String url) {
    return _spotifyPlaylistRegex.hasMatch(url) ||
        _spotifyUriRegex.hasMatch(url) ||
        _appleMusicRegex.hasMatch(url);
  }

  @override
  void initState() {
    super.initState();
    _vsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _resultController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _compatibilityController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _url1Controller.dispose();
    _url2Controller.dispose();
    _vsController.dispose();
    _resultController.dispose();
    _compatibilityController.dispose();
    _compatibilityTimer?.cancel();
    super.dispose();
  }

  void _startBattle() {
    final url1 = _url1Controller.text.trim();
    final url2 = _url2Controller.text.trim();

    if (url1.isEmpty || url2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both playlist URLs'),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
      return;
    }

    // Validate URLs with regex patterns
    final isValidUrl1 = _isValidPlaylistUrl(url1);
    final isValidUrl2 = _isValidPlaylistUrl(url2);

    if (!isValidUrl1 || !isValidUrl2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter valid Spotify or Apple Music playlist URLs'),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
      return;
    }

    ref.read(battleNotifierProvider.notifier).battlePlaylists(url1, url2);
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleNotifierProvider);

    // Animate compatibility score when results arrive
    battleState.whenData((battle) {
      if (battle != null && !_resultsReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _resultsReady = true);
          _resultController.forward();
          _compatibilityController.forward();

          // Animate compatibility score counter
          final target = battle.compatibilityScore;
          _compatibilityTimer?.cancel();
          _compatibilityTimer =
              Timer.periodic(const Duration(milliseconds: 30), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            setState(() {
              _displayCompatibility = min(target, _displayCompatibility + 2);
            });
            if (_displayCompatibility >= target) {
              timer.cancel();
            }
          });
        });
      }
    });

    return battleState.when(
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(error),
      data: (battle) =>
          battle == null ? _buildInputView() : _buildResultView(battle),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const BattleComparisonSkeleton(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Battling Playlists...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    // Check for specific error types
    final errorString = error.toString().toLowerCase();
    final isTokenError = errorString.contains('token') ||
        errorString.contains('spotify') && errorString.contains('required') ||
        errorString.contains('token_expired') ||
        errorString.contains('token_required');

    // Show Spotify connect prompt if it's a token error
    if (isTokenError) {
      return SpotifyConnectPrompt(
        message:
            'Connect your Spotify account to battle playlists and discover which one has better vibes',
        onConnected: () {
          // Retry battle after connecting
          _startBattle();
        },
      );
    }

    return ErrorView(
      error: error,
      onRetry: () {
        _compatibilityTimer?.cancel();
        ref.invalidate(battleNotifierProvider);
        setState(() {
          _resultsReady = false;
          _displayCompatibility = 0;
        });
      },
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Header
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: AppTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Playlist Battle',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compare two playlists head-to-head',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Input Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Contender 1
                Row(
                  children: [
                    Text(
                      'Contender 1',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _url1Controller,
                  decoration: InputDecoration(
                    hintText: 'Paste first playlist URL...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Space Mono',
                  ),
                ),

                const SizedBox(height: 24),

                // VS Badge
                Center(
                  child: AnimatedBuilder(
                    animation: _vsController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _vsController.value * 2 * pi,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VS',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Contender 2
                Row(
                  children: [
                    Text(
                      'Contender 2',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _url2Controller,
                  decoration: InputDecoration(
                    hintText: 'Paste second playlist URL...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Space Mono',
                  ),
                ),

                const SizedBox(height: 32),

                // Start Battle Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startBattle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'START BATTLE',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                Container(
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
                      const Icon(
                        Icons.emoji_events,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Winner Takes All\nAI analyzes energy curves, genre overlap & compatibility.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResultView(BattleResult battle) {
    // Transform audio data for dual radar chart
    // Backend returns: [{playlist: 'playlist1', energy: 0.8, ...}, {playlist: 'playlist2', energy: 0.6, ...}]
    // Frontend needs: [{subject: 'energy', A: 0.8, B: 0.6}, ...]
    Map<String, dynamic> playlist1Obj = <String, dynamic>{};
    Map<String, dynamic> playlist2Obj = <String, dynamic>{};

    if (battle.audioData.isNotEmpty) {
      try {
        playlist1Obj = battle.audioData.firstWhere(
          (data) => data['playlist'] == 'playlist1',
          orElse: () => <String, dynamic>{},
        );
        playlist2Obj = battle.audioData.firstWhere(
          (data) => data['playlist'] == 'playlist2',
          orElse: () => <String, dynamic>{},
        );
      } catch (e) {
        // Fallback to empty objects if parsing fails
        playlist1Obj = <String, dynamic>{};
        playlist2Obj = <String, dynamic>{};
      }
    }

    // Create radar data from audio features
    final audioFeatures = ['energy', 'danceability', 'valence', 'acousticness'];
    final playlist1Data = audioFeatures.map((feature) {
      final value = (playlist1Obj[feature] ?? 0.0) as double;
      return RadarData(
        label: feature.substring(0, 1).toUpperCase() + feature.substring(1),
        value: value.clamp(0.0, 1.0),
      );
    }).toList();

    final playlist2Data = audioFeatures.map((feature) {
      final value = (playlist2Obj[feature] ?? 0.0) as double;
      return RadarData(
        label: feature.substring(0, 1).toUpperCase() + feature.substring(1),
        value: value.clamp(0.0, 1.0),
      );
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom +
            80, // Bottom nav + safe area
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    _compatibilityTimer?.cancel();
                    ref.invalidate(battleNotifierProvider);
                    _url1Controller.clear();
                    _url2Controller.clear();
                    setState(() {
                      _resultsReady = false;
                      _displayCompatibility = 0;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textMuted,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Battle Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Compatibility Analysis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _compatibilityController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withValues(alpha: 0.4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Compatibility Analysis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_displayCompatibility%',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Space Mono',
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCompatibilityDescription(battle.compatibilityScore),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Winner Declaration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _resultController,
              builder: (context, child) {
                final opacity = _resultController.value;
                final scale = 0.8 + (0.2 * _resultController.value);

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _getWinnerColor(battle.winner)
                            .withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getWinnerColor(battle.winner)
                              .withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: _getWinnerColor(battle.winner),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getWinnerText(battle.winner),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getWinnerReason(battle),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Playlist Score Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildPlaylistScoreCard(
                    battle.playlist1,
                    isWinner: battle.winner == 'playlist1',
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlaylistScoreCard(
                    battle.playlist2,
                    isWinner: battle.winner == 'playlist2',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Shared Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Shared Artists
                Container(
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
                          Text(
                            '${battle.sharedArtists.length}',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Space Mono',
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Artists',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                          ),
                        ],
                      ),
                      if (battle.sharedArtists.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.cardBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children:
                                battle.sharedArtists.take(3).map((artist) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        artist,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Shared Genres
                Container(
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
                          Text(
                            '${battle.sharedGenres.length}',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Space Mono',
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Genres',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                          ),
                        ],
                      ),
                      if (battle.sharedGenres.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: battle.sharedGenres.take(6).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                border: Border.all(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                genre,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                    ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Shared Tracks
                Container(
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
                      Text(
                        'Shared Tracks (${battle.sharedTracks.length})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                      ),
                      if (battle.sharedTracks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...battle.sharedTracks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final track = entry.value;
                          final isSelected = _selectedTracks.contains(index);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.secondary.withValues(alpha: 0.2)
                                  : AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.secondary
                                          .withValues(alpha: 0.5),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedTracks.add(index);
                                      } else {
                                        _selectedTracks.remove(index);
                                      }
                                    });
                                  },
                                  activeColor: AppTheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${track.title} - ${track.artist}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textPrimary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Combined Audio DNA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Combined Audio DNA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: DualRadarChart(
                    playlist1Data: playlist1Data,
                    playlist2Data: playlist2Data,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectedTracks.isEmpty
                            ? null
                            : () => _createMergedPlaylist(context, battle),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selectedTracks.isEmpty
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppTheme.secondary.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _selectedTracks.isEmpty
                              ? 'Select Tracks'
                              : 'Create Merged (${_selectedTracks.length})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _selectedTracks.isEmpty
                                        ? AppTheme.textMuted
                                        : AppTheme.secondary,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Share results
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Share Results',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final isAuthenticated = ref.watch(isAuthenticatedProvider);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          if (isAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Battle automatically saved to your history'),
                                backgroundColor: AppTheme.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Sign in to save your battle results'),
                                backgroundColor: AppTheme.cardBackground,
                                action: SnackBarAction(
                                  label: 'Sign In',
                                  textColor: AppTheme.primary,
                                  onPressed: () {
                                    context.push('/auth');
                                  },
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isAuthenticated
                                ? AppTheme.success.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAuthenticated
                                  ? Icons.check_circle
                                  : Icons.download,
                              size: 16,
                              color: isAuthenticated
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAuthenticated
                                  ? 'Saved to History'
                                  : 'Save Battle',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isAuthenticated
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlaylistScoreCard(
    BattlePlaylist playlist, {
    required bool isWinner,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, child) {
        final scale = 0.9 + (0.1 * _resultController.value);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.3),
              border: Border.all(
                color: isWinner
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
                width: isWinner ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: playlist.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: playlist.image!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.cardBackground,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.cardBackground,
                          child: const Icon(
                            Icons.music_note,
                            color: AppTheme.textMuted,
                          ),
                        ),
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Owner
                Text(
                  playlist.owner,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${playlist.score}/100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Space Mono',
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCompatibilityDescription(int score) {
    if (score >= 80) {
      return 'Highly compatible playlists with strong musical synergy.';
    }
    if (score >= 60) {
      return 'Decent compatibility with some shared musical DNA.';
    }
    if (score >= 40) {
      return 'Moderate compatibility - different but not opposing styles.';
    }
    return 'Low compatibility - quite different musical approaches.';
  }

  Color _getWinnerColor(String winner) {
    if (winner == 'tie') {
      return AppTheme.secondary;
    }
    return AppTheme.warning;
  }

  String _getWinnerText(String winner) {
    if (winner == 'tie') {
      return 'Perfect Tie!';
    }
    if (winner == 'playlist1') {
      return 'Contender 1 Wins!';
    }
    if (winner == 'playlist2') return 'Contender 2 Wins!';
    return 'Battle Complete';
  }

  String _getWinnerReason(BattleResult battle) {
    if (battle.winner == 'tie') return 'Both playlists are perfectly balanced!';
    return 'Higher overall score and better musical cohesion.';
  }

  Future<void> _createMergedPlaylist(
      BuildContext context, BattleResult battle) async {
    if (_selectedTracks.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );

    try {
      // Get selected track IDs (assuming shared tracks have spotify IDs)
      // For now, we'll use track titles as identifiers
      final selectedTracks = _selectedTracks.map((index) {
        return battle.sharedTracks[index];
      }).toList();

      // Note: This requires backend support for creating playlists from track names
      // For now, show a message
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Creating playlist with ${selectedTracks.length} tracks...'),
            backgroundColor: AppTheme.cardBackground,
            duration: const Duration(seconds: 2),
          ),
        );

        // Note: Playlist creation requires backend support for creating playlists from track names
        // For now, show success message
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Playlist creation feature coming soon!'),
                backgroundColor: AppTheme.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create playlist: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
