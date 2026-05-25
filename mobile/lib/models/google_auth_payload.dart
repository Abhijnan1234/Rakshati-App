class GoogleAuthPayload {
  const GoogleAuthPayload({
    required this.email,
    required this.googleId,
    this.idToken,
  });

  final String email;
  final String googleId;
  final String? idToken;
}
