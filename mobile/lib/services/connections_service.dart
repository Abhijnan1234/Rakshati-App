// ignore_for_file: avoid_print

import '../models/app_connection.dart';
import '../models/connection_invite.dart';
import 'api_client.dart';

class ConnectionsSnapshot {
  const ConnectionsSnapshot({
    required this.guardians,
    required this.safeWalkers,
    required this.invites,
  });

  final List<AppConnection> guardians;
  final List<AppConnection> safeWalkers;
  final List<ConnectionInvite> invites;
}

class ConnectionsService {
  ConnectionsService() : _client = const ApiClient();

  final ApiClient _client;

  Future<ConnectionsSnapshot> getConnections(String token) async {
    print('[Rakshati][ConnectionsService] Fetching connections');
    final response = await _client.get('/connections', token: token);

    List<AppConnection> parseConnections(String key) {
      final list = response[key] as List<dynamic>? ?? <dynamic>[];
      return list
          .map((item) => AppConnection.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final rawInvites = response['invites'] as List<dynamic>? ?? <dynamic>[];
    return ConnectionsSnapshot(
      guardians: parseConnections('guardians'),
      safeWalkers: parseConnections('safeWalkers'),
      invites: rawInvites
          .map((item) => ConnectionInvite.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ConnectionInvite> createInvite({
    required String token,
    required String relationshipType,
  }) async {
    print('[Rakshati][ConnectionsService] Creating invite relationshipType=$relationshipType');
    final response = await _client.post(
      '/connections/invite',
      token: token,
      body: {
        'relationshipType': relationshipType,
      },
    );

    return ConnectionInvite.fromJson(response['invite'] as Map<String, dynamic>);
  }

  Future<void> acceptInvite({
    required String token,
    required String inviteToken,
  }) async {
    print('[Rakshati][ConnectionsService] Accepting invite token=$inviteToken');
    await _client.post(
      '/connections/accept',
      token: token,
      body: {
        'token': inviteToken,
      },
    );
  }

  Future<void> deleteConnection({
    required String token,
    required String connectionId,
  }) async {
    print('[Rakshati][ConnectionsService] Deleting connection=$connectionId');
    await _client.delete('/connections/$connectionId', token: token);
  }
}
