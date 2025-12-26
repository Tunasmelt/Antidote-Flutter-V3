import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';
import '../models/battle.dart';
import '../providers/battle_provider.dart';
import '../widgets/animated_radar_chart.dart';

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
          _compatibilityTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
            if (mounted) {
              setState(() {
                _displayCompatibility = min(target, _displayCompatibility + 2);
              });
              if (_displayCompatibility >= target) {
                timer.cancel();
              }
            } else {
              timer.cancel();
            }
          });
        });
      }
    });
    
    return battleState.when(
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(error),
      data: (battle) => battle == null 
        ? _buildInputView() 
        : _buildResultView(battle),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Battling Playlists...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comparing audio DNA and compatibility',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 24),
            Text(
              'Battle Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _compatibilityTimer?.cancel();
                ref.invalidate(battleNotifierProvider);
                setState(() {
                  _resultsReady = false;
                  _displayCompatibility = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBackground,
                foregroundColor: AppTheme.textPrimary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    final playlist1Data = battle.audioData.map((data) {
      return RadarData(
        label: data['subject'] ?? '',
        value: (data['A'] ?? 0) / 100.0,
      );
    }).toList();
    
    final playlist2Data = battle.audioData.map((data) {
      return RadarData(
        label: data['subject'] ?? '',
        value: (data['B'] ?? 0) / 100.0,
      );
    }).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
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
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                        color: _getWinnerColor(battle.winner).withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getWinnerColor(battle.winner).withValues(alpha: 0.3),
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getWinnerReason(battle),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Space Mono',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Artists',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            color: AppTheme.cardBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: battle.sharedArtists.take(3).map((artist) {
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
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Space Mono',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Genres',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                genre,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        ...battle.sharedTracks.take(3).map((track) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: AppTheme.success,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${track.title} - ${track.artist}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Create merged playlist
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Create Merged',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondary,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
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
  
  Widget _buildPlaylistScoreCard(BattlePlaylist playlist, {
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
                color: isWinner ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
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
    if (score >= 80) return 'Highly compatible playlists with strong musical synergy.';
    if (score >= 60) return 'Decent compatibility with some shared musical DNA.';
    if (score >= 40) return 'Moderate compatibility - different but not opposing styles.';
    return 'Low compatibility - quite different musical approaches.';
  }
  
  Color _getWinnerColor(String winner) {
    if (winner == 'tie') return AppTheme.secondary;
    return AppTheme.warning;
  }
  
  String _getWinnerText(String winner) {
    if (winner == 'tie') return 'Perfect Tie!';
    if (winner == 'playlist1') return 'Contender 1 Wins!';
    if (winner == 'playlist2') return 'Contender 2 Wins!';
    return 'Battle Complete';
  }
  
  String _getWinnerReason(BattleResult battle) {
    if (battle.winner == 'tie') return 'Both playlists are perfectly balanced!';
    return 'Higher overall score and better musical cohesion.';
  }
}
