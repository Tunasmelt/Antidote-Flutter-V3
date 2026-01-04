import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

/// Share service for sharing analysis results and playlists
class ShareService {
  /// Share analysis results with formatted text
  static Future<void> shareAnalysis({
    required String playlistName,
    required double overallRating,
    required double healthScore,
    required int trackCount,
    String? playlistUrl,
  }) async {
    final text = _formatAnalysisText(
      playlistName: playlistName,
      overallRating: overallRating,
      healthScore: healthScore,
      trackCount: trackCount,
      playlistUrl: playlistUrl,
    );

    await Share.share(
      text,
      subject: 'Playlist Analysis: $playlistName',
    );
  }

  /// Share battle results
  static Future<void> shareBattleResults({
    required String playlist1Name,
    required String playlist2Name,
    required int compatibilityScore,
    required String winner,
  }) async {
    final text = _formatBattleText(
      playlist1Name: playlist1Name,
      playlist2Name: playlist2Name,
      compatibilityScore: compatibilityScore,
      winner: winner,
    );

    await Share.share(
      text,
      subject: 'Playlist Battle Results',
    );
  }

  /// Share a playlist with custom message
  static Future<void> sharePlaylist({
    required String playlistName,
    required String playlistUrl,
    String? customMessage,
  }) async {
    final text =
        customMessage ?? 'Check out this playlist: $playlistName\n$playlistUrl';

    await Share.share(
      text,
      subject: playlistName,
    );
  }

  /// Share taste profile
  static Future<void> shareTasteProfile({
    required List<String> topGenres,
    required Map<String, double> audioPreferences,
  }) async {
    final text = _formatTasteProfileText(
      topGenres: topGenres,
      audioPreferences: audioPreferences,
    );

    await Share.share(
      text,
      subject: 'My Music Taste Profile',
    );
  }

  /// Share with custom text
  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Share with share sheet positioned at a specific location (for iPad)
  static Future<void> shareWithPosition({
    required String text,
    required BuildContext context,
    String? subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;

    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  // Private formatting methods

  static String _formatAnalysisText({
    required String playlistName,
    required double overallRating,
    required double healthScore,
    required int trackCount,
    String? playlistUrl,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🎵 Playlist Analysis: $playlistName');
    buffer.writeln('');
    buffer.writeln('📊 Overall Rating: ${overallRating.toStringAsFixed(1)}/10');
    buffer.writeln('❤️ Health Score: ${healthScore.toStringAsFixed(0)}%');
    buffer.writeln('🎶 Tracks: $trackCount');

    if (playlistUrl != null) {
      buffer.writeln('');
      buffer.writeln('🔗 Listen: $playlistUrl');
    }

    buffer.writeln('');
    buffer.writeln('Analyzed with Antidote - Your Music Intelligence Platform');

    return buffer.toString();
  }

  static String _formatBattleText({
    required String playlist1Name,
    required String playlist2Name,
    required int compatibilityScore,
    required String winner,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('⚔️ Playlist Battle Results');
    buffer.writeln('');
    buffer.writeln(playlist1Name);
    buffer.writeln('    VS');
    buffer.writeln(playlist2Name);
    buffer.writeln('');
    buffer.writeln('🤝 Compatibility: $compatibilityScore%');
    buffer.writeln('🏆 Winner: $winner');
    buffer.writeln('');
    buffer.writeln('Battle your playlists with Antidote!');

    return buffer.toString();
  }

  static String _formatTasteProfileText({
    required List<String> topGenres,
    required Map<String, double> audioPreferences,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🎧 My Music Taste Profile');
    buffer.writeln('');

    if (topGenres.isNotEmpty) {
      buffer.writeln('🎼 Top Genres:');
      for (var i = 0; i < topGenres.length && i < 5; i++) {
        buffer.writeln('  ${i + 1}. ${topGenres[i]}');
      }
      buffer.writeln('');
    }

    if (audioPreferences.isNotEmpty) {
      buffer.writeln('🎵 Audio Preferences:');
      audioPreferences.forEach((key, value) {
        final percentage = (value * 100).toStringAsFixed(0);
        buffer.writeln('  $key: $percentage%');
      });
      buffer.writeln('');
    }

    buffer.writeln('Discover your music DNA with Antidote!');

    return buffer.toString();
  }
}
