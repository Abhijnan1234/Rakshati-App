// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/loading_overlay.dart';
import 'permission_flow_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('[Rakshati][UI] Signup button tapped for ${_usernameController.text.trim()}');
    try {
      await context.read<AuthProvider>().signup(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      print('[Rakshati][Navigation] Signup successful -> PermissionFlowScreen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const PermissionFlowScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Signup ApiException: $error');
      showAppSnackbar(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      print('[Rakshati][UI] Signup unexpected error: $error');
      showAppSnackbar(context, "Can't sign in at this moment");
    }
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
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create your Rakshati profile to enable safety tracking and nearby assistance.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _usernameController,
                    label: 'Username',
                    validator: validateUsername,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
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
                    label: 'Create Account',
                    onPressed: _handleSignUp,
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
