// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({
    required LocationService locationService,
  }) : _locationService = locationService;

  final LocationService _locationService;

  bool _isLoading = false;
  Position? _currentPosition;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;
  LocationService get service => _locationService;

  Future<void> refreshCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    print('[Rakshati][LocationProvider] Refreshing current location');
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      _errorMessage = null;
      print(
        '[Rakshati][LocationProvider] Location received '
        'lat=${_currentPosition?.latitude} lng=${_currentPosition?.longitude}',
      );
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Bad state: ', '');
      print('[Rakshati][LocationProvider] Failed to fetch location: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
