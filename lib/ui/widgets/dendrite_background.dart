import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/background_style.dart';
import 'calm_motion.dart';

/// How a [BackgroundStyle] grows: where its roots lie (in a 320 × 560 frame,
/// scaled to the screen; outside it), how long and deep its branches get and
/// how strong its lines are (#314).
class DendriteSpec {
  const DendriteSpec._({
    required this.roots,
    required this.length,
    required this.depth,
    required this.pulses,
    this.thin = false,
  });

  /// Root position and growth angle in the 320 × 560 design frame.
  final List<(double x, double y, double angle)> roots;
  final double length;
  final int depth;
  final int pulses;
  final bool thin;

  static const _frame = Size(320, 560);

  /// Line width at [depth]: stems strongest, tips finest.
  double width(int depth) => math.max(0.4, (thin ? 1.0 : 1.7) - depth * 0.3);

  /// Line opacity at [depth]: stems clearest, tips faintest.
  double opacity(int depth) =>
      math.max(0.03, (thin ? 0.09 : 0.12) - depth * 0.016);

  static DendriteSpec of(BackgroundStyle style) => switch (style) {
    BackgroundStyle.fiveStems => const DendriteSpec._(
      roots: [
        (-30, 90, 0.4),
        (350, 200, math.pi - 0.3),
        (-30, 420, -0.3),
        (350, 520, math.pi + 0.35),
        (160, 600, -1.5),
      ],
      length: 210,
      depth: 4,
      pulses: 4,
    ),
    BackgroundStyle.dense => const DendriteSpec._(
      roots: [(-30, 120, 0.35), (350, 470, math.pi + 0.25), (120, 600, -1.35)],
      length: 240,
      depth: 6,
      pulses: 4,
    ),
    BackgroundStyle.roots => const DendriteSpec._(
      roots: [
        (40, 600, -1.35),
        (160, 610, -1.57),
        (280, 600, -1.8),
        (-30, 500, -0.8),
        (350, 520, math.pi + 0.8),
      ],
      length: 250,
      depth: 5,
      pulses: 4,
    ),
    BackgroundStyle.twoTrees => const DendriteSpec._(
      roots: [(-40, -30, 0.95), (360, 590, math.pi + 0.95)],
      length: 300,
      depth: 6,
      pulses: 3,
    ),
    BackgroundStyle.mesh => const DendriteSpec._(
      roots: [
        (-30, 60, 0.25),
        (350, 150, math.pi - 0.2),
        (-30, 260, 0.1),
        (350, 340, math.pi + 0.15),
        (-30, 460, -0.15),
        (350, 540, math.pi + 0.3),
        (100, 600, -1.2),
        (230, -40, 1.8),
      ],
      length: 200,
      depth: 4,
      pulses: 5,
      thin: true,
    ),
    BackgroundStyle.none => const DendriteSpec._(
      roots: [],
      length: 0,
      depth: 0,
      pulses: 0,
    ),
  };
}

/// One branch: a gently bending line of points, its depth (0 = stem) and the
/// indices of the branches growing from its end.
class DendriteBranch {
  DendriteBranch(this.points, this.depth);

  final List<Offset> points;
  final int depth;
  final List<int> children = [];
}

/// Still branching trees for a style and screen size; seeded, so the same
/// inputs always give the same picture.
class DendriteLayout {
  DendriteLayout._(this.spec, this.branches, this.roots);

  factory DendriteLayout.generate(
    Size size,
    BackgroundStyle style, {
    int seed = 13,
  }) {
    final spec = DendriteSpec.of(style);
    final random = math.Random(seed + style.index * 7);
    final scaleX = size.width / DendriteSpec._frame.width;
    final scaleY = size.height / DendriteSpec._frame.height;
    final scale = math.min(scaleX, scaleY);
    final branches = <DendriteBranch>[];

    int grow(Offset start, double angle, double length, int depth) {
      final points = [start];
      var direction = angle;
      var point = start;
      for (var step = 0; step < 6; step++) {
        direction += (random.nextDouble() - 0.5) * 0.35;
        point += Offset(math.cos(direction), math.sin(direction)) *
            (length / 6);
        points.add(point);
      }
      final branch = DendriteBranch(points, depth);
      final index = branches.length;
      branches.add(branch);
      if (depth < spec.depth) {
        final forks =
            depth < 2 || random.nextDouble() < (spec.depth > 5 ? 0.75 : 0.6)
            ? 2
            : 1;
        for (var fork = 0; fork < forks; fork++) {
          final turn = (fork == 0 ? -1 : 1) * (0.3 + random.nextDouble() * 0.5);
          branch.children.add(
            grow(
              point,
              direction + turn,
              length * (0.6 + random.nextDouble() * 0.15),
              depth + 1,
            ),
          );
        }
      }
      return index;
    }

    final roots = [
      for (final (x, y, angle) in spec.roots)
        grow(Offset(x * scaleX, y * scaleY), angle, spec.length * scale, 0),
    ];
    return DendriteLayout._(spec, branches, roots);
  }

  final DendriteSpec spec;
  final List<DendriteBranch> branches;

  /// Indices of the stems; they start outside the screen.
  final List<int> roots;

  /// The way of [pulse] in its [round]: from a root (outside the screen)
  /// along one branch after another to a tip. Pure, so a pulse's way only
  /// depends on time.
  ({int root, List<Offset> path}) pulsePath({
    required int round,
    required int pulse,
  }) {
    final root = roots[(round + pulse) % roots.length];
    var branch = branches[root];
    final path = [...branch.points];
    var step = 0;
    while (branch.children.isNotEmpty) {
      final pick = (round * 31 + pulse * 17 + step * 7) % branch.children.length;
      branch = branches[branch.children[pick]];
      path.addAll(branch.points.skip(1));
      step++;
    }
    return (root: root, path: path);
  }
}

/// The living background: still branches and – while [CalmMotion] is on –
/// a few faint pulses that enter from outside and glide to a tip in about
/// 16 seconds. Repaints at most ~15 times a second, only while drawn.
class DendriteBackground extends StatefulWidget {
  const DendriteBackground({super.key, required this.style});

  /// Key of the painted background, for tests.
  static const paintKey = ValueKey('dendrite-background');

  final BackgroundStyle style;

  @override
  State<DendriteBackground> createState() => _DendriteBackgroundState();
}

class _DendriteBackgroundState extends State<DendriteBackground>
    with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 66);

  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(0);
  Duration _shown = Duration.zero;
  DendriteLayout? _layout;
  (Size, BackgroundStyle)? _layoutKey;

  void _onTick(Duration elapsed) {
    if (elapsed - _shown < _frame) return;
    _shown = elapsed;
    _time.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CalmMotion.of(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  DendriteLayout _layoutFor(Size size) {
    final key = (size, widget.style);
    final cached = _layout;
    if (cached != null && _layoutKey == key) return cached;
    _layoutKey = key;
    return _layout = DendriteLayout.generate(size, widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, time, _) => CustomPaint(
            key: DendriteBackground.paintKey,
            size: constraints.biggest,
            painter: DendritePainter(
              layout: _layoutFor(constraints.biggest),
              time: time,
              color: theme.colorScheme.primary,
              strength: theme.brightness == Brightness.dark ? 1 : 0.7,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the branches and the pulses at [time] seconds.
class DendritePainter extends CustomPainter {
  DendritePainter({
    required this.layout,
    required this.time,
    required this.color,
    this.strength = 1,
  });

  static const pulseSeconds = 16.0;

  final DendriteLayout layout;
  final double time;
  final Color color;

  /// Overall opacity factor; lighter on the ivory light mode.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = layout.spec;
    final tip = Paint()..color = color.withValues(alpha: 0.15 * strength);
    for (final branch in layout.branches) {
      final path = Path()..addPolygon(branch.points, false);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = spec.width(branch.depth)
          ..color = color.withValues(
            alpha: spec.opacity(branch.depth) * strength,
          ),
      );
      if (branch.children.isEmpty) {
        canvas.drawCircle(branch.points.last, 1.2, tip);
      }
    }
    if (time == 0 || layout.roots.isEmpty) return;
    for (var pulse = 0; pulse < spec.pulses; pulse++) {
      final shifted = time / pulseSeconds + pulse / spec.pulses;
      final round = shifted.floor();
      final progress = shifted - round;
      final path = layout.pulsePath(round: round, pulse: pulse).path;
      final position = _along(path, progress);
      final fade =
          math.min(1.0, progress * 6) * math.min(1.0, (1 - progress) * 5);
      canvas.drawCircle(
        position,
        2.2,
        Paint()
          ..color = color.withValues(alpha: 0.6 * fade * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  /// The point at [fraction] of the way along [path].
  static Offset _along(List<Offset> path, double fraction) {
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += (path[i] - path[i - 1]).distance;
    }
    var left = fraction * total;
    for (var i = 1; i < path.length; i++) {
      final piece = (path[i] - path[i - 1]).distance;
      if (left <= piece && piece > 0) {
        return Offset.lerp(path[i - 1], path[i], left / piece) ?? path[i];
      }
      left -= piece;
    }
    return path.last;
  }

  @override
  bool shouldRepaint(DendritePainter oldDelegate) =>
      time != oldDelegate.time ||
      layout != oldDelegate.layout ||
      color != oldDelegate.color ||
      strength != oldDelegate.strength;
}
