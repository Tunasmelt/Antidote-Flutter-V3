import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';

class SavedTracksScreen extends ConsumerStatefulWidget {
  const SavedTracksScreen({super.key});

  @override
  ConsumerState<SavedTracksScreen> createState() => _SavedTracksScreenState();
}

class _SavedTracksScreenState extends ConsumerState<SavedTracksScreen> {
  List<Map<String, dynamic>> _tracks = [];
  int _offset = 0;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _tracks.length < _total) {
        _loadMoreTracks();
      }
    }
  }

  Future<void> _loadTracks({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _tracks = [];
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getSavedTracks(limit: 50, offset: _offset);

      if (mounted) {
        setState(() {
          final newTracks = (result['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (refresh) {
            _tracks = newTracks;
          } else {
            _tracks.addAll(newTracks);
          }
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _offset = _tracks.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreTracks() async {
    if (_isLoadingMore || _tracks.length >= _total) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getSavedTracks(limit: 50, offset: _offset);

      if (mounted) {
        setState(() {
          final newTracks = (result['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _tracks.addAll(newTracks);
          _offset = _tracks.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading && _tracks.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : _error != null && _tracks.isEmpty
                ? Center(
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
                            'Failed to load saved tracks',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _loadTracks(refresh: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadTracks(refresh: true),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saved Tracks',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_total ${_total == 1 ? 'track' : 'tracks'}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textMuted,
                                          fontFamily: 'Space Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _loadTracks(refresh: true),
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tracks List
                        if (_tracks.isEmpty && !_isLoading)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_border,
                                      size: 64,
                                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No saved tracks',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Save tracks on Spotify to see them here',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == _tracks.length) {
                                    if (_isLoadingMore) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }

                                  final item = _tracks[index];
                                  final track = item['track'] as Map<String, dynamic>? ?? item;
                                  final addedAt = item['added_at']?.toString();
                                  final name = track['name']?.toString() ?? 'Unknown';
                                  final artists = (track['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                  final artistName = artists.isNotEmpty
                                      ? artists.map((a) => a['name']?.toString() ?? '').join(', ')
                                      : 'Unknown Artist';
                                  final album = track['album'] as Map<String, dynamic>?;
                                  final albumArt = album?['images']?[0]?['url'] as String?;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBackground.withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.05),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        // Album Art
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
                                                    albumArt,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                                                  ),
                                                )
                                              : const Icon(Icons.music_note),
                                        ),
                                        const SizedBox(width: 12),
                                        // Track Info
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
                                              const SizedBox(height: 4),
                                              Text(
                                                artistName,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (addedAt != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 12,
                                                      color: AppTheme.textMuted,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Saved ${_formatDate(addedAt)}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.textMuted,
                                                        fontFamily: 'Space Mono',
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount: _tracks.length + (_isLoadingMore ? 1 : 0),
                              ),
                            ),
                          ),

                        // Bottom padding
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 80,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
