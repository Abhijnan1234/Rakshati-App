// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import '../widgets/auth_scaffold.dart';
import 'home_map_screen.dart';

class PermissionFlowScreen extends StatefulWidget {
  const PermissionFlowScreen({super.key});

  @override
  State<PermissionFlowScreen> createState() => _PermissionFlowScreenState();
}

class _PermissionFlowScreenState extends State<PermissionFlowScreen> {
  bool _isBusy = true;
  bool _showSettingsButton = false;
  String _message = 'Checking your location permission...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePermissionFlow());
  }

  Future<void> _handlePermissionFlow() async {
    print('[Rakshati][Navigation] Permission flow started');
    setState(() {
      _isBusy = true;
      _showSettingsButton = false;
    });

    final locationService = context.read<LocationProvider>().service;
    final permissionState = await locationService.getPermissionState();
    print('[Rakshati][Navigation] Permission state=$permissionState');

    if (!mounted) {
      return;
    }

    if (permissionState == LocationPermissionState.granted) {
      print('[Rakshati][Navigation] Permission already granted -> HomeMapScreen');
      _openHome();
      return;
    }

    if (permissionState == LocationPermissionState.permanentlyDenied) {
      setState(() {
        _isBusy = false;
        _showSettingsButton = true;
        _message = 'Location permission is permanently denied. Open app settings to continue.';
      });
      return;
    }

    final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Location access required'),
            content: const Text(
              'Rakshati requires location access for safety tracking and nearby assistance.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRequest || !mounted) {
      setState(() {
        _isBusy = false;
        _message = 'Location permission is required to continue.';
      });
      return;
    }

    final requestedState = await locationService.requestPermission();
    print('[Rakshati][Navigation] Requested permission result=$requestedState');

    if (!mounted) {
      return;
    }

    if (requestedState == LocationPermissionState.granted) {
      print('[Rakshati][Navigation] Permission granted after request -> HomeMapScreen');
      _openHome();
      return;
    }

    if (requestedState == LocationPermissionState.permanentlyDenied) {
      setState(() {
        _isBusy = false;
        _showSettingsButton = true;
        _message = 'Location permission is permanently denied. Open app settings to continue.';
      });
      return;
    }

    setState(() {
      _isBusy = false;
      _message = 'Location permission is still denied. Please try again.';
    });
  }

  void _openHome() {
    print('[Rakshati][Navigation] Opening HomeMapScreen from PermissionFlowScreen');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeMapScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Location Permission',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 24),
              if (_isBusy)
                const Center(child: CircularProgressIndicator())
              else
                AppButton(
                  label: _showSettingsButton ? 'Open Settings' : 'Try Again',
                  onPressed: () async {
                    if (_showSettingsButton) {
                      await context.read<LocationProvider>().service.openSettings();
                      if (!context.mounted) {
                        return;
                      }
                      showAppSnackbar(
                        context,
                        'Return here after enabling location permission.',
                      );
                    } else {
                      _handlePermissionFlow();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
