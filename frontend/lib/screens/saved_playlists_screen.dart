import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../services/api_client.dart';
import '../providers/api_client_provider.dart';

class SavedPlaylistsScreen extends ConsumerStatefulWidget {
  const SavedPlaylistsScreen({super.key});

  @override
  ConsumerState<SavedPlaylistsScreen> createState() => _SavedPlaylistsScreenState();
}

class _SavedPlaylistsScreenState extends ConsumerState<SavedPlaylistsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AnimationController> _itemControllers = [];
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var itemController in _itemControllers) {
      itemController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_refreshKey),
        future: _fetchPlaylists(apiClient),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Playlists...',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load playlists',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final playlists = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: Icon(Icons.arrow_back, size: 16, color: AppTheme.mutedColor),
                        label: Text(
                          'Back to Profile',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      FadeTransition(
                        opacity: _controller,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOut,
                          )),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved Playlists',
                                style: AppTheme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'PressStart2P',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your collection of curated vibes',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedColor,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: playlists.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No playlists found.',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final playlist = playlists[index];
                            
                            // Create animation controller for this item
                            if (index >= _itemControllers.length) {
                              final controller = AnimationController(
                                vsync: this,
                                duration: const Duration(milliseconds: 300),
                              );
                              _itemControllers.add(controller);
                              Future.delayed(
                                Duration(milliseconds: 100 + (index * 80)),
                                () => controller.forward(),
                              );
                            }
                            
                            final itemController = _itemControllers[index];
                            
                            return FadeTransition(
                              opacity: itemController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: itemController,
                                  curve: Curves.easeOut,
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildPlaylistItem(playlist),
                                ),
                              ),
                            );
                          },
                          childCount: playlists.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaylistItem(Map<String, dynamic> playlist) {
    final coverUrl = playlist['coverUrl'] as String?;
    final name = playlist['name'] ?? 'Untitled Playlist';
    final trackCount = playlist['trackCount'] ?? 0;
    final createdAt = playlist['createdAt'] != null
        ? DateTime.tryParse(playlist['createdAt'])
        : null;
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : 'Unknown date';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to playlist analysis
            if (playlist['url'] != null) {
              context.go('/analysis?url=${Uri.encodeComponent(playlist['url'])}');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Cover image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.play_arrow,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.play_arrow,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                // Playlist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$trackCount tracks • $timeAgo',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, playlist),
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.mutedColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: AppTheme.cardBackground,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'analyze',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.analytics,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analyze Playlist',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.share,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Share Playlist',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (playlist['url'] != null)
                      PopupMenuItem(
                        value: 'open_spotify',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.open_in_new,
                              color: AppTheme.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Open in Spotify',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete Playlist',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylists(ApiClient apiClient) async {
    try {
      final playlists = await apiClient.getSavedPlaylists();
      // Transform backend format to screen format
      return playlists.map((p) {
        return {
          'id': p['id']?.toString(),
          'name': p['name'] ?? 'Untitled Playlist',
          'trackCount': p['track_count'] ?? p['trackCount'] ?? 0,
          'coverUrl': p['cover_url'] ?? p['coverUrl'],
          'createdAt': p['created_at'] ?? p['createdAt'],
          'url': p['url'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch playlists: $e');
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleMenuAction(String action, Map<String, dynamic> playlist) async {
    switch (action) {
      case 'analyze':
        // Navigate to analysis screen
        if (playlist['url'] != null) {
          context.go('/analysis?url=${Uri.encodeComponent(playlist['url'])}');
        }
        break;

      case 'share':
        // Copy playlist URL to clipboard
        final url = playlist['url'] as String?;
        if (url != null && url.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Playlist URL copied to clipboard'),
                backgroundColor: AppTheme.cardBackground,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No URL available for this playlist'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        break;

      case 'open_spotify':
        // Open playlist in Spotify
        final url = playlist['url'] as String?;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open Spotify'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
        break;

      case 'delete':
        // Show confirmation dialog before deleting
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Playlist',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${playlist['name'] ?? 'this playlist'}"? This action cannot be undone.',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          try {
            final playlistId = playlist['id'] as String?;
            if (playlistId == null || playlistId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot delete: Playlist ID not found'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              return;
            }

            final apiClient = ref.read(apiClientProvider);
            await apiClient.deletePlaylist(playlistId);
            
            if (mounted) {
              // Refresh the list by incrementing the refresh key
              setState(() {
                _refreshKey++;
                // Dispose item controllers since we're refreshing
                for (var controller in _itemControllers) {
                  controller.dispose();
                }
                _itemControllers.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playlist "${playlist['name'] ?? 'Playlist'}" deleted successfully'),
                  backgroundColor: AppTheme.cardBackground,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete playlist: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
        break;
    }
  }
}

