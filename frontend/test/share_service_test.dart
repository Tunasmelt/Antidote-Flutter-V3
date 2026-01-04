import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/services/share_service.dart';

void main() {
  group('ShareService', () {
    group('formatAnalysisText', () {
      test('formats analysis with all fields', () {
        final text = ShareService.shareAnalysis(
          playlistName: 'My Awesome Playlist',
          overallRating: 8.5,
          healthScore: 75.5,
          trackCount: 50,
          playlistUrl: 'https://open.spotify.com/playlist/test',
        );

        // Note: This will actually trigger the share dialog in a real environment
        // In tests, we verify the method completes without errors
        expect(text, completes);
      });

      test('formats battle results correctly', () {
        final text = ShareService.shareBattleResults(
          playlist1Name: 'Rock Classics',
          playlist2Name: 'Pop Hits',
          compatibilityScore: 65,
          winner: 'Rock Classics',
        );

        expect(text, completes);
      });

      test('formats taste profile', () {
        final text = ShareService.shareTasteProfile(
          topGenres: ['Rock', 'Pop', 'Jazz'],
          audioPreferences: {
            'Energy': 0.75,
            'Danceability': 0.65,
          },
        );

        expect(text, completes);
      });
    });
  });
}
