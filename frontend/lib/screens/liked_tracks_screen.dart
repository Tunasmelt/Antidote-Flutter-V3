import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/liked_tracks_provider.dart';
import '../widgets/liked_track_item.dart';

class LikedTracksScreen extends ConsumerStatefulWidget {
  const LikedTracksScreen({super.key});

  @override
  ConsumerState<LikedTracksScreen> createState() => _LikedTracksScreenState();
}

class _LikedTracksScreenState extends ConsumerState<LikedTracksScreen> {
  @override
  Widget build(BuildContext context) {
    final likedTracksState = ref.watch(likedTracksProvider);

    return likedTracksState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
      error: (error, stack) => Center(
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
                'Failed to load liked tracks',
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
                onPressed: () => ref.read(likedTracksProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardBackground,
                  foregroundColor: AppTheme.textPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (tracks) => SingleChildScrollView(
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
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liked Tracks',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                            fontFamily: 'Space Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tracks.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => ref.read(likedTracksProvider.notifier).refresh(),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
            ),

            // Tracks List
            if (tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
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
                        'No liked tracks yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Like tracks from recommendations to see them here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/music-assistant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Explore Recommendations'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: tracks.map((track) {
                    return LikedTrackItem(
                      track: track,
                      onRemove: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.cardBackground,
                            title: const Text(
                              'Remove Track',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                            content: Text(
                              'Remove "${track.name}" from liked tracks?',
                              style: const TextStyle(color: AppTheme.textMuted),
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
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(likedTracksProvider.notifier).removeLikedTrack(track.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Track removed'),
                                      backgroundColor: AppTheme.success,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

