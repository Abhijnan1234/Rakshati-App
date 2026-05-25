enum LocationSearchSource {
  recent,
  saved,
  online,
  temporary,
}

class LocationSearchResult {
  const LocationSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final LocationSearchSource source;
  final String? category;

  String get sourceLabel {
    switch (source) {
      case LocationSearchSource.recent:
        return 'Recent';
      case LocationSearchSource.saved:
        return 'Saved';
      case LocationSearchSource.online:
        return 'Online';
      case LocationSearchSource.temporary:
        return 'Pinned';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'source': source.name,
      'category': category,
    };
  }

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      source: LocationSearchSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => LocationSearchSource.recent,
      ),
      category: json['category'] as String?,
    );
  }
}
