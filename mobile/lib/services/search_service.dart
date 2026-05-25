// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location_search_result.dart';
import '../models/saved_location.dart';

class SearchService {
  const SearchService();

  List<LocationSearchResult> searchSaved(
    String query,
    List<SavedLocation> savedLocations,
  ) {
    final normalized = query.trim().toLowerCase();
    final candidates = normalized.isEmpty
        ? savedLocations.take(5)
        : savedLocations.where(
            (location) =>
                location.name.toLowerCase().contains(normalized) ||
                location.category.toLowerCase().contains(normalized),
          );

    return candidates
        .map(
          (location) => LocationSearchResult(
            id: location.id,
            title: location.name,
            subtitle: location.category,
            latitude: location.latitude,
            longitude: location.longitude,
            source: LocationSearchSource.saved,
            category: location.category,
          ),
        )
        .toList();
  }

  List<LocationSearchResult> searchRecent(
    String query,
    List<LocationSearchResult> recentLocations,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return recentLocations.take(5).toList();
    }

    return recentLocations
        .where(
          (location) =>
              location.title.toLowerCase().contains(normalized) ||
              location.subtitle.toLowerCase().contains(normalized),
        )
        .take(5)
        .toList();
  }

  Future<List<LocationSearchResult>> searchOnline(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return <LocationSearchResult>[];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'format': 'jsonv2',
        'q': normalized,
        'limit': '6',
        'addressdetails': '1',
      },
    );

    print('[Rakshati][SearchService] Searching Nominatim query=$normalized');
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Rakshati/1.0 (safety dashboard)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print(
        '[Rakshati][SearchService] Online search failed '
        'status=${response.statusCode}',
      );
      return <LocationSearchResult>[];
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) {
      final json = item as Map<String, dynamic>;
      return LocationSearchResult(
        id: json['place_id'].toString(),
        title: json['display_name'] as String? ?? 'Unknown location',
        subtitle: [
          json['type'],
          json['class'],
        ].whereType<String>().join(' • '),
        latitude: double.tryParse(json['lat'].toString()) ?? 0,
        longitude: double.tryParse(json['lon'].toString()) ?? 0,
        source: LocationSearchSource.online,
      );
    }).toList();
  }
}
