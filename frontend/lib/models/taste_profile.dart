class TasteProfile {
  final Map<String, double> topGenres; // genre -> percentage
  final Map<String, double> topArtists; // artist -> percentage
  final Map<String, double> audioFeatures; // feature -> average value
  final int totalPlaylistsAnalyzed;
  final DateTime lastUpdated;

  TasteProfile({
    required this.topGenres,
    required this.topArtists,
    required this.audioFeatures,
    required this.totalPlaylistsAnalyzed,
    required this.lastUpdated,
  });

  factory TasteProfile.empty() {
    return TasteProfile(
      topGenres: {},
      topArtists: {},
      audioFeatures: {},
      totalPlaylistsAnalyzed: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    return TasteProfile(
      topGenres: (json['topGenres'] ?? json['top_genres'] ?? {})
          .map<String, double>((key, value) => MapEntry(key.toString(), (value as num).toDouble())),
      topArtists: (json['topArtists'] ?? json['top_artists'] ?? {})
          .map<String, double>((key, value) => MapEntry(key.toString(), (value as num).toDouble())),
      audioFeatures: (json['audioFeatures'] ?? json['audio_features'] ?? {})
          .map<String, double>((key, value) => MapEntry(key.toString(), (value as num).toDouble())),
      totalPlaylistsAnalyzed: json['totalPlaylistsAnalyzed'] ?? json['total_playlists'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : json['last_updated'] != null
              ? DateTime.parse(json['last_updated'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topGenres': topGenres,
      'topArtists': topArtists,
      'audioFeatures': audioFeatures,
      'totalPlaylistsAnalyzed': totalPlaylistsAnalyzed,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  List<MapEntry<String, double>> get topGenresSorted {
    final entries = topGenres.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<MapEntry<String, double>> get topArtistsSorted {
    final entries = topArtists.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  TasteProfile copyWith({
    Map<String, double>? topGenres,
    Map<String, double>? topArtists,
    Map<String, double>? audioFeatures,
    int? totalPlaylistsAnalyzed,
    DateTime? lastUpdated,
  }) {
    return TasteProfile(
      topGenres: topGenres ?? this.topGenres,
      topArtists: topArtists ?? this.topArtists,
      audioFeatures: audioFeatures ?? this.audioFeatures,
      totalPlaylistsAnalyzed: totalPlaylistsAnalyzed ?? this.totalPlaylistsAnalyzed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

