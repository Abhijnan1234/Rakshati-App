// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/brand_header.dart';
import 'home_map_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    print('[Rakshati][Navigation] Splash bootstrap started');
    final authProvider = context.read<AuthProvider>();
    final startedAt = DateTime.now();
    final isAuthenticated = await authProvider.restoreSession();
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = const Duration(seconds: 2) - elapsed;

    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) {
      return;
    }

    print(
      '[Rakshati][Navigation] Splash finished. '
      'isAuthenticated=$isAuthenticated next=${isAuthenticated ? 'HomeMapScreen' : 'LoginScreen'}',
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => isAuthenticated ? const HomeMapScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A0B0D),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandHeader(),
              SizedBox(height: 28),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
