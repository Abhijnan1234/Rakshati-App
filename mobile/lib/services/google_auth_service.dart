// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/google_auth_payload.dart';
import 'api_exception.dart';
import 'app_config.dart';

class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              serverClientId: AppConfig.googleServerClientId,
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  String? get currentPhotoUrl => _firebaseAuth.currentUser?.photoURL;

  Future<GoogleAuthPayload?> signIn() async {
    print('[Rakshati][Google] Starting Google Sign-In flow');
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on FirebaseAuthException catch (error) {
      print('[Rakshati][Google] FirebaseAuthException code=${error.code} message=${error.message}');
      throw ApiException(
        error.message ??
            'Firebase rejected Google Sign-In. Check package name, SHA-1, and Google provider setup.',
        code: error.code,
      );
    } catch (error) {
      print('[Rakshati][Google] Account picker failed: $error');
      throw ApiException(
        'Google Sign-In failed before authentication. Verify Google Play services, package name, and Firebase configuration.',
        code: 'GOOGLE_SIGN_IN_FAILED',
      );
    }

    if (account == null) {
      print('[Rakshati][Google] User cancelled account picker');
      return null;
    }

    print('[Rakshati][Google] Account selected email=${account.email}');
    final authentication = await account.authentication;

    if (authentication.idToken == null && authentication.accessToken == null) {
      throw const ApiException(
        'Google authentication did not return a usable token. Check Firebase SHA-1 and Google provider setup.',
        code: 'GOOGLE_TOKEN_MISSING',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );

    print('[Rakshati][Google] Signing into Firebase Auth');
    UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      print('[Rakshati][Google] FirebaseAuthException during credential sign-in code=${error.code} message=${error.message}');
      throw ApiException(
        error.message ??
            'Firebase credential sign-in failed. Check Firebase app registration, SHA-1, and OAuth client configuration.',
        code: error.code,
      );
    }
    final user = userCredential.user;

    if (user == null || user.email == null) {
      throw const ApiException(
        'Firebase Google sign-in succeeded but no email was returned.',
        code: 'GOOGLE_EMAIL_MISSING',
      );
    }

    print('[Rakshati][Google] Firebase Auth success uid=${user.uid} email=${user.email}');
    return GoogleAuthPayload(
      email: user.email!,
      googleId: user.uid,
      idToken: authentication.idToken,
    );
  }

  Future<void> signOut() async {
    print('[Rakshati][Google] Signing out Firebase and Google session');
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
