import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/models/analysis.dart';

void main() {
  group('PlaylistAnalysis Model', () {
    test('creates PlaylistAnalysis from JSON', () {
      final json = {
        'playlistName': 'My Test Playlist',
        'owner': 'Test User',
        'coverUrl': 'https://example.com/cover.jpg',
        'trackCount': 50,
        'audioDna': {
          'energy': 75,
          'danceability': 80,
          'valence': 65,
          'acousticness': 15,
          'instrumentalness': 5,
          'tempo': 120,
        },
        'personalityType': 'Energetic Explorer',
        'personalityDescription': 'High energy playlist',
        'genreDistribution': [
          {'name': 'pop', 'value': 40},
          {'name': 'rock', 'value': 30},
        ],
        'subgenres': ['indie pop', 'alternative rock'],
        'healthScore': 75,
        'healthStatus': 'Healthy',
        'overallRating': 8.5,
        'ratingDescription': 'Excellent',
        'topTracks': [],
      };

      final analysis = PlaylistAnalysis.fromJson(json);

      expect(analysis.playlistName, equals('My Test Playlist'));
      expect(analysis.owner, equals('Test User'));
      expect(analysis.trackCount, equals(50));
      expect(analysis.overallRating, equals(8.5));
      expect(analysis.healthScore, equals(75));
      expect(analysis.audioDna.energy, equals(75));
      expect(analysis.genreDistribution.length, equals(2));
      expect(analysis.genreDistribution[0].name, equals('pop'));
    });

    test('handles missing optional fields', () {
      final json = {
        'playlistName': 'Minimal Playlist',
        'owner': 'Test User',
        'trackCount': 10,
        'audioDna': {},
        'personalityType': '',
        'personalityDescription': '',
        'genreDistribution': [],
        'subgenres': [],
        'healthScore': 0,
        'healthStatus': 'Unknown',
        'overallRating': 0,
        'ratingDescription': '',
        'topTracks': [],
      };

      final analysis = PlaylistAnalysis.fromJson(json);

      expect(analysis.playlistName, equals('Minimal Playlist'));
      expect(analysis.owner, equals('Test User'));
      expect(analysis.trackCount, equals(10));
      expect(analysis.genreDistribution, isEmpty);
      expect(analysis.topTracks, isEmpty);
    });

    test('converts PlaylistAnalysis to JSON', () {
      final analysis = PlaylistAnalysis(
        playlistName: 'Test Playlist',
        owner: 'Test Owner',
        coverUrl: 'https://test.com/cover.jpg',
        trackCount: 25,
        audioDna: AudioDna(
          energy: 70,
          danceability: 80,
          valence: 65,
          acousticness: 15,
          instrumentalness: 5,
          tempo: 120,
        ),
        personalityType: 'Test Type',
        personalityDescription: 'Test Description',
        genreDistribution: [],
        subgenres: [],
        healthScore: 80,
        healthStatus: 'Healthy',
        overallRating: 7.5,
        ratingDescription: 'Good',
        topTracks: [],
      );

      final json = analysis.toJson();

      expect(json['playlistName'], equals('Test Playlist'));
      expect(json['owner'], equals('Test Owner'));
      expect(json['trackCount'], equals(25));
      expect(json['overallRating'], equals(7.5));
      expect(json['audioDna'], isA<Map>());
    });
  });
}
