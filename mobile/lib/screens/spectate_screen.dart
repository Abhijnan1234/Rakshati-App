import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/glass_panel.dart';
import 'live_tracking_screen.dart';

class SpectateScreen extends StatelessWidget {
  const SpectateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connected SafeWalkers')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (provider.safeWalkers.isEmpty)
            const GlassPanel(
              child: Text(
                'No SafeWalkers are connected yet. Use Connections to invite and manage them.',
              ),
            )
          else
            ...provider.safeWalkers.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(connection.peer.username),
                    subtitle: Text(
                      'Status: ${connection.status}\n'
                      'Current SafeWalk: ${connection.currentSafeWalkStatus}\n'
                      'Last update: ${connection.lastUpdatedAt.toLocal()}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LiveTrackingScreen(
                            connectionName: connection.peer.username,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
