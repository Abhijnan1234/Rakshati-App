// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/location_search_result.dart';

class SharedLocationService {
  const SharedLocationService();

  static const MethodChannel _methodChannel =
      MethodChannel('rakshati/share');
  static const EventChannel _eventChannel =
      EventChannel('rakshati/share_stream');

  static final RegExp _urlPattern =
      RegExp(r'https?://\S+', caseSensitive: false);
  static final RegExp _coordinatePattern = RegExp(
    r'(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)',
  );
  static final RegExp _atCoordinatePattern = RegExp(
    r'@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)',
  );

  Stream<LocationSearchResult> watchLocationImports() {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is String)
        .cast<String>()
        .asyncMap(parseSharedText)
        .where((result) => result != null)
        .cast<LocationSearchResult>();
  }

  Future<LocationSearchResult?> getInitialImport() async {
    final sharedText =
        await _methodChannel.invokeMethod<String>('getInitialSharedText');
    if (sharedText == null || sharedText.trim().isEmpty) {
      return null;
    }

    final result = await parseSharedText(sharedText);
    await _methodChannel.invokeMethod<void>('clearInitialSharedText');
    return result;
  }

  Future<LocationSearchResult?> parseSharedText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return null;
    }

    final directCoordinates = _parseCoordinates(
      text,
      fallbackTitle: _extractLeadingLabel(text),
      subtitle: 'Imported from Google Maps',
    );
    if (directCoordinates != null) {
      return directCoordinates;
    }

    final urlMatch = _urlPattern.firstMatch(text);
    if (urlMatch == null) {
      return null;
    }

    final urlText = urlMatch.group(0)!;
    final fallbackTitle =
        _extractLeadingLabel(text.replaceFirst(urlText, '').trim());
    final rawUri = Uri.tryParse(urlText);
    if (rawUri == null) {
      return null;
    }

    final resolvedUri = await _resolveUri(rawUri);
    return _parseUri(
      resolvedUri,
      fallbackTitle: fallbackTitle,
    );
  }

  Future<Uri> _resolveUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    if (!(host.contains('maps.app.goo.gl') ||
        host.contains('goo.gl') ||
        host.contains('google.com') ||
        host.contains('maps.google'))) {
      return uri;
    }

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'Rakshati/1.0 (shared location import)',
            },
          )
          .timeout(const Duration(seconds: 5));
      return response.request?.url ?? uri;
    } catch (error) {
      print('[Rakshati][Share] Failed to resolve shared URL $uri: $error');
      return uri;
    }
  }

  LocationSearchResult? _parseUri(
    Uri uri, {
    String? fallbackTitle,
  }) {
    final geoResult = _parseGeoUri(uri, fallbackTitle: fallbackTitle);
    if (geoResult != null) {
      return geoResult;
    }

    final uriText = uri.toString();
    final atMatch = _atCoordinatePattern.firstMatch(uriText);
    if (atMatch != null) {
      return _buildResult(
        latitude: double.parse(atMatch.group(1)!),
        longitude: double.parse(atMatch.group(2)!),
        title: fallbackTitle ?? _titleFromUri(uri) ?? 'Imported location',
      );
    }

    final queryCandidates = <String>[
      uri.queryParameters['q'] ?? '',
      uri.queryParameters['query'] ?? '',
      uri.queryParameters['ll'] ?? '',
      uri.queryParameters['sll'] ?? '',
      uri.queryParameters['destination'] ?? '',
    ].where((value) => value.trim().isNotEmpty);

    for (final candidate in queryCandidates) {
      final parsed = _parseCoordinates(
        candidate,
        fallbackTitle:
            _cleanupTitle(candidate) ?? fallbackTitle ?? _titleFromUri(uri),
        subtitle: 'Imported from Google Maps',
      );
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseCoordinates(
      uriText,
      fallbackTitle: fallbackTitle ?? _titleFromUri(uri),
      subtitle: 'Imported from Google Maps',
    );
  }

  LocationSearchResult? _parseGeoUri(
    Uri uri, {
    String? fallbackTitle,
  }) {
    if (uri.scheme.toLowerCase() != 'geo') {
      return null;
    }

    final pathCoordinates = _parseCoordinates(
      uri.path,
      fallbackTitle: fallbackTitle,
      subtitle: 'Imported from Google Maps',
    );
    if (pathCoordinates != null) {
      return pathCoordinates;
    }

    final query = uri.queryParameters['q'];
    if (query == null || query.trim().isEmpty) {
      return null;
    }

    return _parseCoordinates(
      query,
      fallbackTitle: _cleanupTitle(query) ?? fallbackTitle,
      subtitle: 'Imported from Google Maps',
    );
  }

  LocationSearchResult? _parseCoordinates(
    String text, {
    String? fallbackTitle,
    required String subtitle,
  }) {
    final match = _coordinatePattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);
    if (!_isValidCoordinate(latitude, longitude)) {
      return null;
    }

    return _buildResult(
      latitude: latitude!,
      longitude: longitude!,
      title: fallbackTitle ?? 'Imported location',
      subtitle: subtitle,
    );
  }

  LocationSearchResult _buildResult({
    required double latitude,
    required double longitude,
    required String title,
    String subtitle = 'Imported from Google Maps',
  }) {
    return LocationSearchResult(
      id: 'shared-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Imported location' : title.trim(),
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
      source: LocationSearchSource.temporary,
    );
  }

  String? _extractLeadingLabel(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final firstLine = trimmed.split('\n').first.trim();
    if (firstLine.isEmpty || _coordinatePattern.hasMatch(firstLine)) {
      return null;
    }

    return firstLine;
  }

  String? _titleFromUri(Uri uri) {
    final query = uri.queryParameters['q'] ?? uri.queryParameters['query'];
    final cleanedQuery = _cleanupTitle(query ?? '');
    if (cleanedQuery != null) {
      return cleanedQuery;
    }

    final segments = uri.pathSegments
        .map(Uri.decodeComponent)
        .where((segment) => segment.isNotEmpty && !segment.startsWith('@'))
        .toList();
    if (segments.isEmpty) {
      return null;
    }

    return segments.last.replaceAll('+', ' ');
  }

  String? _cleanupTitle(String raw) {
    final withoutCoordinates =
        raw.replaceAll(_coordinatePattern, '').replaceAll('+', ' ').trim();
    return withoutCoordinates.isEmpty ? null : withoutCoordinates;
  }

  bool _isValidCoordinate(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
