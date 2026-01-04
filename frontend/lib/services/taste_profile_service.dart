import 'package:hive_flutter/hive_flutter.dart';
import '../models/taste_profile.dart';
import '../models/analysis.dart';

class TasteProfileService {
  static const String _boxName = 'taste_profile';
  static Box? _box;
  static const String _profileKey = 'current_profile';

  static Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      // Box might already be open
      _box = Hive.box(_boxName);
    }
  }

  static Future<TasteProfile> getProfile() async {
    if (_box == null) await init();

    try {
      final json = _box!.get(_profileKey);
      if (json != null) {
        return TasteProfile.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (e) {
      // Return empty profile if error
    }

    return TasteProfile.empty();
  }

  static Future<void> updateProfileFromAnalysis(PlaylistAnalysis analysis) async {
    if (_box == null) await init();

    final currentProfile = await getProfile();

    // Update genres
    final updatedGenres = Map<String, double>.from(currentProfile.topGenres);
    for (var genre in analysis.genreDistribution) {
      final currentValue = updatedGenres[genre.name] ?? 0.0;
      final newValue = genre.value.toDouble();
      // Weighted average: existing * count + new value / (count + 1)
      updatedGenres[genre.name] = (currentValue * currentProfile.totalPlaylistsAnalyzed + newValue) /
          (currentProfile.totalPlaylistsAnalyzed + 1);
    }

    // Update artists (from top tracks)
    final updatedArtists = Map<String, double>.from(currentProfile.topArtists);
    for (var track in analysis.topTracks) {
      final artist = track.artist;
      final currentValue = updatedArtists[artist] ?? 0.0;
      // Increment artist count
      updatedArtists[artist] = (currentValue * currentProfile.totalPlaylistsAnalyzed + 1.0) /
          (currentProfile.totalPlaylistsAnalyzed + 1);
    }

    // Update audio features (weighted average)
    final updatedFeatures = Map<String, double>.from(currentProfile.audioFeatures);
    final audioDna = analysis.audioDna;
    final features = {
      'energy': audioDna.energy / 100.0,
      'danceability': audioDna.danceability / 100.0,
      'valence': audioDna.valence / 100.0,
      'acousticness': audioDna.acousticness / 100.0,
      'instrumentalness': audioDna.instrumentalness / 100.0,
      'tempo': audioDna.tempo / 200.0, // Normalize tempo (assuming max ~200 BPM)
    };

    for (var entry in features.entries) {
      final currentValue = updatedFeatures[entry.key] ?? 0.0;
      updatedFeatures[entry.key] = (currentValue * currentProfile.totalPlaylistsAnalyzed + entry.value) /
          (currentProfile.totalPlaylistsAnalyzed + 1);
    }

    // Create updated profile
    final updatedProfile = currentProfile.copyWith(
      topGenres: updatedGenres,
      topArtists: updatedArtists,
      audioFeatures: updatedFeatures,
      totalPlaylistsAnalyzed: currentProfile.totalPlaylistsAnalyzed + 1,
      lastUpdated: DateTime.now(),
    );

    // Save to Hive
    await _box!.put(_profileKey, updatedProfile.toJson());
  }

  static Future<void> recalculateProfile(List<PlaylistAnalysis> analyses) async {
    if (_box == null) await init();

    if (analyses.isEmpty) {
      await _box!.put(_profileKey, TasteProfile.empty().toJson());
      return;
    }

    // Aggregate all analyses
    final genreMap = <String, double>{};
    final artistMap = <String, double>{};
    final featureMap = <String, List<double>>{};

    for (var analysis in analyses) {
      // Aggregate genres
      for (var genre in analysis.genreDistribution) {
        genreMap[genre.name] = (genreMap[genre.name] ?? 0.0) + genre.value.toDouble();
      }

      // Aggregate artists
      for (var track in analysis.topTracks) {
        artistMap[track.artist] = (artistMap[track.artist] ?? 0.0) + 1.0;
      }

      // Aggregate audio features
      final audioDna = analysis.audioDna;
      final features = {
        'energy': audioDna.energy / 100.0,
        'danceability': audioDna.danceability / 100.0,
        'valence': audioDna.valence / 100.0,
        'acousticness': audioDna.acousticness / 100.0,
        'instrumentalness': audioDna.instrumentalness / 100.0,
        'tempo': audioDna.tempo / 200.0,
      };

      for (var entry in features.entries) {
        featureMap.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }

    // Normalize genres to percentages
    final totalGenreValue = genreMap.values.fold(0.0, (sum, value) => sum + value);
    final normalizedGenres = genreMap.map((key, value) => MapEntry(
      key,
      totalGenreValue > 0 ? (value / totalGenreValue) * 100.0 : 0.0,
    ));

    // Normalize artists to percentages
    final totalArtistValue = artistMap.values.fold(0.0, (sum, value) => sum + value);
    final normalizedArtists = artistMap.map((key, value) => MapEntry(
      key,
      totalArtistValue > 0 ? (value / totalArtistValue) * 100.0 : 0.0,
    ));

    // Calculate average features
    final averageFeatures = featureMap.map((key, values) => MapEntry(
      key,
      values.fold(0.0, (sum, value) => sum + value) / values.length,
    ));

    final recalculatedProfile = TasteProfile(
      topGenres: normalizedGenres,
      topArtists: normalizedArtists,
      audioFeatures: averageFeatures,
      totalPlaylistsAnalyzed: analyses.length,
      lastUpdated: DateTime.now(),
    );

    await _box!.put(_profileKey, recalculatedProfile.toJson());
  }

  static Future<void> clearProfile() async {
    if (_box == null) await init();
    await _box!.put(_profileKey, TasteProfile.empty().toJson());
  }
}

