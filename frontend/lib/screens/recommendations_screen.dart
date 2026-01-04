import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/recommendations_provider.dart';
import '../providers/api_client_provider.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/spotify_connect_prompt.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  final String strategyId;
  final String strategyTitle;
  final Color strategyColor;

  const RecommendationsScreen({
    super.key,
    required this.strategyId,
    required this.strategyTitle,
    required this.strategyColor,
  });

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  bool _swipeMode = true; // Default to swipe mode
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsState =
        ref.watch(recommendationsProvider(widget.strategyId));
    final notifier =
        ref.read(recommendationsProvider(widget.strategyId).notifier);

    return recommendationsState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ),
      error: (error, stack) {
        // Check if it's a connection/authentication error
        final errorString = error.toString().toLowerCase();
        final isConnectionError = errorString.contains('connection') ||
            errorString.contains('refused') ||
            errorString.contains('token') ||
            errorString.contains('unauthorized') ||
            errorString.contains('spotify');

        if (isConnectionError) {
          return Scaffold(
            body: SpotifyConnectPrompt(
              message:
                  'Connect your Spotify account to get personalized music recommendations',
              onConnected: () {
                // Retry loading recommendations after connecting
                notifier.refresh();
              },
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Failed to load recommendations',
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
                    onPressed: () => notifier.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_off,
                    color: AppTheme.textMuted,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No recommendations found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different strategy or check your connection',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textMuted,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.strategyTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'Track ${notifier.currentIndex + 1} of ${notifier.totalCount}',
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
                      ),
                      // Create Playlist Button
                      IconButton(
                        icon: const Icon(
                          Icons.playlist_add,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () =>
                            _showCreatePlaylistDialog(context, recommendations),
                        tooltip: 'Create Playlist',
                      ),
                      // Toggle View Mode
                      IconButton(
                        icon: Icon(
                          _swipeMode ? Icons.list : Icons.view_carousel,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _swipeMode = !_swipeMode;
                          });
                        },
                        tooltip: _swipeMode ? 'List View' : 'Swipe View',
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _swipeMode
                    ? _buildSwipeView(notifier, recommendations)
                    : _buildListView(recommendations),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwipeView(RecommendationsNotifier notifier,
      List<Map<String, dynamic>> recommendations) {
    return PageView.builder(
      controller: _pageController,
      itemCount: recommendations.length,
      onPageChanged: (index) {
        notifier.goToTrack(index);
      },
      itemBuilder: (context, index) {
        final track = recommendations[index];
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                // Swipe right - like
                notifier.likeTrack();
                if (notifier.hasMore) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              } else {
                // Swipe left - dislike
                notifier.dislikeTrack();
                if (notifier.hasMore) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            }
          },
          child: RecommendationCard(
            track: track,
            accentColor: widget.strategyColor,
            onLike: () {
              notifier.likeTrack();
              HapticFeedback.mediumImpact();
              if (notifier.hasMore) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            onDislike: () {
              notifier.dislikeTrack();
              HapticFeedback.lightImpact();
              if (notifier.hasMore) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> recommendations) {
    final notifier =
        ref.read(recommendationsProvider(widget.strategyId).notifier);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final track = recommendations[index];
        return RecommendationCard(
          track: track,
          accentColor: widget.strategyColor,
          onLike: () {
            notifier.goToTrack(index);
            notifier.likeTrack();
            HapticFeedback.mediumImpact();
          },
          onDislike: () {
            notifier.goToTrack(index);
            notifier.dislikeTrack();
            HapticFeedback.lightImpact();
          },
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(
      BuildContext context, List<Map<String, dynamic>> recommendations) async {
    final nameController =
        TextEditingController(text: '${widget.strategyTitle} Playlist');
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textMuted),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textMuted),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              '${recommendations.length} tracks will be added',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontFamily: 'Space Mono',
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null &&
        result['name'] != null &&
        result['name']!.toString().isNotEmpty) {
      if (!mounted || !context.mounted) return;
      _createPlaylist(context, result['name']!.toString(),
          result['description']?.toString(), recommendations);
    }
  }

  Future<void> _createPlaylist(BuildContext context, String name,
      String? description, List<Map<String, dynamic>> recommendations) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      // Convert recommendations to track format
      final tracks = recommendations.map((track) {
        return {
          'id': track['id']?.toString(),
          'uri': track['uri']?.toString() ?? 'spotify:track:${track['id']}',
        };
      }).toList();

      await apiClient.createPlaylist(
        name: name,
        description: description,
        tracks: tracks,
      );

      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "$name" created successfully!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
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
