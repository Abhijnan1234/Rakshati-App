// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_connection.dart';
import '../models/connection_invite.dart';
import '../models/location_history_point.dart';
import '../models/location_history_settings.dart';
import '../models/location_search_result.dart';
import '../models/safe_walk_session.dart';
import '../models/saved_location.dart';
import '../services/connections_service.dart';
import '../services/saved_location_service.dart';
import '../services/search_service.dart';
import '../services/secure_storage_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required SavedLocationService savedLocationService,
    required ConnectionsService connectionsService,
    required SearchService searchService,
    required SecureStorageService storageService,
  })  : _savedLocationService = savedLocationService,
        _connectionsService = connectionsService,
        _searchService = searchService,
        _storageService = storageService;

  static const String _recentSearchesKey = 'rakshati_recent_searches';
  static const String _historySettingsKey = 'rakshati_history_settings';

  final SavedLocationService _savedLocationService;
  final ConnectionsService _connectionsService;
  final SearchService _searchService;
  final SecureStorageService _storageService;
  final Distance _distance = const Distance();

  String? _token;
  bool _isBootstrapping = false;
  bool _isSavingLocation = false;
  bool _isSearching = false;
  bool _isLoadingConnections = false;
  bool _isSearchPanelOpen = false;
  String _searchQuery = '';
  String? _searchError;
  String? _dashboardError;
  Position? _latestPosition;
  LatLng? _selectedPoint;
  LocationSearchResult? _selectedSearchResult;
  List<SavedLocation> _savedLocations = <SavedLocation>[];
  List<AppConnection> _guardians = <AppConnection>[];
  List<AppConnection> _safeWalkers = <AppConnection>[];
  List<ConnectionInvite> _invites = <ConnectionInvite>[];
  List<LocationSearchResult> _recentSearches = <LocationSearchResult>[];
  List<LocationSearchResult> _recentMatches = <LocationSearchResult>[];
  List<LocationSearchResult> _savedSearchResults = <LocationSearchResult>[];
  List<LocationSearchResult> _onlineSearchResults = <LocationSearchResult>[];
  List<LocationHistoryPoint> _historyPoints = <LocationHistoryPoint>[];
  LocationHistorySettings _historySettings = const LocationHistorySettings();
  SafeWalkSession? _activeSafeWalk;
  Timer? _searchDebounce;
  Timer? _trackingTimer;
  String? _bootstrappedForUserId;

  bool get isBootstrapping => _isBootstrapping;
  bool get isSavingLocation => _isSavingLocation;
  bool get isSearching => _isSearching;
  bool get isLoadingConnections => _isLoadingConnections;
  bool get isSearchPanelOpen => _isSearchPanelOpen;
  String get searchQuery => _searchQuery;
  String? get searchError => _searchError;
  String? get dashboardError => _dashboardError;
  LatLng? get selectedPoint => _selectedPoint;
  LocationSearchResult? get selectedSearchResult => _selectedSearchResult;
  List<SavedLocation> get savedLocations => List.unmodifiable(_savedLocations);
  List<AppConnection> get guardians => List.unmodifiable(_guardians);
  List<AppConnection> get safeWalkers => List.unmodifiable(_safeWalkers);
  List<ConnectionInvite> get invites => List.unmodifiable(_invites);
  List<LocationSearchResult> get recentMatches => List.unmodifiable(_recentMatches);
  List<LocationSearchResult> get savedSearchResults => List.unmodifiable(_savedSearchResults);
  List<LocationSearchResult> get onlineSearchResults => List.unmodifiable(_onlineSearchResults);
  List<LocationHistoryPoint> get historyPoints => List.unmodifiable(_historyPoints);
  LocationHistorySettings get historySettings => _historySettings;
  SafeWalkSession? get activeSafeWalk => _activeSafeWalk;
  bool get hasSearchResults =>
      _recentMatches.isNotEmpty ||
      _savedSearchResults.isNotEmpty ||
      _onlineSearchResults.isNotEmpty ||
      _isSearching;

  void showSearchPanel() {
    _isSearchPanelOpen = true;
    _recentMatches = _searchService.searchRecent(_searchQuery, _recentSearches);
    _savedSearchResults = _searchService.searchSaved(_searchQuery, _savedLocations);
    notifyListeners();
  }

  void hideSearchPanel() {
    _searchDebounce?.cancel();
    _isSearchPanelOpen = false;
    _onlineSearchResults = <LocationSearchResult>[];
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }

  Future<void> bootstrap({
    required String token,
    required String userId,
  }) async {
    if (_bootstrappedForUserId == userId && _token == token) {
      return;
    }

    print('[Rakshati][DashboardProvider] Bootstrapping dashboard userId=$userId');
    _token = token;
    _bootstrappedForUserId = userId;
    _isBootstrapping = true;
    _dashboardError = null;
    notifyListeners();

    try {
      await Future.wait([
        _restoreRecentSearches(),
        _restoreHistorySettings(),
        refreshSavedLocations(),
        refreshConnections(),
      ]);
      _startTrackingTimer();
    } catch (error) {
      _dashboardError = 'Unable to load your dashboard right now.';
      print('[Rakshati][DashboardProvider] Bootstrap failed: $error');
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> refreshSavedLocations() async {
    if (_token == null) {
      return;
    }

    print('[Rakshati][DashboardProvider] Refreshing saved locations');
    _savedLocations = await _savedLocationService.getLocations(_token!);
    _savedSearchResults = _searchService.searchSaved(_searchQuery, _savedLocations);
    notifyListeners();
  }

  Future<void> refreshConnections() async {
    if (_token == null) {
      return;
    }

    print('[Rakshati][DashboardProvider] Refreshing connections');
    _isLoadingConnections = true;
    notifyListeners();

    try {
      final snapshot = await _connectionsService.getConnections(_token!);
      _guardians = snapshot.guardians;
      _safeWalkers = snapshot.safeWalkers;
      _invites = snapshot.invites;
    } finally {
      _isLoadingConnections = false;
      notifyListeners();
    }
  }

  void updateLivePosition(Position? position) {
    if (position == null) {
      return;
    }

    _latestPosition = position;
    if (_historyPoints.isEmpty) {
      _appendHistoryPoint(position);
      return;
    }

    final latestPoint = _historyPoints.last;
    final movedMeters = _distance.as(
      LengthUnit.Meter,
      LatLng(latestPoint.latitude, latestPoint.longitude),
      LatLng(position.latitude, position.longitude),
    );

    if (movedMeters >= 25) {
      _appendHistoryPoint(position);
    }
  }

  void setSelectedPoint(
    LatLng point, {
    LocationSearchResult? fromResult,
  }) {
    _selectedPoint = point;
    _selectedSearchResult = fromResult ??
        LocationSearchResult(
          id: 'temporary-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Pinned location',
          subtitle: '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
          latitude: point.latitude,
          longitude: point.longitude,
          source: LocationSearchSource.temporary,
        );
    notifyListeners();
  }

  void clearSelectedPoint() {
    _selectedPoint = null;
    _selectedSearchResult = null;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _isSearchPanelOpen = true;
    _recentMatches = _searchService.searchRecent(value, _recentSearches);
    _savedSearchResults = _searchService.searchSaved(value, _savedLocations);
    _searchError = null;

    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      _onlineSearchResults = <LocationSearchResult>[];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _onlineSearchResults = await _searchService.searchOnline(value);
      } catch (error) {
        _searchError = 'Search is temporarily unavailable.';
        print('[Rakshati][DashboardProvider] Search failed: $error');
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  Future<void> chooseSearchResult(LocationSearchResult result) async {
    print('[Rakshati][DashboardProvider] Choosing search result title=${result.title}');
    _searchQuery = result.title;
    setSelectedPoint(
      LatLng(result.latitude, result.longitude),
      fromResult: result,
    );

    final withoutDuplicate = _recentSearches
        .where((item) => item.title != result.title || item.subtitle != result.subtitle)
        .toList();
    _recentSearches = [
      result.source == LocationSearchSource.recent
          ? result
          : LocationSearchResult(
              id: result.id,
              title: result.title,
              subtitle: result.subtitle,
              latitude: result.latitude,
              longitude: result.longitude,
              source: LocationSearchSource.recent,
              category: result.category,
            ),
      ...withoutDuplicate,
    ].take(8).toList();
    _recentMatches = _searchService.searchRecent(_searchQuery, _recentSearches);
    _savedSearchResults = _searchService.searchSaved(_searchQuery, _savedLocations);
    _onlineSearchResults = <LocationSearchResult>[];
    _searchError = null;
    _isSearching = false;
    _isSearchPanelOpen = false;
    await _persistRecentSearches();
    notifyListeners();
  }

  Future<void> saveSelectedLocation({
    required String name,
    required String category,
  }) async {
    if (_token == null || _selectedPoint == null) {
      return;
    }

    _isSavingLocation = true;
    notifyListeners();
    try {
      final location = await _savedLocationService.saveLocation(
        token: _token!,
        name: name,
        category: category,
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
      );
      _savedLocations = [location, ..._savedLocations];
      _savedSearchResults = _searchService.searchSaved(_searchQuery, _savedLocations);
      print('[Rakshati][DashboardProvider] Selected point saved id=${location.id}');
    } finally {
      _isSavingLocation = false;
      notifyListeners();
    }
  }

  Future<void> deleteSavedLocation(String id) async {
    if (_token == null) {
      return;
    }

    await _savedLocationService.deleteLocation(
      token: _token!,
      locationId: id,
    );
    _savedLocations = _savedLocations.where((item) => item.id != id).toList();
    _savedSearchResults = _searchService.searchSaved(_searchQuery, _savedLocations);
    notifyListeners();
  }

  Future<ConnectionInvite> createInvite(String relationshipType) async {
    if (_token == null) {
      throw StateError('Authentication token missing.');
    }

    final invite = await _connectionsService.createInvite(
      token: _token!,
      relationshipType: relationshipType,
    );
    _invites = [invite, ..._invites];
    notifyListeners();
    return invite;
  }

  Future<void> acceptInvite(String inviteToken) async {
    if (_token == null) {
      throw StateError('Authentication token missing.');
    }

    await _connectionsService.acceptInvite(
      token: _token!,
      inviteToken: inviteToken,
    );
    await refreshConnections();
  }

  Future<void> deleteConnection(String connectionId) async {
    if (_token == null) {
      return;
    }

    await _connectionsService.deleteConnection(
      token: _token!,
      connectionId: connectionId,
    );
    await refreshConnections();
  }

  Future<void> updateHistorySettings(LocationHistorySettings settings) async {
    _historySettings = settings;
    await _storageService.writeString(
      key: _historySettingsKey,
      value: jsonEncode(settings.toJson()),
    );
    _trimHistory();
    _startTrackingTimer();
    notifyListeners();
  }

  Future<void> startSafeWalk({
    required String destination,
    required String estimatedDurationLabel,
    required List<String> guardianIds,
    required bool liveTrackingEnabled,
    required bool arrivalNotificationEnabled,
    required bool routeDeviationAlertsEnabled,
    required bool sosMonitoringEnabled,
  }) async {
    _activeSafeWalk = SafeWalkSession(
      id: 'safe-walk-${DateTime.now().millisecondsSinceEpoch}',
      destination: destination,
      startedAt: DateTime.now(),
      status: 'Active',
      routePoints: List<LocationHistoryPoint>.from(_historyPoints),
      notifiedGuardianIds: guardianIds,
      estimatedDurationLabel: estimatedDurationLabel,
      liveTrackingEnabled: liveTrackingEnabled,
      arrivalNotificationEnabled: arrivalNotificationEnabled,
      routeDeviationAlertsEnabled: routeDeviationAlertsEnabled,
      sosMonitoringEnabled: sosMonitoringEnabled,
    );
    print('[Rakshati][DashboardProvider] Started placeholder SafeWalk destination=$destination');
    notifyListeners();
  }

  void clearSessionState() {
    print('[Rakshati][DashboardProvider] Clearing dashboard state');
    _token = null;
    _bootstrappedForUserId = null;
    _searchQuery = '';
    _searchError = null;
    _isSearchPanelOpen = false;
    _recentSearches = <LocationSearchResult>[];
    _selectedPoint = null;
    _selectedSearchResult = null;
    _savedLocations = <SavedLocation>[];
    _guardians = <AppConnection>[];
    _safeWalkers = <AppConnection>[];
    _invites = <ConnectionInvite>[];
    _onlineSearchResults = <LocationSearchResult>[];
    _savedSearchResults = <LocationSearchResult>[];
    _recentMatches = <LocationSearchResult>[];
    _historyPoints = <LocationHistoryPoint>[];
    _activeSafeWalk = null;
    _latestPosition = null;
    _searchDebounce?.cancel();
    _trackingTimer?.cancel();
    notifyListeners();
  }

  Future<void> _restoreRecentSearches() async {
    final raw = await _storageService.readString(_recentSearchesKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    _recentSearches = decoded
        .map((item) => LocationSearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
    _recentMatches = _searchService.searchRecent(_searchQuery, _recentSearches);
  }

  Future<void> _persistRecentSearches() {
    return _storageService.writeString(
      key: _recentSearchesKey,
      value: jsonEncode(_recentSearches.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _restoreHistorySettings() async {
    final raw = await _storageService.readString(_historySettingsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    _historySettings = LocationHistorySettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  void _appendHistoryPoint(Position position) {
    _historyPoints = [
      ..._historyPoints,
      LocationHistoryPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      ),
    ];
    _trimHistory();
    notifyListeners();
  }

  void _trimHistory() {
    final cutoff = DateTime.now().subtract(_historySettings.retentionDuration);
    _historyPoints = _historyPoints
        .where((point) => point.timestamp.isAfter(cutoff))
        .toList();
  }

  void _startTrackingTimer() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(_historySettings.trackingDuration, (_) {
      final latestPosition = _latestPosition;
      if (latestPosition != null) {
        _appendHistoryPoint(latestPosition);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _trackingTimer?.cancel();
    super.dispose();
  }
}
