import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/services/analysis_service.dart';

void main() {
  group('AnalysisService', () {
    test('calculateHealth returns valid score', () {
      final features = [
        AudioFeatures(
          energy: 0.8,
          danceability: 0.7,
          valence: 0.6,
          acousticness: 0.2,
          instrumentalness: 0.1,
          tempo: 120,
          liveness: 0.1,
          speechiness: 0.05,
        ),
        AudioFeatures(
          energy: 0.6,
          danceability: 0.8,
          valence: 0.7,
          acousticness: 0.3,
          instrumentalness: 0.0,
          tempo: 110,
          liveness: 0.2,
          speechiness: 0.03,
        ),
      ];
      
      final result = AnalysisService.calculateHealth(features, 20, 5);
      
      expect(result['score'], greaterThanOrEqualTo(0));
      expect(result['score'], lessThanOrEqualTo(100));
      expect(result['status'], isNotEmpty);
    });
    
    test('calculateHealth returns 0 for empty features', () {
      final result = AnalysisService.calculateHealth([], 0, 0);
      
      expect(result['score'], equals(0));
      expect(result['status'], equals('Unknown'));
    });
    
    test('determinePersonality returns valid personality', () {
      final features = [
        AudioFeatures(
          energy: 0.9,
          danceability: 0.3,
          valence: 0.2,
          acousticness: 0.1,
          instrumentalness: 0.8,
          tempo: 140,
          liveness: 0.1,
          speechiness: 0.05,
        ),
      ];
      final genres = ['electronic', 'experimental'];
      
      final result = AnalysisService.determinePersonality(features, genres);
      
      expect(result['type'], isNotEmpty);
      expect(result['description'], isNotEmpty);
    });
    
    test('determinePersonality handles empty features', () {
      final result = AnalysisService.determinePersonality([], []);
      
      expect(result['type'], equals('Unknown'));
      expect(result['description'], isNotEmpty);
    });
    
    test('calculateRating returns valid rating', () {
      final result = AnalysisService.calculateRating(80, 50);
      
      expect(result['rating'], greaterThanOrEqualTo(1.0));
      expect(result['rating'], lessThanOrEqualTo(5.0));
      expect(result['description'], isNotEmpty);
    });
    
    test('calculateCompatibility returns valid score', () {
      final features1 = [
        AudioFeatures(
          energy: 0.8,
          danceability: 0.7,
          valence: 0.6,
          acousticness: 0.2,
          instrumentalness: 0.1,
          tempo: 120,
          liveness: 0.1,
          speechiness: 0.05,
        ),
      ];
      
      final features2 = [
        AudioFeatures(
          energy: 0.75,
          danceability: 0.65,
          valence: 0.55,
          acousticness: 0.25,
          instrumentalness: 0.15,
          tempo: 115,
          liveness: 0.15,
          speechiness: 0.04,
        ),
      ];
      
      final result = AnalysisService.calculateCompatibility(features1, features2);
      
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThanOrEqualTo(100));
    });
    
    test('calculateCompatibility returns 0 for empty features', () {
      final result = AnalysisService.calculateCompatibility([], []);
      
      expect(result, equals(0));
    });
    
    test('classifySubgenres returns sorted list', () {
      final genres = {
        'Pop': 20,
        'Rock': 15,
        'Electronic': 12,
        'Jazz': 8,
        'Hip-Hop': 6,
        'Classical': 4,
        'Folk': 3,
        'Country': 2,
      };
      
      final result = AnalysisService.classifySubgenres(genres);
      
      expect(result.length, lessThanOrEqualTo(6));
      expect(result.isNotEmpty, isTrue);
    });
  });
}

