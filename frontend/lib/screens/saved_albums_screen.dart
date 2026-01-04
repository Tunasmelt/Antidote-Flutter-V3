import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/api_client_provider.dart';

class SavedAlbumsScreen extends ConsumerStatefulWidget {
  const SavedAlbumsScreen({super.key});

  @override
  ConsumerState<SavedAlbumsScreen> createState() => _SavedAlbumsScreenState();
}

class _SavedAlbumsScreenState extends ConsumerState<SavedAlbumsScreen> {
  List<Map<String, dynamic>> _albums = [];
  int _offset = 0;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _albums.length < _total) {
        _loadMoreAlbums();
      }
    }
  }

  Future<void> _loadAlbums({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _albums = [];
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getSavedAlbums(limit: 50, offset: _offset);

      if (mounted) {
        setState(() {
          final newAlbums = (result['albums'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (refresh) {
            _albums = newAlbums;
          } else {
            _albums.addAll(newAlbums);
          }
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _offset = _albums.length;
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

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMore || _albums.length >= _total) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getSavedAlbums(limit: 50, offset: _offset);

      if (mounted) {
        setState(() {
          final newAlbums = (result['albums'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _albums.addAll(newAlbums);
          _offset = _albums.length;
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
      return '${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading && _albums.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : _error != null && _albums.isEmpty
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
                            'Failed to load saved albums',
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
                            onPressed: () => _loadAlbums(refresh: true),
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
                    onRefresh: () => _loadAlbums(refresh: true),
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
                                        'Saved Albums',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_total ${_total == 1 ? 'album' : 'albums'}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textMuted,
                                          fontFamily: 'Space Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _loadAlbums(refresh: true),
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Albums Grid
                        if (_albums.isEmpty && !_isLoading)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.album,
                                      size: 64,
                                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No saved albums',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Save albums on Spotify to see them here',
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
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == _albums.length) {
                                    if (_isLoadingMore) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }

                                  final album = _albums[index];
                                  final name = album['name']?.toString() ?? 'Unknown';
                                  final artists = (album['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                  final artistName = artists.isNotEmpty
                                      ? artists.map((a) => a['name']?.toString() ?? '').join(', ')
                                      : 'Unknown Artist';
                                  final images = (album['images'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                  final imageUrl = images.isNotEmpty ? images[0]['url']?.toString() : null;
                                  final releaseDate = album['release_date']?.toString();
                                  final totalTracks = (album['total_tracks'] as num?)?.toInt() ?? 0;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBackground.withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.05),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Album Cover
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.cardBackground,
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                            ),
                                            child: imageUrl != null
                                                ? ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.album),
                                                    ),
                                                  )
                                                : const Icon(Icons.album),
                                          ),
                                        ),
                                        // Album Info
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                artistName,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (releaseDate != null || totalTracks > 0) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    if (releaseDate != null) ...[
                                                      Text(
                                                        _formatDate(releaseDate),
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppTheme.textMuted,
                                                          fontFamily: 'Space Mono',
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      if (totalTracks > 0) ...[
                                                        Text(
                                                          ' • ',
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: AppTheme.textMuted,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                    if (totalTracks > 0)
                                                      Text(
                                                        '$totalTracks tracks',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppTheme.textMuted,
                                                          fontFamily: 'Space Mono',
                                                          fontSize: 10,
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
                                childCount: _albums.length + (_isLoadingMore ? 1 : 0),
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
