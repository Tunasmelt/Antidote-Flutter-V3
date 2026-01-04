import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';
import '../models/analysis.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/api_client_provider.dart';
import '../widgets/animated_radar_chart.dart';
import '../widgets/genre_distribution_bars.dart';
import '../widgets/spotify_connect_prompt.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton_loader.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String? playlistUrl;

  const AnalysisScreen({super.key, this.playlistUrl});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  bool _showSuccessAnimation = false;
  Map<String, dynamic>? _optimizationData;
  bool _isLoadingOptimization = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Trigger analysis if URL is provided
    if (widget.playlistUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(analysisNotifierProvider.notifier)
            .analyzePlaylist(widget.playlistUrl!);
      });
    }
  }

  Future<void> _optimizePlaylist() async {
    if (widget.playlistUrl == null) return;

    setState(() {
      _isLoadingOptimization = true;
      _optimizationData = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.optimizePlaylist(url: widget.playlistUrl);

      if (mounted) {
        setState(() {
          _optimizationData = result;
          _isLoadingOptimization = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOptimization = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to optimize playlist: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisNotifierProvider);

    // Show success animation when analysis completes
    if (analysisState.hasValue &&
        analysisState.value != null &&
        !_showSuccessAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showSuccessAnimation = true);
        _successController.forward();
      });
    }

    return analysisState.when(
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(error),
      data: (analysis) =>
          analysis == null ? _buildEmptyView() : _buildAnalysisView(analysis),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const AnalysisCardSkeleton(),
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
                  'Analyzing Playlist...',
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
            'Connect your Spotify account to analyze playlists and discover insights about your music',
        onConnected: () {
          // Retry analysis after connecting
          if (widget.playlistUrl != null) {
            ref
                .read(analysisNotifierProvider.notifier)
                .analyzePlaylist(widget.playlistUrl!);
          }
        },
      );
    }

    return ErrorView(
      error: error,
      onRetry: widget.playlistUrl != null
          ? () {
              ref
                  .read(analysisNotifierProvider.notifier)
                  .analyzePlaylist(widget.playlistUrl!);
            }
          : null,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No playlist URL provided.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisView(PlaylistAnalysis analysis) {
    // Transform audio DNA for radar chart
    final radarData = [
      RadarData(label: 'Energy', value: analysis.audioDna.energy / 100),
      RadarData(label: 'Dance', value: analysis.audioDna.danceability / 100),
      RadarData(label: 'Valence', value: analysis.audioDna.valence / 100),
      RadarData(label: 'Acoustic', value: analysis.audioDna.acousticness / 100),
      RadarData(
          label: 'Instr.', value: analysis.audioDna.instrumentalness / 100),
    ];

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom +
                80, // Bottom nav + safe area
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Animation Overlay
              if (_showSuccessAnimation)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _successController,
                      builder: (context, child) {
                        return Stack(
                          children: List.generate(8, (index) {
                            final delay = index * 0.1;
                            final progress = (_successController.value - delay)
                                .clamp(0.0, 1.0);

                            return Positioned(
                              top: 100 + (progress * 200),
                              left: MediaQuery.of(context).size.width / 2 -
                                  100 +
                                  (Random().nextDouble() - 0.5) *
                                      200 *
                                      progress,
                              child: Opacity(
                                opacity: 1 - progress,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Back Button and Optimize Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.textMuted,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        if (widget.playlistUrl != null)
                          TextButton.icon(
                            onPressed: _isLoadingOptimization
                                ? null
                                : _optimizePlaylist,
                            icon: _isLoadingOptimization
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primary),
                                    ),
                                  )
                                : const Icon(Icons.tune, size: 18),
                            label: Text(
                              _isLoadingOptimization
                                  ? 'Optimizing...'
                                  : 'Optimize',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Playlist Info
                    Row(
                      children: [
                        // Cover Art
                        AnimatedBuilder(
                          animation: _successController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _showSuccessAnimation
                                  ? (1 +
                                      sin(_successController.value * pi * 4) *
                                          0.05)
                                  : 1,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: analysis.coverUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: analysis.coverUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: AppTheme.cardBackground,
                                            child: const Icon(
                                              Icons.music_note,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: AppTheme.cardBackground,
                                        child: const Icon(
                                          Icons.music_note,
                                          color: AppTheme.textMuted,
                                          size: 32,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 16),

                        // Playlist Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Platform Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954)
                                      .withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: const Color(0xFF1DB954)
                                        .withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'SPOTIFY',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF1DB954),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Title
                              Text(
                                analysis.playlistName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Metadata
                              Text(
                                'by ${analysis.owner} • ${analysis.trackCount} tracks',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontFamily: 'Space Mono',
                                    ),
                              ),

                              const SizedBox(height: 4),

                              // Tempo
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Avg Tempo: ${analysis.audioDna.tempo.round()} BPM',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textMuted,
                                          fontFamily: 'Space Mono',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Health Score Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Playlist Health',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      analysis.healthScore.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontFamily: 'Space Mono',
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/100',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppTheme.textMuted,
                                            fontFamily: 'Space Mono',
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getHealthColor(analysis.healthScore)
                                  .withValues(alpha: 0.1),
                              border: Border.all(
                                color: _getHealthColor(analysis.healthScore)
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              analysis.healthStatus,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        _getHealthColor(analysis.healthScore),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Progress Bar
                      SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: analysis.healthScore / 100,
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getHealthColor(analysis.healthScore)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        _getHealthDescription(analysis.healthScore),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Audio DNA Radar Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Audio DNA',
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
                      child: AnimatedRadarChart(data: radarData),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Top Tracks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Top Tracks',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (analysis.topTracks.isNotEmpty)
                      ...analysis.topTracks.map((track) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.cardBackground.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Album Art
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: track.albumArt != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: track.albumArt!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: AppTheme.cardBackground,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: AppTheme.cardBackground,
                                        child: const Icon(
                                          Icons.music_note,
                                          color: AppTheme.textMuted,
                                          size: 16,
                                        ),
                                      ),
                              ),

                              const SizedBox(width: 12),

                              // Track Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      track.artist,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Personality Decoded
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                          const Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personality Decoded',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analysis.personalityType,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              analysis.personalityDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Playlist Optimization Section
              if (_optimizationData != null) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildOptimizationSection(context, _optimizationData!),
                ),
              ],

              const SizedBox(height: 32),

              // Genre Distribution
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                          const Icon(
                            Icons.pie_chart,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Genre Distribution',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GenreDistributionBars(genres: analysis.genreDistribution),
                      if (analysis.subgenres.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Detected Subgenres',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: analysis.subgenres.map((subgenre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                subgenre,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Overall Rating
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow.withValues(alpha: 0.1),
                        Colors.amber.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.yellow.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Overall Rating',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final isFilled =
                              index < analysis.overallRating.floor();
                          final isPartial =
                              index == analysis.overallRating.floor() &&
                                  analysis.overallRating % 1 > 0;

                          return Icon(
                            Icons.star,
                            color: isFilled || isPartial
                                ? Colors.amber
                                : Colors.white.withValues(alpha: 0.2),
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${analysis.overallRating.toStringAsFixed(1)}/5.0',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontFamily: 'Space Mono',
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        analysis.ratingDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Share functionality
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.share,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Share Analysis',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final isAuthenticated =
                              ref.watch(isAuthenticatedProvider);
                          return OutlinedButton(
                            onPressed: () {
                              if (isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Analysis automatically saved to your history'),
                                    backgroundColor: AppTheme.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Sign in to save your analysis'),
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
                                  isAuthenticated ? 'Saved' : 'Save Report',
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 90) return AppTheme.success;
    if (score >= 75) return AppTheme.secondary;
    if (score >= 60) return Colors.yellow;
    return Colors.redAccent;
  }

  String _getHealthDescription(int score) {
    if (score >= 80) {
      return 'Your playlist has a consistent energy flow with minimal genre clutter.';
    } else {
      return 'Your playlist might feel a bit disjointed. Consider narrowing the genre focus.';
    }
  }

  Widget _buildOptimizationSection(
      BuildContext context, Map<String, dynamic> optimization) {
    final optimizationData =
        optimization['optimization'] as Map<String, dynamic>?;
    final suggestions = (optimizationData?['suggestions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final missingGenres =
        (optimizationData?['missingGenres'] as List?)?.cast<String>() ?? [];
    final score = (optimizationData?['score'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.4),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(24),
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimization Suggestions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Score: $score/100',
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
          if (missingGenres.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Missing Genres',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingGenres.take(5).map((genre) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    genre,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Recommended Tracks',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...suggestions.take(5).map((track) {
              final name = track['name']?.toString() ?? 'Unknown';
              final artists =
                  (track['artists'] as List?)?.cast<dynamic>() ?? [];
              final artistName = artists.isNotEmpty
                  ? artists
                      .map((a) {
                        if (a is Map) {
                          return a['name']?.toString() ?? '';
                        } else {
                          return a.toString();
                        }
                      })
                      .where((n) => n.isNotEmpty)
                      .join(', ')
                  : 'Unknown Artist';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: track['albumArt'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                track['albumArt'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.music_note),
                              ),
                            )
                          : const Icon(Icons.music_note),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artistName,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
