// ignore_for_file: avoid_print

import '../models/auth_session.dart';
import '../models/google_auth_payload.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class AuthService {
  AuthService() : _client = const ApiClient();

  final ApiClient _client;

  Future<AuthSession> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    print('[Rakshati][AuthService] Signing up user=$username email=$email');
    final response = await _client.post(
      '/auth/signup',
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    print('[Rakshati][AuthService] Logging in email=$email');
    final response = await _client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<AuthSession> guestLogin(String guestName) async {
    print('[Rakshati][AuthService] Guest login username=$guestName');
    final response = await _client.post(
      '/auth/guest',
      body: {
        'guestName': guestName,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<AuthSession> googleLogin({
    required GoogleAuthPayload payload,
    String? username,
  }) async {
    print(
      '[Rakshati][AuthService] Google login email=${payload.email} googleId=${payload.googleId} idToken=${payload.idToken == null ? 'missing' : 'present'}',
    );
    final response = await _client.post(
      '/auth/google',
      body: {
        'email': payload.email,
        'googleId': payload.googleId,
        'idToken': payload.idToken,
        if (username != null) 'username': username,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<UserProfile> getCurrentUser(
    String token, {
    Duration? timeout,
  }) async {
    print('[Rakshati][AuthService] Fetching current user for stored token');
    final response = await _client.get(
      '/auth/me',
      token: token,
      timeout: timeout,
    );

    return UserProfile.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    print('[Rakshati][AuthService] Logout requested');
  }
}
