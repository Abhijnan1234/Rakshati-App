import 'user_profile.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final UserProfile user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
