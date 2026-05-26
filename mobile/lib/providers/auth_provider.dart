// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/auth_session.dart';
import '../models/google_auth_payload.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required GoogleAuthService googleAuthService,
    required SecureStorageService storageService,
  })  : _authService = authService,
        _googleAuthService = googleAuthService,
        _storageService = storageService;

  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final SecureStorageService _storageService;

  bool _isLoading = false;
  UserProfile? _currentUser;
  String? _token;

  bool get isLoading => _isLoading;
  UserProfile? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  String? get profilePhotoUrl => _googleAuthService.currentPhotoUrl;
  String get profileInitial =>
      (_currentUser?.username.trim().isNotEmpty ?? false)
          ? _currentUser!.username.trim().substring(0, 1).toUpperCase()
          : 'R';

  Future<bool> restoreSession() async {
    print('[Rakshati][AuthProvider] Starting session restore');
    _setLoading(true);

    try {
      final storedToken = await _storageService.readToken();

      if (storedToken == null || storedToken.isEmpty) {
        print('[Rakshati][AuthProvider] No stored token found');
        await _clearSession();
        return false;
      }

      final user = await _authService.getCurrentUser(
        storedToken,
        timeout: const Duration(seconds: 3),
      );

      _token = storedToken;
      _currentUser = user;
      print('[Rakshati][AuthProvider] Session restored for ${user.username}');
      notifyListeners();
      return true;
    } catch (error) {
      print('[Rakshati][AuthProvider] Session restore failed: $error');
      await _clearSession();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    print('[Rakshati][AuthProvider] Signup started for $username');
    _setLoading(true);
    try {
      final session = await _authService.signup(
        username: username,
        email: email,
        password: password,
      );
      await _persistSession(session);
      print('[Rakshati][AuthProvider] Signup succeeded for $username');
    } catch (error) {
      print('[Rakshati][AuthProvider] Signup failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    print('[Rakshati][AuthProvider] Login started for $email');
    _setLoading(true);
    try {
      final session = await _authService.login(
        email: email,
        password: password,
      );
      await _persistSession(session);
      print('[Rakshati][AuthProvider] Login succeeded for $email');
    } catch (error) {
      print('[Rakshati][AuthProvider] Login failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginAsGuest() async {
    print('[Rakshati][AuthProvider] Guest login started');
    _setLoading(true);
    try {
      final randomNumber = 1000 + Random().nextInt(9000);
      final session = await _authService.guestLogin('Guest_$randomNumber');
      await _persistSession(session);
      print('[Rakshati][AuthProvider] Guest login succeeded as ${session.user.username}');
    } catch (error) {
      print('[Rakshati][AuthProvider] Guest login failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<GoogleAuthPayload?> beginGoogleSignIn() async {
    print('[Rakshati][AuthProvider] Google sign-in start');
    _setLoading(true);
    try {
      final payload = await _googleAuthService.signIn();
      print(
        '[Rakshati][AuthProvider] Google sign-in payload received=${payload != null} idToken=${payload?.idToken == null ? 'missing' : 'present'}',
      );
      return payload;
    } catch (error) {
      print('[Rakshati][AuthProvider] Google sign-in failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle({
    required GoogleAuthPayload payload,
    String? username,
  }) async {
    print(
      '[Rakshati][AuthProvider] Google backend login started email=${payload.email} idToken=${payload.idToken == null ? 'missing' : 'present'}',
    );
    _setLoading(true);
    try {
      final session = await _authService.googleLogin(
        payload: payload,
        username: username,
      );
      await _persistSession(session);
      print('[Rakshati][AuthProvider] Google backend login succeeded for ${session.user.username}');
    } catch (error) {
      print('[Rakshati][AuthProvider] Google backend login failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    print('[Rakshati][AuthProvider] Logout started');
    await _authService.logout();
    await _googleAuthService.signOut();
    await _clearSession();
  }

  Future<void> _persistSession(AuthSession session) async {
    await _storageService.saveToken(session.token);
    _token = session.token;
    _currentUser = session.user;
    print('[Rakshati][AuthProvider] Persisted session for ${session.user.username}');
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _storageService.deleteToken();
    _token = null;
    _currentUser = null;
    print('[Rakshati][AuthProvider] Cleared session');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    print('[Rakshati][AuthProvider] Loading=$value');
    notifyListeners();
  }
}
