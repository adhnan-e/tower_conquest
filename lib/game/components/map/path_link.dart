import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../constants/colors.dart';
import '../buildings/building.dart';

/// The visible route between two nodes.
///
/// `planning/01_design/01_GAME_DESIGN_DOCUMENT.md` §2.3 has units travelling
/// "along paths connecting nodes", and `05_levels/01_LEVEL_DESIGN.md` §5 gives
/// each level a `paths` array of `{from, to, type}`. This component is the
/// visual half of that: one entry in the array becomes one [PathLink].
///
/// Drawn as a thick solid band beneath the nodes ([priority] -1), stopping
/// short of both so it tucks under the buildings rather than crossing them. A
/// route sits dim and neutral until it matters, then takes the faction colour
/// of whichever end is using it — so at a glance the map shows who owns which
/// lanes.
class PathLink extends Component {
  /// The two nodes this route connects. A link is bidirectional — either end
  /// can be the source of a send.
  final Building a;
  final Building b;

  /// Set while one of the endpoints is selected, to show where units can go.
  bool isHighlighted = false;

  /// Band thickness as a fraction of the smaller node's width, so routes stay
  /// proportional if node sizes change.
  static const double _widthRatio = 0.19;

  /// How far the band stops short of each node's edge.
  static const double _nodeInset = 4.0;

  /// Units currently travelling in each direction. Two counters rather than
  /// one so an exchange in both directions at once does not read as idle.
  int _flowAToB = 0;
  int _flowBToA = 0;

  PathLink({required this.a, required this.b}) : super(priority: -1);

  /// True while any unit is travelling along this route.
  bool get isActive => _flowAToB > 0 || _flowBToA > 0;

  /// Registers a unit setting out from [from] (which must be [a] or [b]).
  void beginFlow(Building from) {
    if (identical(from, a)) {
      _flowAToB++;
    } else if (identical(from, b)) {
      _flowBToA++;
    }
  }

  /// Registers a unit that set out from [from] arriving or dying en route.
  void endFlow(Building from) {
    if (identical(from, a)) {
      _flowAToB = math.max(0, _flowAToB - 1);
    } else if (identical(from, b)) {
      _flowBToA = math.max(0, _flowBToA - 1);
    }
  }

  /// Whether this link joins [from] and [to], in either order.
  bool connects(Building from, Building to) {
    return (identical(from, a) && identical(to, b)) ||
        (identical(from, b) && identical(to, a));
  }

  /// True if [building] is one of the endpoints.
  bool touches(Building building) =>
      identical(building, a) || identical(building, b);

  /// The node currently driving this route's appearance: whichever end has more
  /// units on it, defaulting to [a].
  Building get _driver => _flowBToA > _flowAToB ? b : a;

  @override
  void render(ui.Canvas canvas) {
    final delta = b.position - a.position;
    final distance = delta.length;
    if (distance == 0) return;

    final direction = delta / distance;

    // Tuck the band under both nodes rather than butting up against them.
    final startGap = a.size.x / 2 - _nodeInset;
    final endGap = b.size.x / 2 - _nodeInset;
    if (distance - startGap - endGap <= 0) return;

    final start = a.position + direction * startGap;
    final end = b.position - direction * endGap;

    final p1 = ui.Offset(start.x, start.y);
    final p2 = ui.Offset(end.x, end.y);

    final width = math.min(a.size.x, b.size.x) * _widthRatio;
    final colour = _routeColour();

    // Outer band, then a lighter core down the middle for a road-like read.
    canvas.drawLine(p1, p2, _band(colour, width, 0.85));
    canvas.drawLine(p1, p2, _band(_lighten(colour), width * 0.4, 0.7));
  }

  /// Idle routes are a faint neutral. A highlighted or active route takes the
  /// faction colour of whichever end is driving it.
  ui.Color _routeColour() {
    if (!isHighlighted && !isActive) {
      return const ui.Color(0xFF6B7686);
    }
    return FactionColors.getColor(_driver.faction);
  }

  ui.Paint _band(ui.Color colour, double width, double alpha) {
    return ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = ui.StrokeCap.round
      ..color = colour.withValues(
        alpha: isActive ? alpha : alpha * (isHighlighted ? 0.8 : 0.45),
      );
  }

  /// Blends [colour] toward white for the band's inner core.
  ui.Color _lighten(ui.Color colour) {
    return ui.Color.lerp(colour, const ui.Color(0xFFFFFFFF), 0.35)!;
  }
}
