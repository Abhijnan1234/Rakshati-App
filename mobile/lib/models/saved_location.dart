class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
