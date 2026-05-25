import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.showSubtitle = true,
  });

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Rakshati',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 8),
          Text(
            'Safety First',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
}
