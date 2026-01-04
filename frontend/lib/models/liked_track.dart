class LikedTrack {
  final String id;
  final String name;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  final String? spotifyId;
  final DateTime likedAt;
  final DateTime? expiresAt; // For guest users (7 days)

  LikedTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    this.spotifyId,
    required this.likedAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory LikedTrack.fromJson(Map<String, dynamic> json) {
    return LikedTrack(
      id: json['id'] ?? json['track_id'] ?? '',
      name: json['name'] ?? json['track_name'] ?? '',
      artist: json['artist'] ?? json['artist_name'] ?? '',
      albumArt: json['albumArt'] ?? json['album_art_url'],
      previewUrl: json['previewUrl'] ?? json['preview_url'],
      spotifyId: json['spotifyId'] ?? json['spotify_id'],
      likedAt: json['likedAt'] != null
          ? DateTime.parse(json['likedAt'])
          : json['liked_at'] != null
              ? DateTime.parse(json['liked_at'])
              : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : json['expires_at'] != null
              ? DateTime.parse(json['expires_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'albumArt': albumArt,
      'previewUrl': previewUrl,
      'spotifyId': spotifyId,
      'likedAt': likedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  LikedTrack copyWith({
    String? id,
    String? name,
    String? artist,
    String? albumArt,
    String? previewUrl,
    String? spotifyId,
    DateTime? likedAt,
    DateTime? expiresAt,
  }) {
    return LikedTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      previewUrl: previewUrl ?? this.previewUrl,
      spotifyId: spotifyId ?? this.spotifyId,
      likedAt: likedAt ?? this.likedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

