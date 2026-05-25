// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/glass_panel.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Guardians'),
              Tab(text: 'SafeWalkers'),
            ],
          ),
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _ConnectionsTab(
                  title: 'Guardians',
                  relationshipType: 'guardian',
                  emptyLabel: 'No guardians connected yet.',
                ),
                _ConnectionsTab(
                  title: 'SafeWalkers',
                  relationshipType: 'safeWalker',
                  emptyLabel: 'No SafeWalkers connected yet.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionsTab extends StatelessWidget {
  const _ConnectionsTab({
    required this.title,
    required this.relationshipType,
    required this.emptyLabel,
  });

  final String title;
  final String relationshipType;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final connections = relationshipType == 'guardian'
        ? provider.guardians
        : provider.safeWalkers;

    return RefreshIndicator(
      onRefresh: provider.refreshConnections,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _createInvite(context, relationshipType),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Generate Invite QR'),
              ),
              OutlinedButton.icon(
                onPressed: () => _createInvite(context, relationshipType),
                icon: const Icon(Icons.link),
                label: const Text('Generate Invite Link'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  showAppSnackbar(
                    context,
                    'QR scanning is ready for the next build. Use invite code entry for now.',
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
              OutlinedButton.icon(
                onPressed: () => _enterInviteCode(context),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Enter Invite Code'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.invites.isNotEmpty) ...[
            Text(
              'Active Invites',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...provider.invites.map(
              (invite) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.relationshipType == 'guardian'
                            ? 'Invite a Guardian'
                            : 'Invite a SafeWalker',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(invite.token),
                      const SizedBox(height: 6),
                      Text(
                        'Expires ${invite.expiresAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (connections.isEmpty)
            GlassPanel(
              child: Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            )
          else
            ...connections.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(connection.peer.username.substring(0, 1).toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.peer.username,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Status: ${connection.status} • SafeWalk: ${connection.currentSafeWalkStatus}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.deleteConnection(connection.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createInvite(BuildContext context, String relationshipType) async {
    try {
      final invite = await context.read<DashboardProvider>().createInvite(relationshipType);
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            relationshipType == 'guardian'
                ? 'Guardian Invite Ready'
                : 'SafeWalker Invite Ready',
          ),
          content: SelectableText(
            'Invite code: ${invite.token}\n\n'
            'Deep link: ${invite.deepLink}\n'
            'Share link: ${invite.shareLink}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackbar(context, 'Unable to create invite right now.');
    }
  }

  Future<void> _enterInviteCode(BuildContext context) async {
    final controller = TextEditingController();

    final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Enter Invite Code'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Accept'),
              ),
            ],
          ),
        ) ??
        false;

    if (!accepted || !context.mounted) {
      controller.dispose();
      return;
    }

    try {
      await context.read<DashboardProvider>().acceptInvite(controller.text.trim());
      if (!context.mounted) {
        return;
      }
      showAppSnackbar(context, 'Connection accepted successfully.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackbar(context, 'Unable to accept that invite code.');
    } finally {
      controller.dispose();
    }
  }
}
