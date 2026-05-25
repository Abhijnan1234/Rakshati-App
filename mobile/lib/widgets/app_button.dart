import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
          ),
          child: _ButtonChild(label: label, isLoading: isLoading),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: Colors.white,
          ),
          child: _ButtonChild(label: label, isLoading: isLoading),
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: enabled ? onPressed : null,
          child: _ButtonChild(label: label, isLoading: isLoading),
        );
    }
  }
}

class _ButtonChild extends StatelessWidget {
  const _ButtonChild({
    required this.label,
    required this.isLoading,
  });

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Text(label);
  }
}
