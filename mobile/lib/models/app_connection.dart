class ConnectionPeer {
  const ConnectionPeer({
    required this.id,
    required this.username,
    required this.email,
    required this.authType,
  });

  final String id;
  final String username;
  final String? email;
  final String authType;

  factory ConnectionPeer.fromJson(Map<String, dynamic> json) {
    return ConnectionPeer(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      authType: json['authType'] as String,
    );
  }
}

class AppConnection {
  const AppConnection({
    required this.id,
    required this.relationshipType,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.status,
    required this.currentSafeWalkStatus,
    required this.peer,
  });

  final String id;
  final String relationshipType;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String status;
  final String currentSafeWalkStatus;
  final ConnectionPeer peer;

  factory AppConnection.fromJson(Map<String, dynamic> json) {
    return AppConnection(
      id: json['id'] as String,
      relationshipType: json['relationshipType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      status: json['status'] as String,
      currentSafeWalkStatus: json['currentSafeWalkStatus'] as String,
      peer: ConnectionPeer.fromJson(json['peer'] as Map<String, dynamic>),
    );
  }
}
