class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.authType,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String? email;
  final String authType;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      authType: json['authType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
