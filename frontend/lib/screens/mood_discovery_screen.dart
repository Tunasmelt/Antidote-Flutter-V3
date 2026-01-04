import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';

class MoodDiscoveryScreen extends ConsumerStatefulWidget {
  const MoodDiscoveryScreen({super.key});

  @override
  ConsumerState<MoodDiscoveryScreen> createState() => _MoodDiscoveryScreenState();
}

class _MoodDiscoveryScreenState extends ConsumerState<MoodDiscoveryScreen> {
  Map<String, dynamic>? _moodData;
  List<Map<String, dynamic>>? _moodPlaylist;
  bool _isLoading = false;
  bool _isGeneratingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _analyzeMood();
  }

  Future<void> _analyzeMood() async {
    setState(() {
      _isLoading = true;
      _moodData = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.analyzeMood(limit: 20);
      
      if (mounted) {
        setState(() {
          _moodData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze mood: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _generateMoodPlaylist() async {
    if (_moodData == null) return;
    
    final mood = _moodData!['mood']?['category'] as String?;
    if (mood == null) return;

    setState(() {
      _isGeneratingPlaylist = true;
      _moodPlaylist = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.generateMoodPlaylist(mood: mood, limit: 20);
      
      if (mounted) {
        setState(() {
          _moodPlaylist = (result['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isGeneratingPlaylist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingPlaylist = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate playlist: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _getMoodColor(String? category) {
    switch (category) {
      case 'happy_energetic':
        return Colors.yellow;
      case 'happy_calm':
        return Colors.green;
      case 'intense':
        return Colors.red;
      case 'melancholic':
        return Colors.blue;
      case 'dance':
        return Colors.purple;
      case 'chill':
        return Colors.cyan;
      default:
        return AppTheme.secondary;
    }
  }

  IconData _getMoodIcon(String? category) {
    switch (category) {
      case 'happy_energetic':
        return Icons.wb_sunny;
      case 'happy_calm':
        return Icons.favorite;
      case 'intense':
        return Icons.bolt;
      case 'melancholic':
        return Icons.mood;
      case 'dance':
        return Icons.music_note;
      case 'chill':
        return Icons.waves;
      default:
        return Icons.mood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : _moodData == null
                ? Center(
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
                          'Failed to analyze mood',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _analyzeMood,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => context.go('/'),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Mood Discovery',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Current Mood Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildMoodCard(context),
                        ),

                        const SizedBox(height: 32),

                        // Audio Features
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildAudioFeatures(context),
                        ),

                        const SizedBox(height: 32),

                        // Generate Playlist Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGeneratingPlaylist ? null : _generateMoodPlaylist,
                              icon: _isGeneratingPlaylist
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.playlist_add),
                              label: Text(
                                _isGeneratingPlaylist ? 'Generating...' : 'Generate Mood Playlist',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Generated Playlist
                        if (_moodPlaylist != null && _moodPlaylist!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generated Playlist',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._moodPlaylist!.take(10).map((track) {
                                  final name = track['name']?.toString() ?? 'Unknown';
                                  final artists = (track['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                  final artistName = artists.isNotEmpty 
                                      ? artists.map((a) => a['name']?.toString() ?? '').join(', ')
                                      : 'Unknown Artist';
                                  final albumArt = track['album']?['images']?[0]?['url'] ?? 
                                                  track['albumArt']?.toString();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: AppTheme.cardBackground,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: albumArt != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    albumArt.toString(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
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
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                artistName,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context) {
    final mood = _moodData!['mood'] as Map<String, dynamic>?;
    final category = mood?['category'] as String?;
    final description = mood?['description'] as String?;
    final confidence = (mood?['confidence'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMoodColor(category).withValues(alpha: 0.2),
            _getMoodColor(category).withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: _getMoodColor(category).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            _getMoodIcon(category),
            size: 64,
            color: _getMoodColor(category),
          ),
          const SizedBox(height: 16),
          Text(
            description ?? 'Unknown Mood',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: $confidence%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
              fontFamily: 'Space Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioFeatures(BuildContext context) {
    final features = _moodData!['audioFeatures'] as Map<String, dynamic>?;
    if (features == null) return const SizedBox.shrink();

    return Container(
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
            'Audio Features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureBar(context, 'Energy', (features['energy'] as num?)?.toInt() ?? 0),
          const SizedBox(height: 12),
          _buildFeatureBar(context, 'Valence', (features['valence'] as num?)?.toInt() ?? 0),
          const SizedBox(height: 12),
          _buildFeatureBar(context, 'Danceability', (features['danceability'] as num?)?.toInt() ?? 0),
          const SizedBox(height: 12),
          _buildFeatureBar(context, 'Tempo', (features['tempo'] as num?)?.toInt() ?? 0, isTempo: true),
        ],
      ),
    );
  }

  Widget _buildFeatureBar(BuildContext context, String label, int value, {bool isTempo = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              isTempo ? '$value BPM' : '$value%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontFamily: 'Space Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isTempo ? (value / 200).clamp(0.0, 1.0) : (value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

