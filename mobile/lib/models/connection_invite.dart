class ConnectionInvite {
  const ConnectionInvite({
    required this.id,
    required this.token,
    required this.relationshipType,
    required this.status,
    required this.expiresAt,
    required this.deepLink,
    required this.shareLink,
  });

  final String id;
  final String token;
  final String relationshipType;
  final String status;
  final DateTime expiresAt;
  final String deepLink;
  final String shareLink;

  factory ConnectionInvite.fromJson(Map<String, dynamic> json) {
    return ConnectionInvite(
      id: json['id'] as String,
      token: json['token'] as String,
      relationshipType: json['relationshipType'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      deepLink: json['deepLink'] as String,
      shareLink: json['shareLink'] as String,
    );
  }
}
