import 'location_history_point.dart';

class SafeWalkSession {
  const SafeWalkSession({
    required this.id,
    required this.destination,
    required this.startedAt,
    required this.status,
    required this.routePoints,
    required this.notifiedGuardianIds,
    required this.estimatedDurationLabel,
    required this.liveTrackingEnabled,
    required this.arrivalNotificationEnabled,
    required this.routeDeviationAlertsEnabled,
    required this.sosMonitoringEnabled,
  });

  final String id;
  final String destination;
  final DateTime startedAt;
  final String status;
  final List<LocationHistoryPoint> routePoints;
  final List<String> notifiedGuardianIds;
  final String estimatedDurationLabel;
  final bool liveTrackingEnabled;
  final bool arrivalNotificationEnabled;
  final bool routeDeviationAlertsEnabled;
  final bool sosMonitoringEnabled;
}
