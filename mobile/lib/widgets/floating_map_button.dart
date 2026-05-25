import 'package:flutter/material.dart';
import 'glass_panel.dart';

class FloatingMapButton extends StatelessWidget {
  const FloatingMapButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassPanel(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 12 : 14,
            vertical: 12,
          ),
          borderRadius: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (label != null) ...[
                const SizedBox(width: 10),
                Text(
                  label!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
