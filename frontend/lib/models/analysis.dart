class AudioDna {
  final int energy;
  final int danceability;
  final int valence;
  final int acousticness;
  final int instrumentalness;
  final int tempo;

  AudioDna({
    required this.energy,
    required this.danceability,
    required this.valence,
    required this.acousticness,
    required this.instrumentalness,
    required this.tempo,
  });

  factory AudioDna.fromJson(Map<String, dynamic> json) {
    return AudioDna(
      energy: json['energy'] ?? 0,
      danceability: json['danceability'] ?? 0,
      valence: json['valence'] ?? 0,
      acousticness: json['acousticness'] ?? 0,
      instrumentalness: json['instrumentalness'] ?? 0,
      tempo: json['tempo'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'danceability': danceability,
      'valence': valence,
      'acousticness': acousticness,
      'instrumentalness': instrumentalness,
      'tempo': tempo,
    };
  }
}

class GenreDistribution {
  final String name;
  final int value;

  GenreDistribution({
    required this.name,
    required this.value,
  });

  factory GenreDistribution.fromJson(Map<String, dynamic> json) {
    return GenreDistribution(
      name: json['name'] ?? '',
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class TopTrack {
  final String name;
  final String artist;
  final String? albumArt;

  TopTrack({
    required this.name,
    required this.artist,
    this.albumArt,
  });

  factory TopTrack.fromJson(Map<String, dynamic> json) {
    return TopTrack(
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      albumArt: json['albumArt'] ?? json['album_art'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'artist': artist,
      'albumArt': albumArt,
    };
  }
}

class PlaylistAnalysis {
  final String playlistName;
  final String owner;
  final String? coverUrl;
  final int trackCount;
  final AudioDna audioDna;
  final String personalityType;
  final String personalityDescription;
  final List<GenreDistribution> genreDistribution;
  final List<String> subgenres;
  final int healthScore;
  final String healthStatus;
  final double overallRating;
  final String ratingDescription;
  final List<TopTrack> topTracks;

  PlaylistAnalysis({
    required this.playlistName,
    required this.owner,
    this.coverUrl,
    required this.trackCount,
    required this.audioDna,
    required this.personalityType,
    required this.personalityDescription,
    required this.genreDistribution,
    required this.subgenres,
    required this.healthScore,
    required this.healthStatus,
    required this.overallRating,
    required this.ratingDescription,
    required this.topTracks,
  });

  factory PlaylistAnalysis.fromJson(Map<String, dynamic> json) {
    return PlaylistAnalysis(
      playlistName: json['playlistName'] ?? '',
      owner: json['owner'] ?? '',
      coverUrl: json['coverUrl'] ?? json['cover_url'],
      trackCount: json['trackCount'] ?? json['track_count'] ?? 0,
      audioDna: AudioDna.fromJson(json['audioDna'] ?? json['audio_dna'] ?? {}),
      personalityType: json['personalityType'] ?? json['personality_type'] ?? '',
      personalityDescription: json['personalityDescription'] ?? json['personality_description'] ?? '',
      genreDistribution: (json['genreDistribution'] ?? json['genre_distribution'] ?? [])
          .map<GenreDistribution>((g) => GenreDistribution.fromJson(g))
          .toList(),
      subgenres: (json['subgenres'] ?? json['subgenre_distribution'] ?? [])
          .map<String>((s) => s.toString())
          .toList(),
      healthScore: json['healthScore'] ?? json['health_score'] ?? json['totalScore'] ?? 0,
      healthStatus: json['healthStatus'] ?? json['health_status'] ?? 'Unknown',
      overallRating: (json['overallRating'] ?? json['overall_rating'] ?? 0).toDouble(),
      ratingDescription: json['ratingDescription'] ?? json['rating_description'] ?? '',
      topTracks: (json['topTracks'] ?? json['top_tracks'] ?? [])
          .map<TopTrack>((t) => TopTrack.fromJson(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlistName': playlistName,
      'owner': owner,
      'coverUrl': coverUrl,
      'trackCount': trackCount,
      'audioDna': audioDna.toJson(),
      'personalityType': personalityType,
      'personalityDescription': personalityDescription,
      'genreDistribution': genreDistribution.map((g) => g.toJson()).toList(),
      'subgenres': subgenres,
      'healthScore': healthScore,
      'healthStatus': healthStatus,
      'overallRating': overallRating,
      'ratingDescription': ratingDescription,
      'topTracks': topTracks.map((t) => t.toJson()).toList(),
    };
  }
}

