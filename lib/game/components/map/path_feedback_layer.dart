import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'path_link.dart';

/// Brief visual feedback when a route's flow starts or stops: a fading white
/// glow laid over the path for 0.3s on the first unit setting out, and 0.2s
/// on the last one leaving it.
///
/// **Why this is a separate component instead of a change to [PathLink].**
/// Stage 2's guardrails say overlays are read-only observers and must not
/// modify `Building`, `PathLink`, `Unit`, or `EnemyCommander` — but this
/// deliverable's own implementation notes suggested adding a private timer
/// field directly to `PathLink`. Those two instructions conflict; this
/// resolves it in the guardrail's favour by watching [PathLink.isActive]
/// from the outside and re-deriving the same line geometry
/// [PathLink.render] draws (from the two endpoints' public `position`/`size`)
/// rather than reaching into the class.
class PathFeedbackLayer extends Component {
  final List<PathLink> _paths;

  final Map<PathLink, bool> _wasActive = {};
  final Map<PathLink, _Flash> _flashes = {};

  static const double _nodeInset = 4.0;
  static const double _widthRatio = 0.19;

  PathFeedbackLayer(this._paths) : super(priority: -1);

  @override
  void update(double dt) {
    super.update(dt);

    for (final path in _paths) {
      final wasActive = _wasActive[path] ?? false;
      final isActive = path.isActive;

      if (isActive && !wasActive) {
        _flashes[path] = _Flash(totalDuration: 0.3);
      } else if (!isActive && wasActive) {
        _flashes[path] = _Flash(totalDuration: 0.2);
      }
      _wasActive[path] = isActive;
    }

    _flashes.removeWhere((path, flash) {
      flash.remaining -= dt;
      return flash.remaining <= 0;
    });
  }

  @override
  void render(ui.Canvas canvas) {
    for (final entry in _flashes.entries) {
      _renderFlash(canvas, entry.key, entry.value);
    }
  }

  /// Whether [path] currently has an active creation/severance flash —
  /// exposed for tests rather than reaching into private state.
  bool hasActiveFlash(PathLink path) => _flashes.containsKey(path);

  void _renderFlash(ui.Canvas canvas, PathLink path, _Flash flash) {
    final a = path.a;
    final b = path.b;
    final delta = b.position - a.position;
    final distance = delta.length;
    if (distance == 0) return;

    final direction = delta / distance;
    final startGap = a.size.x / 2 - _nodeInset;
    final endGap = b.size.x / 2 - _nodeInset;
    if (distance - startGap - endGap <= 0) return;

    final start = a.position + direction * startGap;
    final end = b.position - direction * endGap;
    final width =
        (a.size.x < b.size.x ? a.size.x : b.size.x) * _widthRatio * 1.6;

    final alpha = (flash.remaining / flash.totalDuration).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: alpha * 0.6);

    canvas.drawLine(
      ui.Offset(start.x, start.y),
      ui.Offset(end.x, end.y),
      paint,
    );
  }
}

class _Flash {
  final double totalDuration;
  double remaining;

  _Flash({required this.totalDuration}) : remaining = totalDuration;
}
