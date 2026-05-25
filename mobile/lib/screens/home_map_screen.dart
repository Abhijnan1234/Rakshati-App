// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/location_history_point.dart';
import '../models/location_search_result.dart';
import '../models/saved_location.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../services/map_provider_interface.dart';
import '../services/open_street_map_provider.dart';
import '../services/shared_location_service.dart';
import '../utils/app_theme.dart';
import '../utils/snackbar.dart';
import '../widgets/floating_map_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/profile_avatar.dart';
import 'connections_screen.dart';
import 'location_history_settings_screen.dart';
import 'login_screen.dart';
import 'permission_flow_screen.dart';
import 'placeholder_detail_screen.dart';
import 'spectate_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen>
    with TickerProviderStateMixin {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();
  final MapProviderInterface _provider = const OpenStreetMapProvider();
  final SharedLocationService _sharedLocationService =
      const SharedLocationService();

  late final AnimationController _cameraAnimationController;
  Animation<LatLng>? _centerAnimation;
  Animation<double>? _zoomAnimation;
  Animation<double>? _rotationAnimation;

  StreamSubscription<LocationSearchResult>? _sharedLocationSubscription;
  bool _handledInitialSharedLocation = false;
  double _mapRotation = 0;

  @override
  void initState() {
    super.initState();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_handleCameraAnimation);
    _focus.addListener(_handleSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    _listenForSharedLocations();
  }

  @override
  void dispose() {
    _sharedLocationSubscription?.cancel();
    _cameraAnimationController.dispose();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final dash = context.read<DashboardProvider>();
    final loc = context.read<LocationProvider>();

    if (auth.token != null && auth.currentUser != null) {
      await dash.bootstrap(token: auth.token!, userId: auth.currentUser!.id);
    }

    final state = await loc.service.getPermissionState();
    if (!mounted) {
      return;
    }

    if (state != LocationPermissionState.granted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const PermissionFlowScreen(),
        ),
      );
      return;
    }

    await loc.refreshCurrentLocation();
    dash.updateLivePosition(loc.currentPosition);
    await _consumeInitialSharedLocation();
  }

  void _listenForSharedLocations() {
    _sharedLocationSubscription = _sharedLocationService
        .watchLocationImports()
        .listen((result) {
      if (!mounted) {
        return;
      }

      unawaited(_applySelectedResult(result, imported: true));
    }, onError: (error) {
      print('[Rakshati][Share] Shared location stream failed: $error');
    });
  }

  Future<void> _consumeInitialSharedLocation() async {
    if (_handledInitialSharedLocation) {
      return;
    }
    _handledInitialSharedLocation = true;

    final result = await _sharedLocationService.getInitialImport();
    if (!mounted || result == null) {
      return;
    }

    await _applySelectedResult(result, imported: true);
  }

  void _handleSearchFocusChange() {
    if (!_focus.hasFocus || !mounted) {
      return;
    }
    context.read<DashboardProvider>().showSearchPanel();
  }

  void _handleCameraAnimation() {
    final center = _centerAnimation?.value;
    if (center == null) {
      return;
    }

    final zoom = _zoomAnimation?.value ?? _currentZoomOr(16);
    final rotation = _rotationAnimation?.value ?? _mapRotation;
    _map.moveAndRotate(center, zoom, rotation);
  }

  double _currentZoomOr(double fallback) {
    try {
      return _map.camera.zoom;
    } catch (_) {
      return fallback;
    }
  }

  LatLng _currentCenterOr(LatLng fallback) {
    try {
      return _map.camera.center;
    } catch (_) {
      return fallback;
    }
  }

  void _animateCameraTo({
    required LatLng center,
    double? zoom,
    double? rotation,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    final currentCenter = _currentCenterOr(center);
    final currentZoom = _currentZoomOr(16);
    final currentRotation = _mapRotation;
    final targetZoom = zoom ?? currentZoom;
    final targetRotation = rotation ?? currentRotation;

    if (currentCenter == center &&
        (currentZoom - targetZoom).abs() < 0.01 &&
        (currentRotation - targetRotation).abs() < 0.1) {
      return;
    }

    final curve = CurvedAnimation(
      parent: _cameraAnimationController,
      curve: Curves.easeOutCubic,
    );
    _centerAnimation = _LatLngTween(
      begin: currentCenter,
      end: center,
    ).animate(curve);
    _zoomAnimation = Tween<double>(
      begin: currentZoom,
      end: targetZoom,
    ).animate(curve);
    _rotationAnimation = Tween<double>(
      begin: currentRotation,
      end: targetRotation,
    ).animate(curve);
    _cameraAnimationController
      ..duration = duration
      ..forward(from: 0);
  }

  void _updateRotation(double rotation) {
    final normalized = rotation.abs() < 0.5 ? 0.0 : rotation;
    if ((normalized - _mapRotation).abs() < 0.25) {
      return;
    }

    setState(() {
      _mapRotation = normalized;
    });
  }

  void _collapseSearchPanel() {
    FocusScope.of(context).unfocus();
    context.read<DashboardProvider>().hideSearchPanel();
  }

  Future<void> _recenter() async {
    final loc = context.read<LocationProvider>();
    final dash = context.read<DashboardProvider>();
    final existing = loc.currentPosition;

    if (existing != null) {
      _animateCameraTo(
        center: LatLng(existing.latitude, existing.longitude),
        zoom: _currentZoomOr(16) < 16 ? 16 : _currentZoomOr(16),
      );
    }

    await loc.refreshCurrentLocation();
    final latest = loc.currentPosition;
    if (latest == null) {
      if (mounted) {
        showAppSnackbar(
          context,
          loc.errorMessage ?? 'Unable to recenter right now.',
        );
      }
      return;
    }

    dash.updateLivePosition(latest);
    _animateCameraTo(
      center: LatLng(latest.latitude, latest.longitude),
      zoom: _currentZoomOr(16) < 16 ? 16 : _currentZoomOr(16),
    );
  }

  Future<void> _logout() async {
    context.read<DashboardProvider>().clearSessionState();
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _applySelectedResult(
    LocationSearchResult result, {
    bool imported = false,
  }) async {
    await context.read<DashboardProvider>().chooseSearchResult(result);
    _search.text = result.title;
    _search.selection = TextSelection.collapsed(offset: _search.text.length);
    _collapseSearchPanel();
    _animateCameraTo(
      center: LatLng(result.latitude, result.longitude),
      zoom: _currentZoomOr(16) < 16 ? 16 : _currentZoomOr(16),
    );

    if (mounted && imported) {
      showAppSnackbar(context, 'Imported from Google Maps');
    }
  }

  Future<void> _pickResult(LocationSearchResult result) {
    return _applySelectedResult(result);
  }

  Future<void> _savePoint() async {
    final dash = context.read<DashboardProvider>();
    final name = TextEditingController();
    var category = 'Custom';
    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setLocal) => AlertDialog(
              title: const Text('Save Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Location Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const [
                      'Home',
                      'College',
                      'Work',
                      'Hospital',
                      'Custom',
                    ]
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setLocal(() => category = value ?? 'Custom'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!ok) {
      return;
    }

    try {
      await dash.saveSelectedLocation(
        name: name.text.trim().isEmpty ? 'Saved Place' : name.text.trim(),
        category: category,
      );
      if (!mounted) {
        return;
      }
      showAppSnackbar(context, 'Location saved.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackbar(context, 'Unable to save location.');
    }
  }

  Future<void> _safeWalk([String? destination]) async {
    final dash = context.read<DashboardProvider>();
    final dest = TextEditingController(
      text: destination ?? dash.selectedSearchResult?.title ?? '',
    );
    final eta = TextEditingController(text: '20 minutes');
    final picked = <String>{};
    var live = true;
    var arrival = true;
    var deviation = true;
    var sos = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start SafeWalk',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dest,
                  decoration: const InputDecoration(labelText: 'Destination'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eta,
                  decoration: const InputDecoration(
                    labelText: 'Estimated duration',
                  ),
                ),
                const SizedBox(height: 10),
                ...dash.guardians.map(
                  (guardian) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: picked.contains(guardian.peer.id),
                    onChanged: (value) => setLocal(
                      () => value == true
                          ? picked.add(guardian.peer.id)
                          : picked.remove(guardian.peer.id),
                    ),
                    title: Text(guardian.peer.username),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: live,
                  onChanged: (value) => setLocal(() => live = value),
                  title: const Text('Enable Live Tracking'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: arrival,
                  onChanged: (value) => setLocal(() => arrival = value),
                  title: const Text('Enable Arrival Notification'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deviation,
                  onChanged: (value) => setLocal(() => deviation = value),
                  title: const Text('Enable Route Deviation Alerts'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: sos,
                  onChanged: (value) => setLocal(() => sos = value),
                  title: const Text('Enable SOS Monitoring'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await dash.startSafeWalk(
                        destination: dest.text.trim().isEmpty
                            ? 'Selected destination'
                            : dest.text.trim(),
                        estimatedDurationLabel: eta.text.trim().isEmpty
                            ? '20 minutes'
                            : eta.text.trim(),
                        guardianIds: picked.toList(),
                        liveTrackingEnabled: live,
                        arrivalNotificationEnabled: arrival,
                        routeDeviationAlertsEnabled: deviation,
                        sosMonitoringEnabled: sos,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      if (!mounted) {
                        return;
                      }
                      showAppSnackbar(context, 'SafeWalk started.');
                    },
                    child: const Text('Start SafeWalk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pinActions() async {
    final selected = context.read<DashboardProvider>().selectedSearchResult;
    if (selected == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(selected.title),
                subtitle: Text(selected.subtitle),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: const Text('Save Location'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _savePoint();
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_walk),
                title: const Text('Start SafeWalk To Here'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _safeWalk(selected.title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation_outlined),
                title: const Text('Navigate'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAppSnackbar(
                    context,
                    'Navigation handoff is placeholder-ready.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savedActions(SavedLocation location) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(location.name),
                subtitle: Text(location.category),
              ),
              ListTile(
                leading: const Icon(Icons.directions_walk),
                title: const Text('Start SafeWalk'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _safeWalk(location.name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Saved Location'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context
                      .read<DashboardProvider>()
                      .deleteSavedLocation(location.id);
                  if (mounted) {
                    showAppSnackbar(context, 'Saved location deleted.');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _profileAction(String action) {
    Widget page(String title, String description,
        [IconData icon = Icons.shield_outlined]) {
      return PlaceholderDetailScreen(
        title: title,
        description: description,
        icon: icon,
      );
    }

    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Profile',
              'Profile overview and safety status will live here.',
            ),
          ),
        );
        return;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Edit Profile',
              'Profile image uploads and details editing are scaffolded.',
              Icons.edit_outlined,
            ),
          ),
        );
        return;
      case 'guardians':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ConnectionsScreen(initialTabIndex: 0),
          ),
        );
        return;
      case 'walkers':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ConnectionsScreen(initialTabIndex: 1),
          ),
        );
        return;
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Notifications',
              'Arrival alerts and deviation rules will appear here.',
              Icons.notifications_none,
            ),
          ),
        );
        return;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const LocationHistorySettingsScreen(),
          ),
        );
        return;
      case 'privacy':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Privacy & Security',
              'Trusted-circle visibility and security controls are scaffolded.',
              Icons.lock_outline,
            ),
          ),
        );
        return;
      case 'emergency':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Emergency Contacts',
              'Emergency contact management is ready for the next sync step.',
              Icons.contact_phone_outlined,
            ),
          ),
        );
        return;
      case 'theme':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Theme',
              'Theme presets and accessibility tuning will expand from this foundation.',
              Icons.palette_outlined,
            ),
          ),
        );
        return;
      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'Help',
              'Guides for SafeWalk, invites, and SOS will appear here.',
              Icons.help_outline,
            ),
          ),
        );
        return;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => page(
              'About Rakshati',
              'Rakshati is evolving into a live safety companion.\n\nMap data © OpenStreetMap contributors.',
              Icons.info_outline,
            ),
          ),
        );
        return;
      case 'logout':
        _logout();
        return;
    }
  }

  Color _ageColor(Duration age) {
    if (age <= const Duration(hours: 1)) {
      return const Color(0xD94285F4);
    }
    if (age <= const Duration(hours: 3)) {
      return const Color(0xB24D93F7);
    }
    if (age <= const Duration(hours: 6)) {
      return const Color(0x8C81A9F8);
    }
    return const Color(0x807A7F89);
  }

  List<Polyline> _polylines(List<LocationHistoryPoint> points) {
    if (points.length < 2) {
      return <Polyline>[];
    }

    final now = DateTime.now();
    final polylines = <Polyline>[];
    var chunk = <LatLng>[
      LatLng(points.first.latitude, points.first.longitude),
    ];
    var color = _ageColor(now.difference(points[1].timestamp));

    for (var index = 1; index < points.length; index++) {
      final next = LatLng(points[index].latitude, points[index].longitude);
      final nextColor = _ageColor(now.difference(points[index].timestamp));
      if (nextColor.toARGB32() != color.toARGB32()) {
        if (chunk.length > 1) {
          polylines.add(
            Polyline(
              points: List<LatLng>.from(chunk),
              strokeWidth: 7,
              color: color,
              borderStrokeWidth: 3,
              borderColor: Colors.black.withValues(alpha: 0.18),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          );
        }
        chunk = <LatLng>[
          LatLng(points[index - 1].latitude, points[index - 1].longitude),
          next,
        ];
        color = nextColor;
      } else {
        chunk.add(next);
      }
    }

    if (chunk.length > 1) {
      polylines.add(
        Polyline(
          points: List<LatLng>.from(chunk),
          strokeWidth: 7,
          color: color,
          borderStrokeWidth: 3,
          borderColor: Colors.black.withValues(alpha: 0.18),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final authMenuData =
        context.select<AuthProvider, ({String initial, String? imageUrl})>(
      (auth) => (
        initial: auth.profileInitial,
        imageUrl: auth.profilePhotoUrl,
      ),
    );
    final isBootstrapping =
        context.select<DashboardProvider, bool>((dash) => dash.isBootstrapping);
    final isLocationLoading =
        context.select<LocationProvider, bool>((loc) => loc.isLoading);
    final errorMessage =
        context.select<LocationProvider, String?>((loc) => loc.errorMessage);
    final position = context.select<LocationProvider, dynamic>(
      (loc) => loc.currentPosition,
    );

    if (position == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocationLoading || isBootstrapping)
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.location_searching, size: 44),
                  const SizedBox(height: 16),
                  Text(
                    (isLocationLoading || isBootstrapping)
                        ? 'Preparing your live safety dashboard...'
                        : 'We could not load your location.',
                    textAlign: TextAlign.center,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _init,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final here = LatLng(position.latitude, position.longitude);
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final bottomSafeInset = media.padding.bottom;
    final bottomControlsOffset =
        16 + (keyboardInset > 0 ? keyboardInset : bottomSafeInset);
    final searchPanelMaxHeight = (media.size.height -
            media.padding.top -
            keyboardInset -
            250)
        .clamp(170.0, 360.0)
        .toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Selector<DashboardProvider,
              ({
                List<SavedLocation> savedLocations,
                List<LocationHistoryPoint> historyPoints,
                LatLng? selectedPoint,
              })>(
            selector: (_, dash) => (
              savedLocations: dash.savedLocations,
              historyPoints: dash.historyPoints,
              selectedPoint: dash.selectedPoint,
            ),
            builder: (_, mapData, __) => FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: here,
                initialZoom: 16,
                initialRotation: 0,
                onTap: (_, point) {
                  _collapseSearchPanel();
                  context.read<DashboardProvider>().setSelectedPoint(point);
                },
                onPositionChanged: (camera, hasGesture) {
                  _updateRotation(camera.rotation);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _provider.tileUrlTemplate,
                  userAgentPackageName: _provider.userAgentPackageName,
                ),
                if (mapData.historyPoints.length > 1)
                  PolylineLayer(polylines: _polylines(mapData.historyPoints)),
                MarkerLayer(
                  markers: [
                    ...mapData.savedLocations.map(
                      (location) => Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 56,
                        height: 72,
                        rotate: true,
                        child: GestureDetector(
                          onTap: () => _savedActions(location),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.greenAccent,
                                size: 36,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  location.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (mapData.selectedPoint != null)
                      Marker(
                        point: mapData.selectedPoint!,
                        width: 46,
                        height: 60,
                        rotate: true,
                        child: GestureDetector(
                          onTap: _pinActions,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppTheme.accent,
                            size: 42,
                          ),
                        ),
                      ),
                    Marker(
                      point: here,
                      width: 58,
                      height: 58,
                      rotate: true,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Selector<DashboardProvider,
                    ({
                      bool isOpen,
                      bool isSearching,
                      String? searchError,
                      List<LocationSearchResult> recent,
                      List<LocationSearchResult> saved,
                      List<LocationSearchResult> online,
                    })>(
                  selector: (_, dash) => (
                    isOpen: dash.isSearchPanelOpen,
                    isSearching: dash.isSearching,
                    searchError: dash.searchError,
                    recent: dash.recentMatches,
                    saved: dash.savedSearchResults,
                    online: dash.onlineSearchResults,
                  ),
                  builder: (_, searchData, __) => _SearchOverlay(
                    authMenuData: authMenuData,
                    controller: _search,
                    focusNode: _focus,
                    isSearchOpen: searchData.isOpen,
                    isSearching: searchData.isSearching,
                    searchError: searchData.searchError,
                    recent: searchData.recent,
                    saved: searchData.saved,
                    online: searchData.online,
                    searchPanelMaxHeight: searchPanelMaxHeight,
                    mapRotation: _mapRotation,
                    onChanged: (value) =>
                        context.read<DashboardProvider>().setSearchQuery(value),
                    onClear: () {
                      _search.clear();
                      context.read<DashboardProvider>().setSearchQuery('');
                      context.read<DashboardProvider>().showSearchPanel();
                    },
                    onCompassTap: () => _animateCameraTo(
                      center: _currentCenterOr(here),
                      zoom: _currentZoomOr(16),
                      rotation: 0,
                    ),
                    onSelectResult: _pickResult,
                    onProfileAction: _profileAction,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomControlsOffset,
            child: SafeArea(
              top: false,
              child: Selector<DashboardProvider, String?>(
                selector: (_, dash) => dash.activeSafeWalk?.destination,
                builder: (_, activeDestination, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activeDestination != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassPanel(
                          child: ListTile(
                            leading: const Icon(
                              Icons.directions_walk,
                              color: AppTheme.accent,
                            ),
                            title: const Text('SafeWalk Active'),
                            subtitle: Text(activeDestination),
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingMapButton(
                              icon: Icons.visibility_outlined,
                              label: 'Spectate',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const SpectateScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FloatingMapButton(
                              icon: Icons.group_add_outlined,
                              label: 'Connections',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const ConnectionsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingMapButton(
                              icon: Icons.directions_walk,
                              label: 'Start SafeWalk',
                              onTap: () => _safeWalk(),
                            ),
                            const SizedBox(height: 12),
                            FloatingMapButton(
                              icon: Icons.my_location,
                              onTap: _recenter,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.authMenuData,
    required this.controller,
    required this.focusNode,
    required this.isSearchOpen,
    required this.isSearching,
    required this.searchError,
    required this.recent,
    required this.saved,
    required this.online,
    required this.searchPanelMaxHeight,
    required this.mapRotation,
    required this.onChanged,
    required this.onClear,
    required this.onCompassTap,
    required this.onSelectResult,
    required this.onProfileAction,
  });

  final ({String initial, String? imageUrl}) authMenuData;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearchOpen;
  final bool isSearching;
  final String? searchError;
  final List<LocationSearchResult> recent;
  final List<LocationSearchResult> saved;
  final List<LocationSearchResult> online;
  final double searchPanelMaxHeight;
  final double mapRotation;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCompassTap;
  final Future<void> Function(LocationSearchResult result) onSelectResult;
  final ValueChanged<String> onProfileAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search Location...',
                    border: InputBorder.none,
                    isCollapsed: true,
                    suffixIcon: controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClear,
                            splashRadius: 18,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onProfileAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                  PopupMenuItem(
                    value: 'guardians',
                    child: Text('Manage Guardians'),
                  ),
                  PopupMenuItem(
                    value: 'walkers',
                    child: Text('Manage SafeWalkers'),
                  ),
                  PopupMenuItem(
                    value: 'notifications',
                    child: Text('Notifications'),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Text('Location History Settings'),
                  ),
                  PopupMenuItem(
                    value: 'privacy',
                    child: Text('Privacy & Security'),
                  ),
                  PopupMenuItem(
                    value: 'emergency',
                    child: Text('Emergency Contacts'),
                  ),
                  PopupMenuItem(value: 'theme', child: Text('Theme')),
                  PopupMenuItem(value: 'help', child: Text('Help')),
                  PopupMenuItem(
                    value: 'about',
                    child: Text('About Rakshati'),
                  ),
                  PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
                child: ProfileAvatar(
                  initial: authMenuData.initial,
                  imageUrl: authMenuData.imageUrl,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: mapRotation == 0
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topLeft,
                  child: _RoundGlassButton(
                    key: const ValueKey('compass'),
                    icon: Icons.explore,
                    size: 44,
                    onTap: onCompassTap,
                  ),
                ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: isSearchOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    constraints: BoxConstraints(maxHeight: searchPanelMaxHeight),
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _SearchResultsSheet(
                        recent: recent,
                        saved: saved,
                        online: online,
                        isSearching: isSearching,
                        errorText: searchError,
                        onSelect: onSelectResult,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SearchResultsSheet extends StatelessWidget {
  const _SearchResultsSheet({
    required this.recent,
    required this.saved,
    required this.online,
    required this.isSearching,
    required this.errorText,
    required this.onSelect,
  });

  final List<LocationSearchResult> recent;
  final List<LocationSearchResult> saved;
  final List<LocationSearchResult> online;
  final bool isSearching;
  final String? errorText;
  final Future<void> Function(LocationSearchResult result) onSelect;

  @override
  Widget build(BuildContext context) {
    final hasResults =
        recent.isNotEmpty || saved.isNotEmpty || online.isNotEmpty;

    if (!hasResults && !isSearching && errorText == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          'Search places, saved destinations, or nearby landmarks.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        if (recent.isNotEmpty)
          _SearchSection(title: 'Recent', results: recent, onSelect: onSelect),
        if (saved.isNotEmpty)
          _SearchSection(title: 'Saved', results: saved, onSelect: onSelect),
        if (online.isNotEmpty)
          _SearchSection(title: 'Online', results: online, onSelect: onSelect),
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
      ],
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.title,
    required this.results,
    required this.onSelect,
  });

  final String title;
  final List<LocationSearchResult> results;
  final Future<void> Function(LocationSearchResult result) onSelect;

  @override
  Widget build(BuildContext context) {
    IconData iconFor(LocationSearchSource source) => switch (source) {
          LocationSearchSource.saved => Icons.bookmark_rounded,
          LocationSearchSource.recent => Icons.history,
          LocationSearchSource.online => Icons.public,
          LocationSearchSource.temporary => Icons.location_pin,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        ...results.map(
          (result) => ListTile(
            leading: Icon(iconFor(result.source), color: Colors.white70),
            title: Text(
              result.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              result.subtitle.isEmpty ? result.sourceLabel : result.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(result),
          ),
        ),
      ],
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: GlassPanel(
          padding: EdgeInsets.all((size - 20) / 2),
          borderRadius: size / 2,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({
    required LatLng begin,
    required LatLng end,
  }) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
