enum LocationHistoryDurationOption {
  hours24,
  days3,
  days7,
  days30,
}

enum TrackingIntervalOption {
  seconds30,
  seconds60,
  seconds120,
}

class LocationHistorySettings {
  const LocationHistorySettings({
    this.duration = LocationHistoryDurationOption.hours24,
    this.interval = TrackingIntervalOption.seconds60,
  });

  final LocationHistoryDurationOption duration;
  final TrackingIntervalOption interval;

  Duration get retentionDuration {
    switch (duration) {
      case LocationHistoryDurationOption.hours24:
        return const Duration(hours: 24);
      case LocationHistoryDurationOption.days3:
        return const Duration(days: 3);
      case LocationHistoryDurationOption.days7:
        return const Duration(days: 7);
      case LocationHistoryDurationOption.days30:
        return const Duration(days: 30);
    }
  }

  Duration get trackingDuration {
    switch (interval) {
      case TrackingIntervalOption.seconds30:
        return const Duration(seconds: 30);
      case TrackingIntervalOption.seconds60:
        return const Duration(seconds: 60);
      case TrackingIntervalOption.seconds120:
        return const Duration(seconds: 120);
    }
  }

  String get durationLabel {
    switch (duration) {
      case LocationHistoryDurationOption.hours24:
        return '24 Hours';
      case LocationHistoryDurationOption.days3:
        return '3 Days';
      case LocationHistoryDurationOption.days7:
        return '7 Days';
      case LocationHistoryDurationOption.days30:
        return '30 Days';
    }
  }

  String get intervalLabel {
    switch (interval) {
      case TrackingIntervalOption.seconds30:
        return '30 Seconds';
      case TrackingIntervalOption.seconds60:
        return '60 Seconds';
      case TrackingIntervalOption.seconds120:
        return '120 Seconds';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration.name,
      'interval': interval.name,
    };
  }

  factory LocationHistorySettings.fromJson(Map<String, dynamic> json) {
    return LocationHistorySettings(
      duration: LocationHistoryDurationOption.values.firstWhere(
        (value) => value.name == json['duration'],
        orElse: () => LocationHistoryDurationOption.hours24,
      ),
      interval: TrackingIntervalOption.values.firstWhere(
        (value) => value.name == json['interval'],
        orElse: () => TrackingIntervalOption.seconds60,
      ),
    );
  }

  LocationHistorySettings copyWith({
    LocationHistoryDurationOption? duration,
    TrackingIntervalOption? interval,
  }) {
    return LocationHistorySettings(
      duration: duration ?? this.duration,
      interval: interval ?? this.interval,
    );
  }
}
