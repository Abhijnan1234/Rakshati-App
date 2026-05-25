// ignore_for_file: avoid_print

import '../models/saved_location.dart';
import 'api_client.dart';

class SavedLocationService {
  SavedLocationService() : _client = const ApiClient();

  final ApiClient _client;

  Future<List<SavedLocation>> getLocations(String token) async {
    print('[Rakshati][LocationsService] Fetching saved locations');
    final response = await _client.get('/locations', token: token);
    final raw = response['locations'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .map((item) => SavedLocation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SavedLocation> saveLocation({
    required String token,
    required String name,
    required String category,
    required double latitude,
    required double longitude,
  }) async {
    print('[Rakshati][LocationsService] Saving location name=$name category=$category');
    final response = await _client.post(
      '/locations/save',
      token: token,
      body: {
        'name': name,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return SavedLocation.fromJson(response['location'] as Map<String, dynamic>);
  }

  Future<void> deleteLocation({
    required String token,
    required String locationId,
  }) async {
    print('[Rakshati][LocationsService] Deleting location=$locationId');
    await _client.delete('/locations/$locationId', token: token);
  }
}
