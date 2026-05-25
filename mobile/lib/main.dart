// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/location_provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/connections_service.dart';
import 'services/google_auth_service.dart';
import 'services/location_service.dart';
import 'services/saved_location_service.dart';
import 'services/search_service.dart';
import 'services/secure_storage_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('[Rakshati][Firebase] Initializing Firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[Rakshati][Firebase] Firebase initialized');
  } catch (error, stackTrace) {
    print('[Rakshati][Firebase] Firebase initialization failed: $error');
    print(stackTrace);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: AuthService(),
            googleAuthService: GoogleAuthService(),
            storageService: const SecureStorageService(),
          ),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(
            locationService: const LocationService(),
          ),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(
            savedLocationService: SavedLocationService(),
            connectionsService: ConnectionsService(),
            searchService: const SearchService(),
            storageService: const SecureStorageService(),
          ),
        ),
      ],
      child: const RakshatiApp(),
    ),
  );
}

class RakshatiApp extends StatelessWidget {
  const RakshatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakshati',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
