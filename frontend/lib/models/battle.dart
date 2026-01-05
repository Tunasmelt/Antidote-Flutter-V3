class BattlePlaylist {
  final String name;
  final String owner;
  final String? image;
  final int score;
  final int tracks;

  BattlePlaylist({
    required this.name,
    required this.owner,
    this.image,
    required this.score,
    required this.tracks,
  });

  factory BattlePlaylist.fromJson(Map<String, dynamic> json) {
    return BattlePlaylist(
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      image: json['image'] ?? json['coverUrl'] ?? json['cover_url'],
      score: json['score'] ?? 0,
      tracks: json['tracks'] ?? json['trackCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'image': image,
      'score': score,
      'tracks': tracks,
    };
  }
}

class SharedTrack {
  final String title;
  final String artist;
  final String? spotifyId;
  final String? uri;

  SharedTrack({
    required this.title,
    required this.artist,
    this.spotifyId,
    this.uri,
  });

  factory SharedTrack.fromJson(Map<String, dynamic> json) {
    return SharedTrack(
      title: json['title'] ?? json['name'] ?? '',
      artist: json['artist'] ?? '',
      spotifyId: json['spotifyId'] ?? json['spotify_id'] ?? json['id'],
      uri: json['uri'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
    };
  }
}

class BattleResult {
  final int compatibilityScore;
  final String winner;
  final BattlePlaylist playlist1;
  final BattlePlaylist playlist2;
  final List<String> sharedArtists;
  final List<String> sharedGenres;
  final List<SharedTrack> sharedTracks;
  final List<Map<String, dynamic>> audioData;

  BattleResult({
    required this.compatibilityScore,
    required this.winner,
    required this.playlist1,
    required this.playlist2,
    required this.sharedArtists,
    required this.sharedGenres,
    required this.sharedTracks,
    required this.audioData,
  });

  factory BattleResult.fromJson(Map<String, dynamic> json) {
    return BattleResult(
      compatibilityScore:
          json['compatibilityScore'] ?? json['compatibility_score'] ?? 0,
      winner: json['winner'] ?? 'tie',
      playlist1: BattlePlaylist.fromJson(
          (json['playlist1'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      playlist2: BattlePlaylist.fromJson(
          (json['playlist2'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      sharedArtists: (json['sharedArtists'] ?? json['shared_artists'] ?? [])
          .map<String>((a) => a.toString())
          .toList(),
      sharedGenres: (json['sharedGenres'] ?? json['shared_genres'] ?? [])
          .map<String>((g) => g.toString())
          .toList(),
      sharedTracks: (json['sharedTracks'] ?? json['shared_tracks'] ?? [])
          .map<SharedTrack>((t) => SharedTrack.fromJson(
              t is Map<String, dynamic>
                  ? Map<String, dynamic>.from(t)
                  : {'title': t.toString(), 'artist': ''}))
          .toList(),
      audioData: (json['audioData'] ?? json['audio_data'] ?? [])
          .map<Map<String, dynamic>>((d) => d is Map<String, dynamic>
              ? Map<String, dynamic>.from(d)
              : <String, dynamic>{})
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compatibilityScore': compatibilityScore,
      'winner': winner,
      'playlist1': playlist1.toJson(),
      'playlist2': playlist2.toJson(),
      'sharedArtists': sharedArtists,
      'sharedGenres': sharedGenres,
      'sharedTracks': sharedTracks.map((t) => t.toJson()).toList(),
      'audioData': audioData,
    };
  }
}
