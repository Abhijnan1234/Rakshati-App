import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/open_street_map_provider.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({
    super.key,
    required this.connectionName,
  });

  final String connectionName;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final mapProvider = const OpenStreetMapProvider();
    final points = provider.historyPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Tracking $connectionName')),
      body: points.isEmpty
          ? const Center(
              child: Text('Live tracking will appear here once route history is available.'),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: points.last,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: mapProvider.tileUrlTemplate,
                  userAgentPackageName: mapProvider.userAgentPackageName,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 5,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.last,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
