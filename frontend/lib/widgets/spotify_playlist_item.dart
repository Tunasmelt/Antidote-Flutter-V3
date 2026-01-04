import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class SpotifyPlaylistItem extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback? onTap;

  const SpotifyPlaylistItem({
    super.key,
    required this.playlist,
    this.onTap,
  });

  String get _playlistUrl {
    final url = playlist['url'] as String?;
    if (url != null && url.isNotEmpty) return url;
    final id = playlist['id'] as String?;
    if (id != null && id.isNotEmpty) return 'https://open.spotify.com/playlist/$id';
    return '';
  }

  String? get _coverImage {
    final images = playlist['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map<String, dynamic>) {
        return firstImage['url'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = playlist['name'] as String? ?? 'Unknown Playlist';
    final trackCount = playlist['trackCount'] as int? ?? 0;
    final owner = playlist['owner'] as String? ?? 'Unknown';

    return InkWell(
      onTap: onTap ?? () {
        final url = _playlistUrl;
        if (url.isNotEmpty) {
          context.push('/analysis?url=${Uri.encodeComponent(url)}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Cover Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: _coverImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: _coverImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.cardBackground,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.cardBackground,
                          child: const Icon(
                            Icons.music_note,
                            color: AppTheme.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.cardBackground,
                      child: const Icon(
                        Icons.music_note,
                        color: AppTheme.textMuted,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Playlist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount tracks • $owner',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow Icon
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
}

