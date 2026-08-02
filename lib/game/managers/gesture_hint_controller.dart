/// The onboarding hint sequence's state, in the order a first-time player
/// is expected to progress through them.
enum GestureHintState { initial, selected, pathCreated, done }

/// The gesture-hint onboarding state machine, kept free of `Timer`/`Flutter`
/// dependencies so its transitions and timing are directly unit-testable
/// against synthetic timestamps — the same split `AIStrategy` keeps from
/// `EnemyCommander`'s real-clock harness.
///
/// [tick] is the only way time or game state reaches this class: pass the
/// current game signals plus (optionally, for tests) an explicit [DateTime]
/// standing in for "now".
class GestureHintController {
  static const Duration reshowAfter = Duration(seconds: 15);

  static const Map<GestureHintState, Duration> _fadeDurations = {
    GestureHintState.initial: Duration(seconds: 8),
    GestureHintState.selected: Duration(seconds: 8),
    GestureHintState.pathCreated: Duration(seconds: 10),
  };

  /// Player-facing copy for each state. `pathCreated`'s text deliberately
  /// does not say "swipe to cut a path" as the original brief's tutorial
  /// reference suggested — path severance is explicitly out of scope for
  /// this stage (tap-based interaction only), and a hint instructing a
  /// gesture the game does not yet respond to would be actively misleading.
  static const Map<GestureHintState, String> hintText = {
    GestureHintState.initial: 'Tap a tower to select it',
    GestureHintState.selected: 'Tap another tower to send units',
    GestureHintState.pathCreated: 'Capture every enemy tower to win',
  };

  GestureHintState _state = GestureHintState.initial;
  bool _visible = true;
  DateTime _stateEnteredAt;
  DateTime? _hiddenAt;

  GestureHintController({DateTime? now})
      : _stateEnteredAt = now ?? DateTime.now();

  GestureHintState get state => _state;

  bool get isVisible => _visible && _state != GestureHintState.done;

  /// The hint to display right now, or null if nothing should be shown.
  String? get text => isVisible ? hintText[_state] : null;

  /// Advances the state machine and its fade/reshow timers by one step.
  ///
  /// [hasSelection] and [hasActivePath] are read from the live game each
  /// call — true once the player has selected a building, and once any
  /// route has a unit travelling on it, respectively. [now] defaults to the
  /// real clock; tests pass synthetic times instead of waiting out real
  /// 8-15 second durations.
  void tick({
    required bool hasSelection,
    required bool hasActivePath,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    _advance(
        hasSelection: hasSelection, hasActivePath: hasActivePath, time: time);
    _updateVisibility(time);
  }

  void _advance({
    required bool hasSelection,
    required bool hasActivePath,
    required DateTime time,
  }) {
    switch (_state) {
      case GestureHintState.initial:
        if (hasSelection) _transitionTo(GestureHintState.selected, time);
      case GestureHintState.selected:
        if (hasActivePath) _transitionTo(GestureHintState.pathCreated, time);
      case GestureHintState.pathCreated:
      case GestureHintState.done:
        break;
    }
  }

  void _transitionTo(GestureHintState next, DateTime time) {
    _state = next;
    _visible = true;
    _stateEnteredAt = time;
    _hiddenAt = null;
  }

  void _updateVisibility(DateTime time) {
    if (_state == GestureHintState.done) return;

    if (_visible) {
      if (time.difference(_stateEnteredAt) >= _fadeDurations[_state]!) {
        _visible = false;
        if (_state == GestureHintState.pathCreated) {
          // Nothing further to teach — stop rather than keep reminding.
          _state = GestureHintState.done;
        } else {
          _hiddenAt = time;
        }
      }
      return;
    }

    if (_hiddenAt != null && time.difference(_hiddenAt!) >= reshowAfter) {
      _visible = true;
      _stateEnteredAt = time;
      _hiddenAt = null;
    }
  }
}
