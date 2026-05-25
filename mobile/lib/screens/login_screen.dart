// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/google_auth_payload.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/brand_header.dart';
import '../widgets/loading_overlay.dart';
import 'permission_flow_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('[Rakshati][UI] Login button tapped for ${_emailController.text.trim()}');
    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      print('[Rakshati][Navigation] Login successful -> PermissionFlowScreen');
      _openPermissionFlow();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Login ApiException: $error');
      showAppSnackbar(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Login unexpected error: $error');
      showAppSnackbar(context, "Can't sign in at this moment");
    }
  }

  Future<void> _handleGuestLogin() async {
    print('[Rakshati][UI] Guest login button tapped');
    try {
      await context.read<AuthProvider>().loginAsGuest();
      if (!mounted) {
        return;
      }
      print('[Rakshati][Navigation] Guest login successful -> PermissionFlowScreen');
      _openPermissionFlow();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Guest login ApiException: $error');
      showAppSnackbar(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Guest login unexpected error: $error');
      showAppSnackbar(context, 'Guest login failed.');
    }
  }

  Future<void> _handleGoogleLogin() async {
    print('[Rakshati][UI] Google Sign-In tapped');
    try {
      final GoogleAuthPayload? payload =
          await context.read<AuthProvider>().beginGoogleSignIn();

      if (payload == null) {
        if (!mounted) {
          return;
        }
        showAppSnackbar(context, 'Google Sign-In cancelled');
        return;
      }

      await _completeGoogleBackendLogin(payload);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Google sign-in ApiException: $error');
      showAppSnackbar(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Google sign-in unexpected error: $error');
      showAppSnackbar(context, 'Google Sign-In failed');
    }
  }

  Future<void> _completeGoogleBackendLogin(GoogleAuthPayload payload) async {
    try {
      await context.read<AuthProvider>().loginWithGoogle(payload: payload);
      if (!mounted) {
        return;
      }
      print('[Rakshati][Navigation] Google login successful -> PermissionFlowScreen');
      _openPermissionFlow();
    } on ApiException catch (error) {
      if (error.code == 'USERNAME_REQUIRED') {
        final username = await _promptForUsername();
        if (username == null || !mounted) {
          return;
        }

        await context.read<AuthProvider>().loginWithGoogle(
              payload: payload,
              username: username,
            );
        if (!mounted) {
          return;
        }
        print('[Rakshati][Navigation] First-time Google login successful -> PermissionFlowScreen');
        _openPermissionFlow();
        return;
      }

      rethrow;
    }
  }

  Future<String?> _promptForUsername() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dialogFormKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('Choose a username'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              validator: validateUsername,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  void _openPermissionFlow() {
    print('[Rakshati][Navigation] Opening PermissionFlowScreen from LoginScreen');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const PermissionFlowScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthScaffold(
      child: LoadingOverlay(
        isLoading: authProvider.isLoading,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(),
                  const SizedBox(height: 28),
                  Text(
                    'Log in to keep your safety tools ready whenever you need them.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: validatePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Login',
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Continue with Google',
                    onPressed: _handleGoogleLogin,
                    variant: AppButtonVariant.secondary,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Continue as Guest',
                    onPressed: _handleGuestLogin,
                    variant: AppButtonVariant.secondary,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Sign Up',
                    onPressed: () {
                      print('[Rakshati][Navigation] Opening SignUpScreen');
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignUpScreen(),
                        ),
                      );
                    },
                    variant: AppButtonVariant.ghost,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
