// ignore_for_file: avoid_print

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationService {
  const LocationService();

  Future<LocationPermissionState> getPermissionState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[Rakshati][Location] Service disabled');
      return LocationPermissionState.serviceDisabled;
    }

    final status = await Permission.locationWhenInUse.status;
    print('[Rakshati][Location] Current permission status=$status');
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionState.permanentlyDenied;
    }
    return LocationPermissionState.denied;
  }

  Future<LocationPermissionState> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    print('[Rakshati][Location] Requested permission status=$status');
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionState.permanentlyDenied;
    }
    return LocationPermissionState.denied;
  }

  Future<Position> getCurrentPosition() async {
    print('[Rakshati][Location] Fetching current position');

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[Rakshati][Location] Current position aborted: location service disabled');
      throw StateError('Location services are disabled.');
    }

    final permission = await Permission.locationWhenInUse.status;
    if (!permission.isGranted) {
      print('[Rakshati][Location] Current position aborted: permission not granted status=$permission');
      throw StateError('Location permission is not granted.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      print('[Rakshati][Location] Current position resolved lat=${position.latitude} lng=${position.longitude}');
      return position;
    } on TimeoutException catch (error) {
      print('[Rakshati][Location] Current position timed out: $error');
    } catch (error) {
      print('[Rakshati][Location] Current position failed, trying last known location: $error');
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      print(
        '[Rakshati][Location] Falling back to last known position '
        'lat=${lastKnown.latitude} lng=${lastKnown.longitude}',
      );
      return lastKnown;
    }

    throw StateError('Unable to determine your location right now.');
  }

  Future<void> openSettings() async {
    print('[Rakshati][Location] Opening app settings');
    await openAppSettings();
  }
}
