import 'package:flutter/material.dart';

/// The calm backdrop of the main screens: the surface color, a soft radial
/// glow of the accent color and a gentle vignette at the bottom. Uses theme
/// colors only, so light mode gets a warm ivory glow.
class FocusBackground extends StatelessWidget {
  const FocusBackground({
    super.key,
    required this.child,
    this.glowCenter = const Alignment(0.7, -0.75),
    this.glowRadius = 0.9,
  });

  /// Key of the glow layer, for tests.
  static const glowKey = ValueKey('focus-background-glow');

  final Widget child;

  /// Where the light comes from, e.g. top right on home, behind the ring in a
  /// session.
  final Alignment glowCenter;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: colors.surface,
      child: DecoratedBox(
        key: glowKey,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: glowCenter,
            radius: glowRadius,
            colors: [
              colors.primary.withValues(alpha: dark ? 0.16 : 0.12),
              colors.primary.withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.4),
              radius: 1.1,
              colors: [
                colors.shadow.withValues(alpha: dark ? 0.35 : 0.06),
                colors.shadow.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
