import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A short, calm intro on cold start: the ring, the wordmark and a tagline,
/// then home fades in.
class IntroScreen extends StatefulWidget {
  const IntroScreen({
    super.key,
    required this.onDone,
    this.duration = const Duration(milliseconds: 1200),
  });

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 120,
                child: CircularProgressIndicator(
                  value: 300 / 360,
                  strokeWidth: 2,
                  strokeCap: StrokeCap.round,
                  color: gold,
                  backgroundColor: gold.withValues(alpha: 0.22),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.appTitle.toUpperCase(),
                style: theme.textTheme.displaySmall?.copyWith(
                  letterSpacing: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(width: 36, height: 1, color: gold),
              const SizedBox(height: 20),
              Text(
                l10n.introTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
