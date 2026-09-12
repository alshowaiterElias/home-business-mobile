import 'package:flutter/material.dart';

/// A reusable badge indicating that a home business or store is verified
/// and authenticated by the marketplace administration.
class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showLabel;
  final Color? color;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.showLabel = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? const Color(0xFF1E88E5);

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: size,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              'متجر موثق',
              style: TextStyle(
                color: badgeColor,
                fontSize: size * 0.75,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: 'متجر موثق ومعتمد',
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: badgeColor,
      ),
    );
  }
}
