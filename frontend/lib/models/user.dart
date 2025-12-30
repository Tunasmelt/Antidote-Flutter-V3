class User {
  final String id; // Supabase uses UUID strings
  final String username;
  final String? email;
  final String? spotifyId;
  final String? avatarUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.spotifyId,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? json['name'] ?? '',
      email: json['email'],
      spotifyId: json['spotifyId'] ?? json['spotify_id'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      createdAt: json['createdAt'] != null 
        ? DateTime.tryParse(json['createdAt'])
        : json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'spotifyId': spotifyId,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

