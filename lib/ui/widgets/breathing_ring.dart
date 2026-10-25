import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'calm_motion.dart';

/// The thin goal ring with the champagne progress arc. While [CalmMotion] is
/// on, the arc and its tip glow softly and breathe once every 5.5 seconds
/// (#307); the ticker stops by itself when Focus isn't drawn.
class BreathingRing extends StatefulWidget {
  const BreathingRing({super.key, required this.progress});

  /// Key of the painted ring, for tests.
  static const paintKey = ValueKey('breathing-ring');

  /// One breath: in and out.
  static const breathDuration = Duration(milliseconds: 5500);

  /// Share of the goal reached, 0–1.
  final double progress;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: BreathingRing.breathDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CalmMotion.of(context)) {
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) => CustomPaint(
        key: BreathingRing.paintKey,
        painter: GoalRingPainter(
          progress: widget.progress,
          // 0 → 1 → 0 over one breath, eased like a breath.
          breath: (1 - math.cos(_breath.value * 2 * math.pi)) / 2,
          arc: colors.primary,
          track: colors.outline,
        ),
      ),
    );
  }
}

/// Paints the track, the progress arc and – growing with [breath] – a soft
/// glow on the arc and its tip.
class GoalRingPainter extends CustomPainter {
  GoalRingPainter({
    required this.progress,
    required this.breath,
    required this.arc,
    required this.track,
  });

  final double progress;

  /// Glow strength, 0 (still) to 1 (full breath).
  final double breath;
  final Color arc;
  final Color track;

  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke * 4;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = track,
    );
    final sweep = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep == 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    if (breath > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = _stroke + 3 * breath
          ..color = arc.withValues(alpha: 0.2 + 0.35 * breath)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 6 * breath),
      );
    }
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _stroke
        ..color = arc,
    );
    if (breath > 0) {
      final tip = center +
          Offset(math.cos(start + sweep), math.sin(start + sweep)) * radius;
      canvas.drawCircle(
        tip,
        2.5 + 2 * breath,
        Paint()
          ..color = arc.withValues(alpha: 0.5 + 0.5 * breath)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * breath),
      );
    }
  }

  @override
  bool shouldRepaint(GoalRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      breath != oldDelegate.breath ||
      arc != oldDelegate.arc ||
      track != oldDelegate.track;
}
