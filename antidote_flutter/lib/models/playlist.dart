class Playlist {
  final int? id;
  final int? userId;
  final String spotifyId;
  final String name;
  final String? description;
  final String? owner;
  final String? coverUrl;
  final int? trackCount;
  final String url;
  final DateTime? analyzedAt;
  final DateTime createdAt;

  Playlist({
    this.id,
    this.userId,
    required this.spotifyId,
    required this.name,
    this.description,
    this.owner,
    this.coverUrl,
    this.trackCount,
    required this.url,
    this.analyzedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      userId: json['user_id'],
      spotifyId: json['spotify_id'],
      name: json['name'],
      description: json['description'],
      owner: json['owner'],
      coverUrl: json['cover_url'],
      trackCount: json['track_count'],
      url: json['url'],
      analyzedAt: json['analyzed_at'] != null 
        ? DateTime.parse(json['analyzed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spotify_id': spotifyId,
      'name': name,
      'description': description,
      'owner': owner,
      'cover_url': coverUrl,
      'track_count': trackCount,
      'url': url,
      'analyzed_at': analyzedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

