import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_history_settings.dart';
import '../providers/dashboard_provider.dart';

class LocationHistorySettingsScreen extends StatelessWidget {
  const LocationHistorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final settings = provider.historySettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Location History Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'History Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LocationHistoryDurationOption>(
            initialValue: settings.duration,
            items: LocationHistoryDurationOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      LocationHistorySettings(duration: option).durationLabel,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              provider.updateHistorySettings(settings.copyWith(duration: value));
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Tracking Interval',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TrackingIntervalOption>(
            initialValue: settings.interval,
            items: TrackingIntervalOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      LocationHistorySettings(interval: option).intervalLabel,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              provider.updateHistorySettings(settings.copyWith(interval: value));
            },
          ),
        ],
      ),
    );
  }
}
