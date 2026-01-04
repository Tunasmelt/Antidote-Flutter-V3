import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../widgets/audio_preview_player.dart';

class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final Color accentColor;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool showActions;

  const RecommendationCard({
    super.key,
    required this.track,
    required this.accentColor,
    this.onLike,
    this.onDislike,
    this.showActions = true,
  });

  String get _name => track['name'] ?? track['title'] ?? 'Unknown Track';
  
  String get _artist {
    if (track['artist'] != null) {
      return track['artist'].toString();
    }
    if (track['artists'] is List && (track['artists'] as List).isNotEmpty) {
      final artistsList = track['artists'] as List;
      if (artistsList[0] is Map && artistsList[0]['name'] != null) {
        return artistsList[0]['name'].toString();
      }
      return artistsList[0].toString();
    }
    return 'Unknown Artist';
  }

  String? get _albumArt {
    if (track['albumArt'] != null) return track['albumArt'].toString();
    if (track['album_art'] != null) return track['album_art'].toString();
    if (track['album'] is Map && track['album']['images'] is List && (track['album']['images'] as List).isNotEmpty) {
      return (track['album']['images'] as List)[0]['url'];
    }
    if (track['images'] is List && (track['images'] as List).isNotEmpty) {
      return (track['images'] as List)[0]['url'];
    }
    return track['image']?.toString();
  }

  String? get _previewUrl => track['preview_url'] ?? track['previewUrl'];
  String? get _spotifyId => track['id'] ?? track['spotify_id'];

  Future<void> _openInSpotify(BuildContext context) async {
    if (_spotifyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spotify ID not available'),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
      return;
    }

    final spotifyUrl = 'https://open.spotify.com/track/$_spotifyId';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.4),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Album Art
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              color: accentColor.withValues(alpha: 0.1),
            ),
            child: _albumArt != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _albumArt!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: accentColor.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            size: 64,
                            color: accentColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: accentColor.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            size: 64,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.music_note,
                      size: 64,
                      color: accentColor,
                    ),
                  ),
          ),

          // Track Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _artist,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Audio Preview
                if (_previewUrl != null) ...[
                  const SizedBox(height: 16),
                  AudioPreviewPlayer(
                    previewUrl: _previewUrl!,
                    autoPlay: true,
                  ),
                ],

                // Action Buttons
                if (showActions) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dislike Button
                      IconButton(
                        onPressed: onDislike,
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                        ),
                        tooltip: 'Dislike',
                      ),
                      const SizedBox(width: 16),
                      // Like Button
                      IconButton(
                        onPressed: onLike,
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppTheme.success,
                            size: 24,
                          ),
                        ),
                        tooltip: 'Like',
                      ),
                      const SizedBox(width: 16),
                      // Open in Spotify Button
                      IconButton(
                        onPressed: () => _openInSpotify(context),
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.open_in_new,
                            color: Color(0xFF1DB954),
                            size: 24,
                          ),
                        ),
                        tooltip: 'Open in Spotify',
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
  }
}

