import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'calm_motion.dart';

/// Still nodes spread over the screen like a brain network – focus builds
/// connections – with thin lines between neighbours (#308).
class NeuralLayout {
  const NeuralLayout._(this.nodes, this.edges);

  /// A network for [size]: about 40 nodes on a jittered grid, each connected
  /// to its nearest neighbours. Seeded, so the same size gives the same
  /// network every time.
  factory NeuralLayout.generate(Size size, {int seed = 7}) {
    final random = math.Random(seed);
    const columns = 5;
    final rows = math.max(4, (columns * size.height / size.width).round());
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    final nodes = [
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          Offset(
            (column + 0.15 + random.nextDouble() * 0.7) * cellWidth,
            (row + 0.15 + random.nextDouble() * 0.7) * cellHeight,
          ),
    ];
    final edges = <(int, int)>{};
    for (var index = 0; index < nodes.length; index++) {
      final nearest = [
        for (var other = 0; other < nodes.length; other++)
          if (other != index) other,
      ]..sort(
          (a, b) => (nodes[a] - nodes[index]).distanceSquared.compareTo(
            (nodes[b] - nodes[index]).distanceSquared,
          ),
        );
      for (final other in nearest.take(2 + random.nextInt(2))) {
        edges.add(index < other ? (index, other) : (other, index));
      }
    }
    return NeuralLayout._(nodes, edges.toList());
  }

  final List<Offset> nodes;

  /// Connected node indices, the smaller one first.
  final List<(int, int)> edges;
}

/// The network behind the main screens. While [CalmMotion] is on, two or
/// three faint pulses travel slowly along the lines; the nodes never move.
/// Repaints at most about 15 times a second and only while Focus is drawn.
class NeuralBackground extends StatefulWidget {
  const NeuralBackground({super.key});

  /// Key of the painted network, for tests.
  static const paintKey = ValueKey('neural-background');

  @override
  State<NeuralBackground> createState() => _NeuralBackgroundState();
}

class _NeuralBackgroundState extends State<NeuralBackground>
    with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 66);

  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(0);
  Duration _shown = Duration.zero;
  NeuralLayout? _layout;
  Size? _layoutSize;

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

  NeuralLayout _layoutFor(Size size) {
    if (_layoutSize != size) {
      _layout = NeuralLayout.generate(size);
      _layoutSize = size;
    }
    return _layout ?? NeuralLayout.generate(size);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder<double>(
          valueListenable: _time,
          builder: (context, time, _) => CustomPaint(
            key: NeuralBackground.paintKey,
            size: constraints.biggest,
            painter: NeuralPainter(
              layout: _layoutFor(constraints.biggest),
              time: time,
              color: color,
              strength: dark ? 1 : 0.7,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the still network and the pulses at [time] seconds. Each pulse
/// takes [pulseSeconds] to cross a line, then moves on to another line.
class NeuralPainter extends CustomPainter {
  NeuralPainter({
    required this.layout,
    required this.time,
    required this.color,
    this.strength = 1,
  });

  static const pulses = 3;
  static const pulseSeconds = 14.0;

  final NeuralLayout layout;
  final double time;
  final Color color;

  /// Overall opacity factor; lighter on the ivory light mode.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = layout.nodes;
    final line = Paint()
      ..strokeWidth = 0.6
      ..color = color.withValues(alpha: 0.07 * strength);
    for (final (a, b) in layout.edges) {
      canvas.drawLine(nodes[a], nodes[b], line);
    }
    final dot = Paint()..color = color.withValues(alpha: 0.18 * strength);
    for (final node in nodes) {
      canvas.drawCircle(node, 1.5, dot);
    }
    if (time == 0 || layout.edges.isEmpty) return;
    for (var pulse = 0; pulse < pulses; pulse++) {
      final shifted = time / pulseSeconds + pulse / pulses;
      final round = shifted.floor();
      final progress = shifted - round;
      final (a, b) = layout.edges[(round * 7 + pulse * 13) % layout.edges.length];
      final position = Offset.lerp(nodes[a], nodes[b], progress) ?? nodes[a];
      final fade = math.sin(progress * math.pi);
      canvas.drawCircle(
        position,
        1.8,
        Paint()
          ..color = color.withValues(alpha: 0.45 * fade * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(NeuralPainter oldDelegate) =>
      time != oldDelegate.time ||
      layout != oldDelegate.layout ||
      color != oldDelegate.color ||
      strength != oldDelegate.strength;
}
