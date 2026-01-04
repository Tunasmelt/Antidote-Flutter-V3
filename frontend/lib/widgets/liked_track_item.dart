import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/liked_track.dart';
import '../utils/theme.dart';
import '../widgets/audio_preview_player.dart';

class LikedTrackItem extends StatelessWidget {
  final LikedTrack track;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const LikedTrackItem({
    super.key,
    required this.track,
    this.onRemove,
    this.showRemoveButton = true,
  });

  Future<void> _openInSpotify(BuildContext context) async {
    if (track.spotifyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spotify ID not available'),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
      return;
    }

    final spotifyUrl = 'https://open.spotify.com/track/${track.spotifyId}';
    final uri = Uri.parse(spotifyUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Spotify'),
            backgroundColor: AppTheme.cardBackground,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Album Art
              Container(
                width: 60,
                height: 60,
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
                          placeholder: (context, url) => Container(
                            color: AppTheme.cardBackground,
                            child: const Icon(
                              Icons.music_note,
                              color: AppTheme.textMuted,
                              size: 24,
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
              
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Liked ${_formatDate(track.likedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontFamily: 'Space Mono',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Column(
                children: [
                  if (showRemoveButton && onRemove != null)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: onRemove,
                      tooltip: 'Remove',
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _openInSpotify(context),
                    tooltip: 'Open in Spotify',
                  ),
                ],
              ),
            ],
          ),
          
          // Audio Preview Player
          if (track.previewUrl != null) ...[
            const SizedBox(height: 12),
            AudioPreviewPlayer(
              previewUrl: track.previewUrl!,
              autoPlay: false,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

